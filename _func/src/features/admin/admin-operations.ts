/**
 * SHIRAH Cloud Functions - Admin Module
 * Handles admin-only operations: user management, withdrawals, etc.
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  ACCOUNT_STATES,
  RISK_LEVELS,
  TRANSACTION_SOURCES,
  AUDIT_ACTIONS,
  USER_ROLES,
  REGION,
} from "../../config/constants";
import { UserDocument, WithdrawalRequest, ApiResponse } from "../../types";
import { serverTimestamp, increment } from "../../utils/helpers";
import {
  validateAuthenticated,
  validateMinimumRole,
  validateAdminPermission,
} from "../../utils/validators";
import { createAuditLog } from "../audit/audit-logging";
import { getUserByUid, isTestUser } from "../users/user-management";
import { getAdminPermissions } from "../permissions/rbac-and-permissions";
import { creditWallet, lockWallet, unlockWallet } from "../wallet/wallet-and-withdrawal";
import { creditRewardPoints } from "../rewards/reward-and-streak";

const db = admin.firestore();

/**
 * Verify admin has required permission
 */
async function verifyAdminPermission(
  actorUid: string,
  requiredPermission: string
): Promise<UserDocument> {
  const actor = await getUserByUid(actorUid);
  if (!actor) {
    throw new functions.https.HttpsError("not-found", "Admin not found");
  }

  // SuperAdmin has all permissions
  if (actor.role === USER_ROLES.SUPER_ADMIN) {
    return actor;
  }

  // Check minimum role
  validateMinimumRole(actor.role, USER_ROLES.SUPPORT);

  // Check specific permission
  const permissions = await getAdminPermissions(actorUid);
  validateAdminPermission(permissions, requiredPermission);

  return actor;
}

/**
 * Cloud Function: Suspend user
 */
export const suspendUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    reason: string;
    suspendUntil?: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, reason, suspendUntil } = request.data;

    if (!targetUid || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and reason are required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "user.suspend");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    // Can't suspend superAdmin
    if (target.role === USER_ROLES.SUPER_ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Cannot suspend a superAdmin"
      );
    }

    const userRef = db.collection(COLLECTIONS.USERS).doc(targetUid);
    const updateData: Record<string, unknown> = {
      "status.accountState": ACCOUNT_STATES.SUSPENDED,
      "system.notes": reason,
      "meta.updatedAt": serverTimestamp(),
    };

    if (suspendUntil) {
      updateData["system.suspendUntil"] = admin.firestore.Timestamp.fromDate(
        new Date(suspendUntil)
      );
    }

    await userRef.update(updateData);

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.USER_SUSPEND,
      targetUid,
      before: { accountState: target.status.accountState },
      after: { accountState: ACCOUNT_STATES.SUSPENDED },
      metadata: { reason, suspendUntil },
    });

    return {
      success: true,
      message: "User suspended successfully",
    };
  }
);

/**
 * Cloud Function: Ban user
 */
export const banUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, reason } = request.data;

    if (!targetUid || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and reason are required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "user.ban");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    if (target.role === USER_ROLES.SUPER_ADMIN) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Cannot ban a superAdmin"
      );
    }

    const userRef = db.collection(COLLECTIONS.USERS).doc(targetUid);
    await userRef.update({
      "status.accountState": ACCOUNT_STATES.BANNED,
      "system.banReason": reason,
      "wallet.locked": true,
      "meta.updatedAt": serverTimestamp(),
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.USER_BAN,
      targetUid,
      before: { accountState: target.status.accountState },
      after: { accountState: ACCOUNT_STATES.BANNED },
      metadata: { reason },
    });

    return {
      success: true,
      message: "User banned successfully",
    };
  }
);

/**
 * Cloud Function: Unban user
 */
export const unbanUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, reason } = request.data;

    if (!targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid is required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "user.unban");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    const userRef = db.collection(COLLECTIONS.USERS).doc(targetUid);
    await userRef.update({
      "status.accountState": ACCOUNT_STATES.ACTIVE,
      "system.banReason": null,
      "system.suspendUntil": null,
      "wallet.locked": false,
      "meta.updatedAt": serverTimestamp(),
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.USER_UNBAN,
      targetUid,
      before: { accountState: target.status.accountState },
      after: { accountState: ACCOUNT_STATES.ACTIVE },
      metadata: { reason },
    });

    return {
      success: true,
      message: "User unbanned successfully",
    };
  }
);

/**
 * Cloud Function: Approve withdrawal
 */
