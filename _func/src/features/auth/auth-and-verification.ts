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
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import { ApiResponse } from "../../types";
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
 */
export const verifyUserProfile = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentReference: string;
  }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { paymentReference } = request.data;

    if (!paymentReference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment reference is required"
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

    // Get uplines for reward distribution
    const uplines = await getUserUplines(uid);
    const config = await getAppConfig();

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

        // Distribute verification rewards to uplines
        const rewards = await distributeVerificationRewards(uid, uplines);
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

    // Update relations
    await updateRelationsOnStatusChange(uid, "descendantVerified", true);

    await createAuditLog({
      actorUid: uid,
      actorRole: user.role,
      action: AUDIT_ACTIONS.USER_VERIFY,
      targetUid: uid,
      metadata: { paymentReference },
    });

    return {
      success: true,
      message: "Profile verified successfully",
    };
  }
);

/**
 * Cloud Function: Subscribe user (after payment)
 */
export const subscribeUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    paymentReference: string;
  }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { paymentReference } = request.data;

    if (!paymentReference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Payment reference is required"
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

    // Get uplines for reward distribution
    const uplines = await getUserUplines(uid);
    const config = await getAppConfig();

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

        // Distribute subscription rewards to uplines
        const rewards = await distributeSubscriptionRewards(uid, uplines);
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
      metadata: { paymentReference },
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
