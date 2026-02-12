/**
 * SHIRAH Cloud Functions - Users Module
 * Handles user creation, management, and lifecycle
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  ACCOUNT_STATES,
  RISK_LEVELS,
  SUBSCRIPTION_STATUS,
  USER_ROLES,
  AUDIT_ACTIONS,
  REGION,
} from "../../config/constants";
import { getAppConfig } from "../../config/dynamic-config";
import {
  UserDocument,
  UserIdentity,
  UserCodes,
  UserNetwork,
  UserMeta,
  CreateUserRequest,
  ApiResponse,
} from "../../types";
import {
  serverTimestamp,
  sanitizeString,
  getTodayDateString,
  isValidPhoneNumber,
  isValidInviteCodeFormat,
} from "../../utils/helpers";
import {
  validateCreateUserRequest,
  validateAuthenticated,
  validateUserAccountState,
} from "../../utils/validators";
import { validateAndLookupInviteCode, generateUniqueInviteCode } from "../invite-codes/invite-code-operations";
import {
  buildUplineChain,
  createUserUplinesInTransaction,
  createUserRelationsInTransaction,
  initializeNetworkStatsInTransaction,
  incrementNetworkStatsInTransaction,
} from "../network/network-graph-operations";
import { createAuditLogInTransaction } from "../audit/audit-logging";

const db = admin.firestore();

/**
 * Create default user document structure
 */
export function createDefaultUserDocument(
  uid: string,
  identity: UserIdentity,
  codes: UserCodes,
  network: UserNetwork
): Omit<UserDocument, "meta"> & { meta: Partial<UserMeta> } {
  return {
    uid,
    role: USER_ROLES.USER,
    identity,
    codes,
    network,
    status: {
      accountState: ACCOUNT_STATES.ACTIVE,
      verified: false,
      subscription: SUBSCRIPTION_STATUS.NONE,
      riskLevel: RISK_LEVELS.NORMAL,
    },
    wallet: {
      balanceBDT: 0,
      rewardPoints: 0,
      locked: false,
    },
    permissions: {
      canPost: false,
      canWithdraw: false,
      canViewCommunity: true,
    },
    flags: {
      isTestUser: false,
    },
    limits: {
      dailyAdsViewed: 0,
      dailyRewardConverted: 0,
      lastLimitReset: getTodayDateString(),
    },
    meta: {
      createdAt: serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
      updatedAt: serverTimestamp() as unknown as FirebaseFirestore.Timestamp,
      lastLoginAt: null,
      lastActiveAt: null,
    },
    system: {
      banReason: null,
      suspendUntil: null,
      notes: "",
    },
  };
}

/**
 * Cloud Function: Create new user with email/password
 *
 * Flow:
 * 1. Validate all inputs (email, phone, invite code format)
 * 2. Validate invite code exists in invite_codes collection & parent is active
 * 3. Create Firebase Auth user
 * 4. Generate new invite code for the user
 * 5. Build upline chain
 * 6. Run Firestore transaction to create: users, invite_codes, user_uplines, user_relations, user_network_stats
 * 7. If ANYTHING fails after auth user creation → delete the auth user immediately
 */
