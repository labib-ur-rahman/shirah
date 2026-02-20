/**
 * SHIRAH Cloud Functions - Auth Module
 * Handles authentication triggers and user verification/subscription
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as functionsV1 from "firebase-functions/v1";
import {
  COLLECTIONS,
  ACCOUNT_STATES,
  SUBSCRIPTION_STATUS,
  TRANSACTION_SOURCES,
  AUDIT_ACTIONS,
  USER_ROLES,
  REGION,
  PAYMENT_STATUS,
  PAYMENT_TYPES,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import { ApiResponse, UndistributedEntry } from "../../types";
import { serverTimestamp } from "../../utils/helpers";
import {
  validateAuthenticated,
  validateUserAccountState,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid, updateUserLogin } from "../users/user-management";
import {
  getUserUplines,
  incrementNetworkStatsInTransaction,
  updateRelationsOnStatusChange,
  distributeSubscriptionRewards,
  distributeVerificationRewards,
} from "../network/network-graph-operations";
import { creditRewardPointsInTransaction } from "../rewards/reward-and-streak";

const db = admin.firestore();

/**
 * Trigger: On user login (update last login timestamp)
 */
export const onUserLogin = functionsV1.region(REGION).auth.user().beforeSignIn(async (user) => {
  if (user.uid) {
    await updateUserLogin(user.uid);
  }
});

/**
 * Cloud Function: Verify user profile (after payment)
 * Updated: Validates payment_transactions doc, handles undistributed commission to app_funding_transactions
 */
export const verifyUserProfile = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentTransactionId: string;
  }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { paymentTransactionId } = request.data;

    if (!paymentTransactionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment transaction ID is required"
      );
    }

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    validateUserAccountState(user.status.accountState);

    if (user.status.verified) {
      throw new functions.https.HttpsError(
        "already-exists",
        "User is already verified"
      );
    }

    // Validate payment transaction
    const paymentRef = db.collection(COLLECTIONS.PAYMENT_TRANSACTIONS).doc(paymentTransactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Payment transaction not found");
    }

    const paymentData = paymentDoc.data()!;
    if (paymentData.uid !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Payment does not belong to this user");
    }
    if (paymentData.status !== PAYMENT_STATUS.COMPLETED) {
      throw new functions.https.HttpsError("failed-precondition", "Payment is not completed");
    }
    if (paymentData.type !== PAYMENT_TYPES.VERIFICATION) {
      throw new functions.https.HttpsError("invalid-argument", "Payment is not for verification");
    }

    // Get uplines for reward distribution
    const uplines = await getUserUplines(uid);
    const config = await getAppConfig();

    let undistributedEntries: UndistributedEntry[] = [];

    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);

      // Update user status
      tx.update(userRef, {
        "status.verified": true,
        "permissions.canPost": true,
        "permissions.canWithdraw": true,
        "meta.updatedAt": serverTimestamp(),
      });

      // Increment verified count for uplines
      if (uplines) {
        incrementNetworkStatsInTransaction(tx, uplines, "verified", config.network.maxDepth);

        // Distribute verification rewards to uplines (with verified check)
        const { rewards, undistributed } = await distributeVerificationRewards(uid, uplines);
        undistributedEntries = undistributed;

        for (const [uplineUid, points] of rewards) {
          creditRewardPointsInTransaction(
            tx,
            uplineUid,
            points,
            TRANSACTION_SOURCES.VERIFICATION_COMMISSION,
            `Verification reward from network member`,
            uid
          );
        }
      }
    });

    // Write undistributed entries to app_funding_transactions (outside transaction to avoid conflicts)
    await writeUndistributedEntries(undistributedEntries, uid, PAYMENT_TYPES.VERIFICATION, config.rewardPoints.conversionRate);

    // Update relations
    await updateRelationsOnStatusChange(uid, "descendantVerified", true);

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.USER_VERIFY,
      targetUid: uid,
      metadata: { paymentTransactionId },
    });

    return {
      success: true,
      message: "Profile verified successfully",
    };
  }
);

/**
 * Cloud Function: Subscribe user (after payment)
 * Updated: Validates payment_transactions doc, handles undistributed commission to app_funding_transactions
 */
