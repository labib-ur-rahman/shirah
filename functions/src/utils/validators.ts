/**
 * SHIRAH Cloud Functions - Validation Utilities
 * All validation functions for API requests
 */

import * as functions from "firebase-functions";
import { isValidEmail, isValidPhoneNumber, isValidInviteCodeFormat } from "./helpers";
import { USER_ROLES } from "../config/constants";
import { InviteCodeConfig, RewardPointsConfig, WalletConfig } from "../config/dynamic-config";

/**
 * Validate required fields exist
 */
export function validateRequiredFields(
  data: Record<string, unknown>,
  fields: string[]
): void {
  const missing = fields.filter((field) => !data[field] && data[field] !== 0);
  if (missing.length > 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Missing required fields: ${missing.join(", ")}`
    );
  }
}

/**
 * Validate user is authenticated (for v2 callable functions)
 */
export function validateAuthenticated(
  auth: { uid: string } | undefined
): string {
  if (!auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }
  return auth.uid;
}

/**
 * Validate create user request (requires invite code config for format check)
 */
export function validateCreateUserRequest(data: Record<string, unknown>, inviteCodeConfig: InviteCodeConfig): void {
  // lastName is optional, so only require these fields
  validateRequiredFields(data, ["email", "password", "firstName", "phone", "inviteCode"]);

  const { email, password, firstName, lastName, phone, inviteCode } = data;

  if (!isValidEmail(email as string)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid email format"
    );
  }

  if ((password as string).length < 6) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters"
    );
  }

  if ((firstName as string).length < 2) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "First name must be at least 2 characters"
    );
  }

  // lastName is optional, but if provided must be at least 2 characters
  if (lastName && (lastName as string).length > 0 && (lastName as string).length < 2) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Last name must be at least 2 characters if provided"
    );
  }

  if (!isValidPhoneNumber(phone as string)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid phone number format. Must be 11 digits starting with 0 (e.g., 01602475999)"
    );
  }

  if (!isValidInviteCodeFormat((inviteCode as string).toUpperCase(), inviteCodeConfig)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid invite code format"
    );
  }
}

/**
 * Validate invite code (requires invite code config for format check)
 */
export function validateInviteCode(inviteCode: string, inviteCodeConfig: InviteCodeConfig): void {
  if (!inviteCode) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invite code is required"
    );
  }

  if (!isValidInviteCodeFormat(inviteCode, inviteCodeConfig)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid invite code format"
    );
  }
}

/**
 * Validate reward conversion request (dynamic config)
 */
export function validateRewardConversion(
  points: number,
  currentPoints: number,
  dailyConverted: number,
  rewardConfig: RewardPointsConfig
): void {
  if (!points || points <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Points must be a positive number"
    );
  }

  if (points < rewardConfig.minConversion) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Minimum conversion is ${rewardConfig.minConversion} points`
    );
  }

  if (points > currentPoints) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Insufficient reward points"
    );
  }

  if (dailyConverted >= rewardConfig.maxDailyConversions) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Maximum ${rewardConfig.maxDailyConversions} conversions per day`
    );
  }
}

/**
 * Validate withdrawal request (dynamic config)
 */
export function validateWithdrawalRequest(
  amount: number,
  currentBalance: number,
  isLocked: boolean,
  walletConfig: WalletConfig
): void {
  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Amount must be a positive number"
    );
  }

  if (amount < walletConfig.minWithdrawalBDT) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Minimum withdrawal is ${walletConfig.minWithdrawalBDT} BDT`
    );
  }

  if (amount > currentBalance) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Insufficient wallet balance"
    );
  }

  if (isLocked) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Wallet is locked. Contact support."
    );
  }
}

/**
 * Validate user account state
 */
export function validateUserAccountState(
  accountState: string,
  allowedStates: string[] = ["active"]
): void {
  if (!allowedStates.includes(accountState)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `Account is ${accountState}. This action is not allowed.`
    );
  }
}

/**
 * Validate user is verified or subscribed
 */
export function validateUserVerifiedOrSubscribed(
  verified: boolean,
  subscription: string
): void {
  if (!verified && subscription === "none") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User must be verified or have an active subscription"
    );
  }
}

/**
 * Validate role change request
 */
export function validateRoleChange(
  currentRole: string,
  newRole: string,
  actorRole: string
): void {
  const validRoles = Object.values(USER_ROLES);
  
  if (!validRoles.includes(newRole as typeof USER_ROLES[keyof typeof USER_ROLES])) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid role: ${newRole}`
    );
  }

  // Only superAdmin can assign superAdmin role
  if (newRole === USER_ROLES.SUPER_ADMIN && actorRole !== USER_ROLES.SUPER_ADMIN) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only superAdmin can assign superAdmin role"
    );
  }

  // Can't change own role
  if (currentRole === USER_ROLES.SUPER_ADMIN && newRole !== USER_ROLES.SUPER_ADMIN) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Cannot demote a superAdmin"
    );
  }
}

/**
 * Validate permission format
 */
export function validatePermissionFormat(permission: string): void {
  // Permission format: group.action (e.g., withdraw.approve)
  const parts = permission.split(".");
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid permission format: ${permission}. Expected: group.action`
    );
  }
}

/**
 * Validate daily ad view limit
 */
export function validateDailyAdLimit(dailyAdsViewed: number, maxAds: number): void {
  if (dailyAdsViewed >= maxAds) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Daily ad limit reached (${maxAds} ads)`
    );
  }
}

/**
 * Validate admin has permission
 */
export function validateAdminPermission(
  permissions: Record<string, boolean>,
  requiredPermission: string
): void {
  if (!permissions[requiredPermission]) {
    throw new functions.https.HttpsError(
      "permission-denied",
      `Missing required permission: ${requiredPermission}`
    );
  }
}

/**
 * Validate user role has minimum privilege
 */
export function validateMinimumRole(
  userRole: string,
  minimumRole: string
): void {
  const roleHierarchy: Record<string, number> = {
    [USER_ROLES.SUPER_ADMIN]: 5,
    [USER_ROLES.ADMIN]: 4,
    [USER_ROLES.MODERATOR]: 3,
    [USER_ROLES.SUPPORT]: 2,
    [USER_ROLES.USER]: 1,
  };

  const userLevel = roleHierarchy[userRole] || 0;
  const requiredLevel = roleHierarchy[minimumRole] || 0;

  if (userLevel < requiredLevel) {
    throw new functions.https.HttpsError(
      "permission-denied",
      `Insufficient role privileges. Required: ${minimumRole}`
    );
  }
}

/**
 * Validate string length
 */
export function validateStringLength(
  value: string,
  fieldName: string,
  min: number,
  max: number
): void {
  if (!value || value.length < min || value.length > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${fieldName} must be between ${min} and ${max} characters`
    );
  }
}

/**
 * Validate positive number
 */
export function validatePositiveNumber(
  value: number,
  fieldName: string
): void {
  if (typeof value !== "number" || value <= 0 || !isFinite(value)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${fieldName} must be a positive number`
    );
  }
}