export const createUser = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<CreateUserRequest>): Promise<ApiResponse> => {
    const data = request.data;

    // Fetch dynamic config
    const config = await getAppConfig();

    // Ensure invite code is uppercase
    if (data.inviteCode) {
      data.inviteCode = data.inviteCode.toUpperCase();
    }

    // Ensure lastName defaults to empty string if not provided
    if (!data.lastName) {
      data.lastName = "";
    }

    // Step 1: Validate request data
    validateCreateUserRequest(data as unknown as Record<string, unknown>, config.inviteCode);

    const { email, password, firstName, lastName, phone, inviteCode } = data;

    // Step 2: Validate invite code and get parent UID (before creating auth user)
    const parentUid = await validateAndLookupInviteCode(inviteCode);

    // Check if parent exists and is active
    const parentDoc = await db.collection(COLLECTIONS.USERS).doc(parentUid).get();
    if (!parentDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Invite code owner not found");
    }

    const parentData = parentDoc.data() as UserDocument;
    if (parentData.status.accountState !== ACCOUNT_STATES.ACTIVE) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Invite code owner account is not active"
      );
    }

    // Step 3: Create Firebase Auth user
    let uid: string | null = null;

    try {
      const displayName = lastName ? `${firstName} ${lastName}` : firstName;
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName,
      });
      uid = userRecord.uid;
    } catch (error) {
      // Auth user creation itself failed — nothing to clean up
      throw new functions.https.HttpsError(
        "internal",
        `Failed to create auth user: ${(error as Error).message}`
      );
    }

    // From this point on, if ANYTHING fails, delete the auth user
    try {
      // Step 4: Generate unique invite code for new user
      const newInviteCode = await generateUniqueInviteCode(uid, email);

      // Step 5: Build upline chain
      const uplineChain = await buildUplineChain(parentUid);

      // Step 6: Create all Firestore documents in a single transaction
      await db.runTransaction(async (transaction) => {
        // Create user document
        const userRef = db.collection(COLLECTIONS.USERS).doc(uid!);
        const identity: UserIdentity = {
          firstName: sanitizeString(firstName),
          lastName: sanitizeString(lastName || ""),
          email,
          phone: sanitizeString(phone),
          authProvider: "password",
          photoURL: "",
          coverURL: "",
        };
        const codes: UserCodes = {
          inviteCode: newInviteCode,
          referralCode: uid!,
        };
        const network: UserNetwork = {
          parentUid,
          joinedVia: "invite",
        };

        const userDoc = createDefaultUserDocument(uid!, identity, codes, network);
        transaction.set(userRef, userDoc);

        // Create uplines document
        createUserUplinesInTransaction(transaction, uid!, uplineChain, config.network.maxDepth);

        // Create relations
        createUserRelationsInTransaction(transaction, uid!, uplineChain, false, false, config.network.maxDepth);

        // Initialize network stats for new user
        initializeNetworkStatsInTransaction(transaction, uid!, config.network.maxDepth);

        // Increment network stats for all uplines
        incrementNetworkStatsInTransaction(transaction, uplineChain, "total", config.network.maxDepth);

        // Create audit log
        createAuditLogInTransaction(transaction, {
          actorUid: uid!,
          actorRole: USER_ROLES.USER,
          action: AUDIT_ACTIONS.USER_CREATE,
          targetUid: uid!,
          metadata: {
            parentUid,
            inviteCodeUsed: inviteCode,
            newInviteCode,
          },
        });
      });

      return {
        success: true,
        message: "User created successfully",
        data: { uid, inviteCode: newInviteCode },
      };
    } catch (error) {
      // Step 7: ALWAYS clean up auth user if any post-creation step fails
      try {
        if (uid) {
          await admin.auth().deleteUser(uid);
        }
      } catch {
        // Ignore cleanup errors — best effort
      }

      // Re-throw as HttpsError if not already
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        `Failed to create user: ${(error as Error).message}`
      );
    }
  }
);

/**
 * Cloud Function: Complete Google Sign-in with invite code and phone
 * Called after a Google user authenticates but has no complete profile.
 * Requires both phone number and invite code to create the full user document.
 */
export const completeGoogleSignIn = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ inviteCode: string; phone: string }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { inviteCode, phone } = request.data;

    // Validate required fields
    if (!inviteCode) {
      throw new functions.https.HttpsError("invalid-argument", "Invite code is required");
    }
    if (!phone) {
      throw new functions.https.HttpsError("invalid-argument", "Phone number is required");
    }

    // Validate phone format (exactly 11 digits starting with 0)
    if (!isValidPhoneNumber(phone)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Phone number must be exactly 11 digits starting with 0"
      );
    }

    // Validate invite code format
    const upperInviteCode = inviteCode.toUpperCase();

    // Check if user already has a complete profile
    const existingUserDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (existingUserDoc.exists) {
      const existingData = existingUserDoc.data() as UserDocument;
      if (existingData.network.parentUid && existingData.identity.phone) {
        throw new functions.https.HttpsError(
          "already-exists",
          "User profile already completed"
        );
      }
    }

    // Fetch dynamic config (needed for invite code format validation)
    const config = await getAppConfig();

    // Validate invite code format with config
    if (!isValidInviteCodeFormat(upperInviteCode, config.inviteCode)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid invite code format"
      );
    }

    // Validate invite code and get parent UID
    const parentUid = await validateAndLookupInviteCode(upperInviteCode);

    // Get auth user data
    const authUser = await admin.auth().getUser(uid);
    if (!authUser.email) {
      throw new functions.https.HttpsError("invalid-argument", "User email not found");
    }

    // Generate unique invite code
    const newInviteCode = await generateUniqueInviteCode(uid, authUser.email);

    // Build upline chain
    const uplineChain = await buildUplineChain(parentUid);

    // Create all documents in a transaction
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection(COLLECTIONS.USERS).doc(uid);

      const nameParts = (authUser.displayName || "User").split(" ");
      const identity: UserIdentity = {
        firstName: nameParts[0] || "User",
        lastName: nameParts.slice(1).join(" ") || "",
        email: authUser.email!,
        phone: phone,
        authProvider: "google",
        photoURL: authUser.photoURL || "",
        coverURL: "",
      };
      const codes: UserCodes = {
        inviteCode: newInviteCode,
        referralCode: uid,
      };
      const network: UserNetwork = {
        parentUid,
        joinedVia: "invite",
      };

      const userDoc = createDefaultUserDocument(uid, identity, codes, network);
      transaction.set(userRef, userDoc);

      createUserUplinesInTransaction(transaction, uid, uplineChain, config.network.maxDepth);
      createUserRelationsInTransaction(transaction, uid, uplineChain, false, false, config.network.maxDepth);
      initializeNetworkStatsInTransaction(transaction, uid, config.network.maxDepth);
      incrementNetworkStatsInTransaction(transaction, uplineChain, "total", config.network.maxDepth);

      createAuditLogInTransaction(transaction, {
        actorUid: uid,
        actorRole: USER_ROLES.USER,
        action: AUDIT_ACTIONS.USER_CREATE,
        targetUid: uid,
        metadata: {
          parentUid,
          inviteCodeUsed: upperInviteCode,
          newInviteCode,
          authProvider: "google",
          phone,
        },
      });
    });

    return {
      success: true,
      message: "Google sign-in completed",
      data: { uid, inviteCode: newInviteCode },
    };
  }
);