export const approveWithdrawal = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    withdrawalId: string;
    adminNote?: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { withdrawalId, adminNote } = request.data;

    if (!withdrawalId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "withdrawalId is required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "withdraw.approve");

    // Get withdrawal request
    const withdrawalQuery = await db
      .collection(COLLECTIONS.WITHDRAWAL_REQUESTS)
      .where("id", "==", withdrawalId)
      .limit(1)
      .get();

    if (withdrawalQuery.empty) {
      throw new functions.https.HttpsError("not-found", "Withdrawal request not found");
    }

    const withdrawalDoc = withdrawalQuery.docs[0];
    const withdrawal = withdrawalDoc.data() as WithdrawalRequest;

    if (withdrawal.status !== "pending") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Withdrawal is already ${withdrawal.status}`
      );
    }

    // Check if user is test user
    const isTest = await isTestUser(withdrawal.uid);
    if (isTest) {
      // For test users, just mark as completed without actual payout
      await withdrawalDoc.ref.update({
        status: "completed",
        adminUid: actorUid,
        adminNote: adminNote || "Test user - simulated payout",
        processedAt: serverTimestamp(),
      });

      return {
        success: true,
        message: "Test user withdrawal marked as completed (simulated)",
      };
    }

    // Update withdrawal status
    await withdrawalDoc.ref.update({
      status: "approved",
      adminUid: actorUid,
      adminNote: adminNote || null,
      processedAt: serverTimestamp(),
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.WITHDRAWAL_APPROVE,
      targetUid: withdrawal.uid,
      metadata: {
        withdrawalId,
        amount: withdrawal.amount,
        netAmount: withdrawal.netAmount,
        adminNote,
      },
    });

    return {
      success: true,
      message: "Withdrawal approved successfully",
    };
  }
);

/**
 * Cloud Function: Reject withdrawal
 */
export const rejectWithdrawal = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    withdrawalId: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { withdrawalId, reason } = request.data;

    if (!withdrawalId || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "withdrawalId and reason are required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "withdraw.reject");

    // Get withdrawal request
    const withdrawalQuery = await db
      .collection(COLLECTIONS.WITHDRAWAL_REQUESTS)
      .where("id", "==", withdrawalId)
      .limit(1)
      .get();

    if (withdrawalQuery.empty) {
      throw new functions.https.HttpsError("not-found", "Withdrawal request not found");
    }

    const withdrawalDoc = withdrawalQuery.docs[0];
    const withdrawal = withdrawalDoc.data() as WithdrawalRequest;

    if (withdrawal.status !== "pending") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Withdrawal is already ${withdrawal.status}`
      );
    }

    // Refund the amount back to user's wallet
    await db.runTransaction(async (tx) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(withdrawal.uid);

      tx.update(userRef, {
        "wallet.balanceBDT": increment(withdrawal.amount),
        "meta.updatedAt": serverTimestamp(),
      });

      tx.update(withdrawalDoc.ref, {
        status: "rejected",
        adminUid: actorUid,
        adminNote: reason,
        processedAt: serverTimestamp(),
      });
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.WITHDRAWAL_REJECT,
      targetUid: withdrawal.uid,
      metadata: {
        withdrawalId,
        amount: withdrawal.amount,
        reason,
      },
    });

    return {
      success: true,
      message: "Withdrawal rejected and amount refunded",
    };
  }
);

/**
 * Cloud Function: Admin credit wallet
 */
export const adminCreditWallet = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    amount: number;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, amount, reason } = request.data;

    if (!targetUid || !amount || amount <= 0 || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid, amount (positive), and reason are required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "wallet.credit");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    await creditWallet(
      targetUid,
      amount,
      TRANSACTION_SOURCES.ADMIN_CREDIT,
      `Admin credit: ${reason}`,
      actorUid
    );

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.WALLET_CREDIT,
      targetUid,
      metadata: { amount, reason },
    });

    return {
      success: true,
      message: `Credited ৳${amount} to user wallet`,
    };
  }
);

/**
 * Cloud Function: Admin credit reward points
 */
export const adminCreditRewardPoints = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    points: number;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, points, reason } = request.data;

    if (!targetUid || !points || points <= 0 || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid, points (positive), and reason are required"
      );
    }

    const actor = await verifyAdminPermission(actorUid, "reward.credit");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    await creditRewardPoints(
      targetUid,
      points,
      TRANSACTION_SOURCES.ADMIN_CREDIT,
      `Admin credit: ${reason}`,
      actorUid
    );

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.REWARD_CREDIT,
      targetUid,
      metadata: { points, reason },
    });

    return {
      success: true,
      message: `Credited ${points} reward points to user`,
    };
  }
);

