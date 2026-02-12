/**
 * SHIRAH Cloud Functions - Main Entry Point
 * ============================================
 *
 * This file exports all Cloud Functions for the SHIRAH application.
 * Functions are organized by feature modules for maintainability.
 *
 * Structure:
 * - config/     → Constants and configuration
 * - types/      → TypeScript interfaces
 * - utils/      → Helper and validation functions
 * - features/   → Feature-specific function modules
 *   ├── auth/       → Authentication triggers and user verification
 *   ├── users/      → User creation and profile management
 *   ├── invite-codes/  → Invite code generation and validation
 *   ├── network/    → Upline/downline relationship management
 *   ├── wallet/     → Wallet balance and transactions
 *   ├── rewards/    → Reward points and streaks
 *   ├── permissions/  → RBAC and admin permissions
 *   ├── admin/      → Admin-only operations
 *   └── audit/      → Audit logging
 *
 * Naming Convention:
 * - Callable functions: camelCase (e.g., createUser, recordAdView)
 * - Triggers: on{Event}{Resource} (e.g., onUserDeleted)
 *
 * @author SHIRAH Team
 * @version 1.0.0
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// ============================================
// AUTH FUNCTIONS
// ============================================
// NOTE: onUserLogin disabled - requires Google Cloud Identity Platform (GCIP)
// Login timestamp tracking is handled in Flutter app instead
// export { onUserLogin } from "./features/auth/auth-and-verification";

export {
  onUserDeleted,
  verifyUserProfile,
  subscribeUser,
  checkAuthStatus,
} from "./features/auth/auth-and-verification";

// ============================================
// USER FUNCTIONS
// ============================================
export {
  createUser,
  completeGoogleSignIn,
  getUserProfile,
  updateUserProfile,
} from "./features/users/user-management";

// ============================================
// WALLET FUNCTIONS
// ============================================
export {
  requestWithdrawal,
  getMyWalletTransactions,
  getMyWithdrawalRequests,
} from "./features/wallet/wallet-and-withdrawal";

// ============================================
// REWARD FUNCTIONS
// ============================================
export {
  recordAdView,
  convertRewardPoints,
  getStreakInfo,
  getMyRewardTransactions,
} from "./features/rewards/reward-and-streak";

// ============================================
// PERMISSION FUNCTIONS
// ============================================
export {
  grantUserPermissions,
  revokeUserPermissions,
  changeUserRole,
  getUserPermissions,
  getMyPermissions,
} from "./features/permissions/rbac-and-permissions";

// ============================================
// ADMIN FUNCTIONS
// ============================================
export {
  suspendUser,
  banUser,
  unbanUser,
  approveWithdrawal,
  rejectWithdrawal,
  adminCreditWallet,
  adminCreditRewardPoints,
  adminLockWallet,
  adminUnlockWallet,
  setUserRiskLevel,
  getPendingWithdrawals,
  getAdminUserDetails,
  searchUsers,
} from "./features/admin/admin-operations";

// ============================================
// CONFIGURATION FUNCTIONS
// ============================================
export {
  seedConfigurations,
  updateAppConfig,
  getAppConfigAdmin,
} from "./features/admin/config-management";

// ============================================
// COMMUNITY FUNCTIONS
// ============================================
export {
  createCommunityPost,
  togglePostReaction,
  addPostComment,
  addPostReply,
  moderatePost,
  deleteCommunityPost,
} from "./features/community/community-operations";

// ============================================
// MICRO JOB FUNCTIONS
// ============================================
export {
  createMicroJob,
  getAvailableJobs,
  getMicroJobDetails,
  getMyCreatedJobs,
  submitJobProof,
  getMySubmissions,
  reviewJobSubmission,
  adminReviewJob,
  getJobSubmissions,
} from "./features/micro-jobs/micro-job-operations";

// ============================================
// FUNCTION REFERENCE (For Flutter Developers)
// ============================================
/**
 * USER FUNCTIONS (Callable):
 * - createUser(email, password, firstName, lastName, phone, inviteCode)
 * - completeGoogleSignIn(inviteCode)
 * - getUserProfile()
 * - updateUserProfile(firstName?, lastName?, phone?, photoURL?, coverURL?)
 *
 * AUTH FUNCTIONS (Callable):
 * - verifyUserProfile(paymentReference)
 * - subscribeUser(paymentReference)
 * - checkAuthStatus()
 *
 * AUTH TRIGGERS:
 * - onUserLogin (beforeSignIn trigger)
 * - onUserDeleted (onDelete trigger)
 *
 * WALLET FUNCTIONS (Callable):
 * - requestWithdrawal(amount, paymentMethod, paymentDetails)
 * - getMyWalletTransactions(limit?)
 * - getMyWithdrawalRequests(limit?)
 *
 * REWARD FUNCTIONS (Callable):
 * - recordAdView(adType, deviceId)
 * - convertRewardPoints(points)
 * - getStreakInfo()
 * - getMyRewardTransactions(limit?)
 *
 * PERMISSION FUNCTIONS (Callable):
 * - grantUserPermissions(targetUid, permissions[]) [Admin]
 * - revokeUserPermissions(targetUid, permissions[]) [Admin]
 * - changeUserRole(targetUid, newRole) [Admin]
 * - getUserPermissions(targetUid) [Admin]
 * - getMyPermissions()
 *
 * ADMIN FUNCTIONS (Callable):
 * - suspendUser(targetUid, reason, suspendUntil?) [Admin]
 * - banUser(targetUid, reason) [Admin]
 * - unbanUser(targetUid, reason) [Admin]
 * - approveWithdrawal(withdrawalId, adminNote?) [Admin]
 * - rejectWithdrawal(withdrawalId, reason) [Admin]
 * - adminCreditWallet(targetUid, amount, reason) [Admin]
 * - adminCreditRewardPoints(targetUid, points, reason) [Admin]
 * - adminLockWallet(targetUid, reason) [Admin]
 * - adminUnlockWallet(targetUid, reason) [Admin]
 * - setUserRiskLevel(targetUid, riskLevel, reason) [Admin]
 * - getPendingWithdrawals(limit?) [Admin]
 * - getAdminUserDetails(targetUid) [Admin]
 * - searchUsers(query, field, limit?) [Admin]
 *
 * CONFIGURATION FUNCTIONS (Callable):
 * - seedConfigurations() [SuperAdmin]
 * - updateAppConfig(updates) [SuperAdmin]
 * - getAppConfigAdmin() [Admin]
 *
 * COMMUNITY FUNCTIONS (Callable):
 * - createCommunityPost(text, images[], privacy)
 * - togglePostReaction(postId, reactionType)
 * - addPostComment(postId, text)
 * - addPostReply(postId, commentId, text)
 * - moderatePost(postId, action, reason?) [Admin/Moderator]
 * - deleteCommunityPost(postId)
 */
