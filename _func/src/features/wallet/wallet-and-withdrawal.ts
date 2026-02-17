/**
 * SHIRAH Cloud Functions - Wallet Module
 * Handles wallet balance, transactions, and withdrawals
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  TRANSACTION_TYPES,
  TRANSACTION_SOURCES,
  AUDIT_ACTIONS,
  USER_ROLES,
  REGION,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import {
  WalletTransaction,
  WithdrawalRequest,
  UserDocument,
  ApiResponse,
} from "../../types";
import {
  serverTimestamp,
  calculateWithdrawalFee,
  generateTransactionId,
  increment,
} from "../../utils/helpers";
import {
  validateAuthenticated,
  validateWithdrawalRequest,
  validateUserAccountState,
  validateUserVerifiedOrSubscribed,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid } from "../users/user-management";

const db = admin.firestore();

/**
 * Credit wallet balance
 */
export async function creditWallet(
  uid: string,
  amount: number,
  source: string,
  description: string,
  reference?: string
): Promise<WalletTransaction> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
  const transactionId = generateTransactionId("WTX");

  let transaction: WalletTransaction | null = null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data() as UserDocument;
    const balanceBefore = userData.wallet.balanceBDT;
    const balanceAfter = balanceBefore + amount;

    // Create transaction record
    transaction = {
      id: transactionId,
      uid,
      type: TRANSACTION_TYPES.CREDIT,
      source,
      amount,
      balanceBefore,
      balanceAfter,
      description,
      reference: reference || null,
      createdAt: admin.firestore.Timestamp.now(),
    };

    // Update user wallet
    tx.update(userRef, {
      "wallet.balanceBDT": balanceAfter,
      "meta.updatedAt": serverTimestamp(),
    });

    // Save transaction
    tx.set(transactionRef, {
      ...transaction,
      createdAt: serverTimestamp(),
    });
  });

  return transaction!;
}

/**
 * Debit wallet balance
 */
export async function debitWallet(
  uid: string,
  amount: number,
  source: string,
  description: string,
  reference?: string
): Promise<WalletTransaction> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
  const transactionId = generateTransactionId("WTX");

  let transaction: WalletTransaction | null = null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data() as UserDocument;
    const balanceBefore = userData.wallet.balanceBDT;

    if (balanceBefore < amount) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Insufficient balance"
      );
    }

    const balanceAfter = balanceBefore - amount;

    transaction = {
      id: transactionId,
      uid,
      type: TRANSACTION_TYPES.DEBIT,
      source,
      amount,
      balanceBefore,
      balanceAfter,
      description,
      reference: reference || null,
      createdAt: admin.firestore.Timestamp.now(),
    };

    tx.update(userRef, {
      "wallet.balanceBDT": balanceAfter,
      "meta.updatedAt": serverTimestamp(),
    });

    tx.set(transactionRef, {
      ...transaction,
      createdAt: serverTimestamp(),
    });
  });

  return transaction!;
}

/**
 * Lock user wallet
 */
export async function lockWallet(
  uid: string,
  adminUid: string,
  reason: string
): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);

  await userRef.update({
    "wallet.locked": true,
    "meta.updatedAt": serverTimestamp(),
  });

  await createAuditLog({
    actorUid: adminUid,
    actorRole: USER_ROLES.ADMIN,
    action: AUDIT_ACTIONS.WALLET_LOCK,
    targetUid: uid,
    metadata: { reason },
  });
}

/**
 * Unlock user wallet
 */
export async function unlockWallet(
  uid: string,
  adminUid: string,
  reason: string
): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);

  await userRef.update({
    "wallet.locked": false,
    "meta.updatedAt": serverTimestamp(),
  });

  await createAuditLog({
    actorUid: adminUid,
    actorRole: USER_ROLES.ADMIN,
    action: AUDIT_ACTIONS.WALLET_UNLOCK,
    targetUid: uid,
    metadata: { reason },
  });
}

/**
 * Cloud Function: Request withdrawal
 */