export const subscribeUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentTransactionId: string;
  }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { paymentTransactionId } = request.data;

    if (!paymentTransactionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment transaction ID is required"
      );
    }

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    validateUserAccountState(user.status.accountState);

    if (user.status.subscription === SUBSCRIPTION_STATUS.ACTIVE) {
      throw new functions.https.HttpsError(
        "already-exists",
        "User already has an active subscription"
      );
    }

    // Validate payment transaction
    const paymentRef = db.collection(COLLECTIONS.PAYMENT_TRANSACTIONS).doc(paymentTransactionId);
    const paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Payment transaction not found");
    }

    const paymentData = paymentDoc.data()!;
    if (paymentData.uid !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Payment does not belong to this user");
    }
    if (paymentData.status !== PAYMENT_STATUS.COMPLETED) {
      throw new functions.https.HttpsError("failed-precondition", "Payment is not completed");
    }
    if (paymentData.type !== PAYMENT_TYPES.SUBSCRIPTION) {
      throw new functions.https.HttpsError("invalid-argument", "Payment is not for subscription");
    }

    // Get uplines for reward distribution
    const uplines = await getUserUplines(uid);
    const config = await getAppConfig();

    let undistributedEntries: UndistributedEntry[] = [];

    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);

      // Update user status
      tx.update(userRef, {
        "status.subscription": SUBSCRIPTION_STATUS.ACTIVE,
        "status.verified": true, // Subscription also verifies
        "permissions.canPost": true,
        "permissions.canWithdraw": true,
        "meta.updatedAt": serverTimestamp(),
      });

      // Increment counts for uplines
      if (uplines) {
        incrementNetworkStatsInTransaction(tx, uplines, "subscribed", config.network.maxDepth);

        // If not already verified, also increment verified count
        if (!user.status.verified) {
          incrementNetworkStatsInTransaction(tx, uplines, "verified", config.network.maxDepth);
        }

        // Distribute subscription rewards to uplines (with verified check)
        const { rewards, undistributed } = await distributeSubscriptionRewards(uid, uplines);
        undistributedEntries = undistributed;

        for (const [uplineUid, points] of rewards) {
          creditRewardPointsInTransaction(
            tx,
            uplineUid,
            points,
            TRANSACTION_SOURCES.SUBSCRIPTION_COMMISSION,
            `Subscription reward from network member`,
            uid
          );
        }
      }
    });

    // Write undistributed entries to app_funding_transactions (outside transaction)
    await writeUndistributedEntries(undistributedEntries, uid, PAYMENT_TYPES.SUBSCRIPTION, config.rewardPoints.conversionRate);

    // Update relations
    await updateRelationsOnStatusChange(uid, "descendantSubscribed", true);
    if (!user.status.verified) {
      await updateRelationsOnStatusChange(uid, "descendantVerified", true);
    }

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.USER_SUBSCRIBE,
      targetUid: uid,
      metadata: { paymentTransactionId },
    });

    return {
      success: true,
      message: "Subscription activated successfully",
    };
  }
);

/**
 * Cloud Function: Check authentication status
 */
export const checkAuthStatus = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<ApiResponse<{
    authenticated: boolean;
    uid: string | null;
    hasProfile: boolean;
    profileComplete: boolean;
  }>> => {
    try {
      const uid = validateAuthenticated(request.auth);
      const user = await getUserByUid(uid);

      return {
        success: true,
        message: "Auth status checked",
        data: {
          authenticated: true,
          uid,
          hasProfile: !!user,
          profileComplete: !!user?.network.parentUid,
        },
      };
    } catch {
      return {
        success: true,
        message: "Not authenticated",
        data: {
          authenticated: false,
          uid: null,
          hasProfile: false,
          profileComplete: false,
        },
      };
    }
  }
);

/**
 * Trigger: On user deleted from Firebase Auth
 */
export const onUserDeleted = functionsV1.region(REGION).auth.user().onDelete(async (user: functionsV1.auth.UserRecord) => {
  const uid = user.uid;

  // Soft delete user document (don't actually delete data)
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const userDoc = await userRef.get();

  if (userDoc.exists) {
    await userRef.update({
      "status.accountState": ACCOUNT_STATES.DELETED,
      "meta.updatedAt": serverTimestamp(),
    });

    await createAuditLog({
      actorUid: uid,
      actorRole: USER_ROLES.USER,
      action: AUDIT_ACTIONS.USER_DELETE,
      targetUid: uid,
      metadata: { trigger: "auth.user.onDelete" },
    });
  }
});

/**
 * Check if user is verified or subscribed
 */
export async function isUserVerifiedOrSubscribed(uid: string): Promise<boolean> {
  const user = await getUserByUid(uid);
  if (!user) return false;
  return user.status.verified || user.status.subscription === SUBSCRIPTION_STATUS.ACTIVE;
}

/**
 * Check if user account is active
 */
export async function isUserAccountActive(uid: string): Promise<boolean> {
  const user = await getUserByUid(uid);
  if (!user) return false;
  return user.status.accountState === ACCOUNT_STATES.ACTIVE;
}

/**
 * Write undistributed commission entries to app_funding_transactions collection.
 * Called after the main transaction to avoid conflicts.
 */