/**
 * Get user document by UID
 */
export async function getUserByUid(uid: string): Promise<UserDocument | null> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const doc = await userRef.get();

  if (!doc.exists) return null;
  return doc.data() as UserDocument;
}

/**
 * Update user last active timestamp
 */
export async function updateUserActivity(uid: string): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  await userRef.update({
    "meta.lastActiveAt": serverTimestamp(),
    "meta.updatedAt": serverTimestamp(),
  });
}

/**
 * Update user last login timestamp
 */
export async function updateUserLogin(uid: string): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  await userRef.update({
    "meta.lastLoginAt": serverTimestamp(),
    "meta.lastActiveAt": serverTimestamp(),
    "meta.updatedAt": serverTimestamp(),
  });
}

/**
 * Reset daily limits if needed
 */
export async function resetDailyLimitsIfNeeded(uid: string): Promise<boolean> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) return false;

  const userData = userDoc.data() as UserDocument;
  const today = getTodayDateString();

  if (userData.limits.lastLimitReset !== today) {
    await userRef.update({
      "limits.dailyAdsViewed": 0,
      "limits.dailyRewardConverted": 0,
      "limits.lastLimitReset": today,
      "meta.updatedAt": serverTimestamp(),
    });
    return true;
  }

  return false;
}

/**
 * Check if user is test user
 */
export async function isTestUser(uid: string): Promise<boolean> {
  const user = await getUserByUid(uid);
  return user?.flags.isTestUser || false;
}

/**
 * Cloud Function: Get current user profile
 */
export const getUserProfile = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest): Promise<ApiResponse<UserDocument>> => {
    const uid = validateAuthenticated(request.auth);

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    // Reset daily limits if needed
    await resetDailyLimitsIfNeeded(uid);

    // Update activity
    await updateUserActivity(uid);

    return {
      success: true,
      message: "User profile retrieved",
      data: user,
    };
  }
);

/**
 * Cloud Function: Update user profile
 */
export const updateUserProfile = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{
    firstName?: string;
    lastName?: string;
    phone?: string;
    photoURL?: string;
    coverURL?: string;
  }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    const user = await getUserByUid(uid);
    if (!user) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    validateUserAccountState(user.status.accountState);

    const updates: Record<string, unknown> = {
      "meta.updatedAt": serverTimestamp(),
    };

    if (data.firstName) {
      updates["identity.firstName"] = sanitizeString(data.firstName);
    }
    if (data.lastName) {
      updates["identity.lastName"] = sanitizeString(data.lastName);
    }
    if (data.phone) {
      updates["identity.phone"] = sanitizeString(data.phone);
    }
    if (data.photoURL !== undefined) {
      updates["identity.photoURL"] = data.photoURL;
    }
    if (data.coverURL !== undefined) {
      updates["identity.coverURL"] = data.coverURL;
    }

    const userRef = db.collection(COLLECTIONS.USERS).doc(uid);
    await userRef.update(updates);

    return {
      success: true,
      message: "Profile updated successfully",
    };
  }
);