/**
 * Cloud Function: Lock user wallet
 */
export const adminLockWallet = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, reason } = request.data;

    if (!targetUid || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and reason are required"
      );
    }

    await verifyAdminPermission(actorUid, "wallet.lock");
    await lockWallet(targetUid, actorUid, reason);

    return {
      success: true,
      message: "User wallet locked",
    };
  }
);

/**
 * Cloud Function: Unlock user wallet
 */
export const adminUnlockWallet = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, reason } = request.data;

    if (!targetUid || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid and reason are required"
      );
    }

    await verifyAdminPermission(actorUid, "wallet.unlock");
    await unlockWallet(targetUid, actorUid, reason);

    return {
      success: true,
      message: "User wallet unlocked",
    };
  }
);

/**
 * Cloud Function: Set user risk level
 */
export const setUserRiskLevel = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    targetUid: string;
    riskLevel: string;
    reason: string;
  }>): Promise<ApiResponse> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid, riskLevel, reason } = request.data;

    if (!targetUid || !riskLevel || !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid, riskLevel, and reason are required"
      );
    }

    const validRiskLevels = Object.values(RISK_LEVELS);
    if (!validRiskLevels.includes(riskLevel as typeof RISK_LEVELS[keyof typeof RISK_LEVELS])) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid risk level. Must be one of: ${validRiskLevels.join(", ")}`
      );
    }

    const actor = await verifyAdminPermission(actorUid, "user.risk");

    const target = await getUserByUid(targetUid);
    if (!target) {
      throw new functions.https.HttpsError("not-found", "Target user not found");
    }

    const oldRiskLevel = target.status.riskLevel;

    const userRef = db.collection(COLLECTIONS.USERS).doc(targetUid);
    await userRef.update({
      "status.riskLevel": riskLevel,
      "meta.updatedAt": serverTimestamp(),
    });

    await createAuditLog({
      actorUid,
      actorRole: actor.role,
      action: AUDIT_ACTIONS.ADMIN_ACTION,
      targetUid,
      before: { riskLevel: oldRiskLevel },
      after: { riskLevel },
      metadata: { reason, action: "setRiskLevel" },
    });

    return {
      success: true,
      message: `User risk level set to ${riskLevel}`,
    };
  }
);

/**
 * Cloud Function: Get pending withdrawals (Admin)
 */
export const getPendingWithdrawals = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ limit?: number }>): Promise<ApiResponse<WithdrawalRequest[]>> => {
    const actorUid = validateAuthenticated(request.auth);
    const limit = request.data?.limit || 50;

    await verifyAdminPermission(actorUid, "withdraw.review");

    const snapshot = await db
      .collection(COLLECTIONS.WITHDRAWAL_REQUESTS)
      .where("status", "==", "pending")
      .orderBy("createdAt", "asc")
      .limit(limit)
      .get();

    const withdrawals = snapshot.docs.map((doc) => doc.data() as WithdrawalRequest);

    return {
      success: true,
      message: "Pending withdrawals retrieved",
      data: withdrawals,
    };
  }
);

/**
 * Cloud Function: Get user details (Admin)
 */
export const getAdminUserDetails = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ targetUid: string }>): Promise<ApiResponse<UserDocument>> => {
    const actorUid = validateAuthenticated(request.auth);
    const { targetUid } = request.data;

    if (!targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid is required"
      );
    }

    await verifyAdminPermission(actorUid, "user.view");

    const user = await getUserByUid(targetUid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    return {
      success: true,
      message: "User details retrieved",
      data: user,
    };
  }
);

/**
 * Cloud Function: Search users (Admin)
 */
export const searchUsers = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    query: string;
    field: "email" | "phone" | "inviteCode";
    limit?: number;
  }>): Promise<ApiResponse<UserDocument[]>> => {
    const actorUid = validateAuthenticated(request.auth);
    const { query, field, limit = 20 } = request.data;

    if (!query || !field) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "query and field are required"
      );
    }

    await verifyAdminPermission(actorUid, "user.search");

    let fieldPath: string;
    switch (field) {
      case "email":
        fieldPath = "identity.email";
        break;
      case "phone":
        fieldPath = "identity.phone";
        break;
      case "inviteCode":
        fieldPath = "codes.inviteCode";
        break;
      default:
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid search field"
        );
    }

    const snapshot = await db
      .collection(COLLECTIONS.USERS)
      .where(fieldPath, "==", query)
      .limit(limit)
      .get();

    const users = snapshot.docs.map((doc) => doc.data() as UserDocument);

    return {
      success: true,
      message: `Found ${users.length} users`,
      data: users,
    };
  }
);