async function writeUndistributedEntries(
  entries: UndistributedEntry[],
  sourceUid: string,
  sourceEvent: string,
  conversionRate: number
): Promise<void> {
  if (entries.length === 0) return;

  const batch = db.batch();
  const fundingType = sourceEvent === PAYMENT_TYPES.VERIFICATION
    ? "verification_undistributed"
    : "subscription_undistributed";

  for (const entry of entries) {
    const ref = db.collection(COLLECTIONS.APP_FUNDING_TRANSACTIONS).doc();
    batch.set(ref, {
      id: ref.id,
      type: fundingType,
      sourceUid,
      sourceEvent,
      skippedLevel: entry.level,
      skippedUplineUid: entry.uplineUid,
      reason: entry.reason,
      points: entry.points,
      amountBDT: entry.points / conversionRate,
      createdAt: serverTimestamp(),
    });
  }

  await batch.commit();
}

/**
 * Internal: Process verification for a user (used by both direct call and admin approval)
 */
export async function processVerification(
  uid: string,
  paymentTransactionId: string
): Promise<void> {
  const user = await getUserByUid(uid);
  if (!user) throw new functions.https.HttpsError("not-found", "User not found");
  if (user.status.verified) return; // Already verified, skip silently

  const uplines = await getUserUplines(uid);
  const config = await getAppConfig();

  let undistributedEntries: UndistributedEntry[] = [];

  await db.runTransaction(async (tx) => {
    const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
    tx.update(userRef, {
      "status.verified": true,
      "permissions.canPost": true,
      "permissions.canWithdraw": true,
      "meta.updatedAt": serverTimestamp(),
    });

    if (uplines) {
      incrementNetworkStatsInTransaction(tx, uplines, "verified", config.network.maxDepth);
      const { rewards, undistributed } = await distributeVerificationRewards(uid, uplines);
      undistributedEntries = undistributed;

      for (const [uplineUid, points] of rewards) {
        creditRewardPointsInTransaction(
          tx, uplineUid, points,
          TRANSACTION_SOURCES.VERIFICATION_COMMISSION,
          `Verification reward from network member`, uid
        );
      }
    }
  });

  await writeUndistributedEntries(undistributedEntries, uid, PAYMENT_TYPES.VERIFICATION, config.rewardPoints.conversionRate);
  await updateRelationsOnStatusChange(uid, "descendantVerified", true);

  await createAuditLog({
    actorUid: uid,
    actorRole: user.role,
    action: AUDIT_ACTIONS.USER_VERIFY,
    targetUid: uid,
    metadata: { paymentTransactionId },
  });
}

/**
 * Internal: Process subscription for a user (used by both direct call and admin approval)
 */
export async function processSubscription(
  uid: string,
  paymentTransactionId: string
): Promise<void> {
  const user = await getUserByUid(uid);
  if (!user) throw new functions.https.HttpsError("not-found", "User not found");
  if (user.status.subscription === SUBSCRIPTION_STATUS.ACTIVE) return;

  const uplines = await getUserUplines(uid);
  const config = await getAppConfig();

  let undistributedEntries: UndistributedEntry[] = [];

  await db.runTransaction(async (tx) => {
    const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
    tx.update(userRef, {
      "status.subscription": SUBSCRIPTION_STATUS.ACTIVE,
      "status.verified": true,
      "permissions.canPost": true,
      "permissions.canWithdraw": true,
      "meta.updatedAt": serverTimestamp(),
    });

    if (uplines) {
      incrementNetworkStatsInTransaction(tx, uplines, "subscribed", config.network.maxDepth);
      if (!user.status.verified) {
        incrementNetworkStatsInTransaction(tx, uplines, "verified", config.network.maxDepth);
      }

      const { rewards, undistributed } = await distributeSubscriptionRewards(uid, uplines);
      undistributedEntries = undistributed;

      for (const [uplineUid, points] of rewards) {
        creditRewardPointsInTransaction(
          tx, uplineUid, points,
          TRANSACTION_SOURCES.SUBSCRIPTION_COMMISSION,
          `Subscription reward from network member`, uid
        );
      }
    }
  });

  await writeUndistributedEntries(undistributedEntries, uid, PAYMENT_TYPES.SUBSCRIPTION, config.rewardPoints.conversionRate);
  await updateRelationsOnStatusChange(uid, "descendantSubscribed", true);
  if (!user.status.verified) {
    await updateRelationsOnStatusChange(uid, "descendantVerified", true);
  }

  await createAuditLog({
    actorUid: uid,
    actorRole: user.role,
    action: AUDIT_ACTIONS.USER_SUBSCRIBE,
    targetUid: uid,
    metadata: { paymentTransactionId },
  });
}