export const requestWithdrawal = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    amount: number;
    paymentMethod: string;
    paymentDetails: Record<string, string>;
  }>): Promise<ApiResponse<WithdrawalRequest>> => {
    const uid = validateAuthenticated(request.auth);
    const { amount, paymentMethod, paymentDetails } = request.data;

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    // Validate user state
    validateUserAccountState(user.status.accountState);
    validateUserVerifiedOrSubscribed(user.status.verified, user.status.subscription);

    const config = await getAppConfig();
    validateWithdrawalRequest(amount, user.wallet.balanceBDT, user.wallet.locked, config.wallet);

    // Check permissions
    if (!user.permissions.canWithdraw) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User is not allowed to withdraw"
      );
    }

    const fee = calculateWithdrawalFee(amount, config.wallet.withdrawalFeePer1000);
    const netAmount = amount - fee;

    const withdrawalRef = db.collection(COLLECTIONS.WITHDRAWAL_REQUESTS).doc();
    const withdrawalId = generateTransactionId("WDR");

    const withdrawalRequest: Omit<WithdrawalRequest, "createdAt" | "processedAt"> & {
      createdAt: FirebaseFirestore.FieldValue;
      processedAt: null;
    } = {
      id: withdrawalId,
      uid,
      amount,
      fee,
      netAmount,
      paymentMethod,
      paymentDetails,
      status: "pending",
      adminUid: null,
      adminNote: null,
      createdAt: serverTimestamp(),
      processedAt: null,
    };

    // Create withdrawal request and debit wallet
    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
      const userDoc = await tx.get(userRef);
      const userData = userDoc.data() as UserDocument;

      // Double-check balance
      if (userData.wallet.balanceBDT < amount) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient balance"
        );
      }

      // Debit wallet
      tx.update(userRef, {
        "wallet.balanceBDT": increment(-amount),
        "meta.updatedAt": serverTimestamp(),
      });

      // Create withdrawal request
      tx.set(withdrawalRef, withdrawalRequest);

      // Create transaction record
      const transactionRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();
      tx.set(transactionRef, {
        id: generateTransactionId("WTX"),
        uid,
        type: TRANSACTION_TYPES.DEBIT,
        source: TRANSACTION_SOURCES.WITHDRAWAL,
        amount,
        balanceBefore: userData.wallet.balanceBDT,
        balanceAfter: userData.wallet.balanceBDT - amount,
        description: `Withdrawal request: ${withdrawalId}`,
        reference: withdrawalId,
        createdAt: serverTimestamp(),
      });
    });

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.WITHDRAWAL_REQUEST,
      targetUid: uid,
      metadata: {
        withdrawalId,
        amount,
        fee,
        netAmount,
        paymentMethod,
      },
    });

    return {
      success: true,
      message: "Withdrawal request submitted",
      data: {
        ...withdrawalRequest,
        createdAt: admin.firestore.Timestamp.now(),
        processedAt: null,
      } as WithdrawalRequest,
    };
  }
);

/**
 * Get user wallet transactions
 */
export async function getWalletTransactions(
  uid: string,
  limit: number = 50
): Promise<WalletTransaction[]> {
  const snapshot = await db
    .collection(COLLECTIONS.WALLET_TRANSACTIONS)
    .where("uid", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as WalletTransaction);
}

/**
 * Get user withdrawal requests
 */
export async function getWithdrawalRequests(
  uid: string,
  limit: number = 20
): Promise<WithdrawalRequest[]> {
  const snapshot = await db
    .collection(COLLECTIONS.WITHDRAWAL_REQUESTS)
    .where("uid", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return snapshot.docs.map((doc) => doc.data() as WithdrawalRequest);
}

/**
 * Cloud Function: Get wallet transactions
 */
export const getMyWalletTransactions = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ limit?: number }>): Promise<ApiResponse<WalletTransaction[]>> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 50;

    const transactions = await getWalletTransactions(uid, limit);

    return {
      success: true,
      message: "Transactions retrieved",
      data: transactions,
    };
  }
);

/**
 * Cloud Function: Get withdrawal requests
 */
export const getMyWithdrawalRequests = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ limit?: number }>): Promise<ApiResponse<WithdrawalRequest[]>> => {
    const uid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 20;

    const requests = await getWithdrawalRequests(uid, limit);

    return {
      success: true,
      message: "Withdrawal requests retrieved",
      data: requests,
    };
  }
);

/**
 * Get wallet balance
 */
export async function getWalletBalance(uid: string): Promise<number> {
  const user = await getUserByUid(uid);
  return user?.wallet.balanceBDT || 0;
}

/**
 * Credit wallet in transaction (for batch operations)
 */
export function creditWalletInTransaction(
  transaction: FirebaseFirestore.Transaction,
  uid: string,
  amount: number,
  source: string,
  description: string,
  reference?: string
): void {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const transactionRef = db.collection(COLLECTIONS.WALLET_TRANSACTIONS).doc();

  transaction.update(userRef, {
    "wallet.balanceBDT": increment(amount),
    "meta.updatedAt": serverTimestamp(),
  });

  transaction.set(transactionRef, {
    id: generateTransactionId("WTX"),
    uid,
    type: TRANSACTION_TYPES.CREDIT,
    source,
    amount,
    description,
    reference: reference || null,
    createdAt: serverTimestamp(),
  });
}
