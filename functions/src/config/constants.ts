/**
 * SHIRAH Cloud Functions - Static Constants
 * =============================================
 *
 * STATIC values only — enum-like constants, collection names, roles, etc.
 *
 * All DYNAMIC business rules (network depth, reward points, subscription
 * prices, commission percentages, streak multipliers, wallet limits, etc.)
 * have been moved to Firestore `configurations/app_settings` and are
 * served by `src/config/dynamic-config.ts`.
 *
 * @see dynamic-config.ts for runtime configuration
 */

// ============================================
// REGION CONFIGURATION (deployment — stays static)
// ============================================
/**
 * Server region for Cloud Functions
 * asia-south1 = Mumbai, India (closest to Bangladesh)
 */
export const REGION = "asia-south1";

// ============================================
// WALLET CONFIGURATION — REMOVED (now in dynamic-config)
// ============================================

// ============================================
// ACCOUNT STATES
// ============================================
export const ACCOUNT_STATES = {
  ACTIVE: "active",
  SUSPENDED: "suspended",
  UNDER_REVIEW: "under_review",
  BANNED: "banned",
  DELETED: "deleted",
} as const;

// ============================================
// RISK LEVELS
// ============================================
export const RISK_LEVELS = {
  NORMAL: "normal",
  WATCH: "watch",
  HIGH: "high",
  FRAUD: "fraud",
} as const;

// ============================================
// SUBSCRIPTION STATUS
// ============================================
export const SUBSCRIPTION_STATUS = {
  NONE: "none",
  ACTIVE: "active",
  EXPIRED: "expired",
} as const;

// ============================================
// USER ROLES
// ============================================
export const USER_ROLES = {
  SUPER_ADMIN: "superAdmin",
  ADMIN: "admin",
  MODERATOR: "moderator",
  SUPPORT: "support",
  USER: "user",
} as const;

// ============================================
// TRANSACTION TYPES
// ============================================
export const TRANSACTION_TYPES = {
  CREDIT: "credit",
  DEBIT: "debit",
} as const;

// ============================================
// TRANSACTION SOURCES
// ============================================
export const TRANSACTION_SOURCES = {
  SUBSCRIPTION_COMMISSION: "subscription_commission",
  VERIFICATION_COMMISSION: "verification_commission",
  REWARD_CONVERSION: "reward_conversion",
  WITHDRAWAL: "withdrawal",
  RECHARGE_CASHBACK: "recharge_cashback",
  PRODUCT_SALE: "product_sale",
  MICRO_JOB: "micro_job",
  AD_REWARD: "ad_reward",
  ADMIN_CREDIT: "admin_credit",
  ADMIN_DEBIT: "admin_debit",
} as const;

// ============================================
// AUDIT ACTION TYPES
// ============================================
export const AUDIT_ACTIONS = {
  // User actions
  USER_CREATE: "user.create",
  USER_VERIFY: "user.verify",
  USER_SUBSCRIBE: "user.subscribe",
  USER_SUSPEND: "user.suspend",
  USER_BAN: "user.ban",
  USER_UNBAN: "user.unban",
  USER_DELETE: "user.delete",
  // Wallet actions
  WALLET_CREDIT: "wallet.credit",
  WALLET_DEBIT: "wallet.debit",
  WALLET_LOCK: "wallet.lock",
  WALLET_UNLOCK: "wallet.unlock",
  WITHDRAWAL_REQUEST: "withdrawal.request",
  WITHDRAWAL_APPROVE: "withdrawal.approve",
  WITHDRAWAL_REJECT: "withdrawal.reject",
  // Reward actions
  REWARD_CREDIT: "reward.credit",
  REWARD_CONVERT: "reward.convert",
  // Permission actions
  PERMISSION_GRANT: "permission.grant",
  PERMISSION_REVOKE: "permission.revoke",
  ROLE_CHANGE: "role.change",
  // Admin actions
  ADMIN_LOGIN: "admin.login",
  ADMIN_ACTION: "admin.action",
  // Micro Job actions
  JOB_CREATE: "job.create",
  JOB_APPROVE: "job.approve",
  JOB_REJECT: "job.reject",
  JOB_PAUSE: "job.pause",
  JOB_SUBMISSION_CREATE: "job_submission.create",
  JOB_SUBMISSION_APPROVE: "job_submission.approve",
  JOB_SUBMISSION_REJECT: "job_submission.reject",
  // Home Feed actions
  FEED_CREATE: "feed.create",
  FEED_STATUS_CHANGE: "feed.status_change",
  FEED_REMOVE: "feed.remove",
  FEED_PRIORITY_CHANGE: "feed.priority_change",
} as const;

// ============================================
// COLLECTIONS
// ============================================
export const COLLECTIONS = {
  USERS: "users",
  INVITE_CODES: "invite_codes",
  USER_UPLINES: "user_uplines",
  USER_RELATIONS: "user_relations",
  USER_NETWORK_STATS: "user_network_stats",
  WALLET_TRANSACTIONS: "wallet_transactions",
  REWARD_TRANSACTIONS: "reward_transactions",
  PERMISSIONS: "permissions",
  ADMIN_PERMISSIONS: "admin_permissions",
  PERMISSION_TEMPLATES: "permission_templates",
  AUDIT_LOGS: "audit_logs",
  WITHDRAWAL_REQUESTS: "withdrawal_requests",
  AD_VIEW_LOGS: "ad_view_logs",
  STREAK_DATA: "streak_data",
  CONFIGURATIONS: "configurations",
  // Community
  POSTS: "posts",
  COMMENTS: "comments",
  REPLIES: "replies",
  REACTIONS: "reactions", // subcollection under posts
  // Micro Jobs
  JOBS: "jobs",
  JOB_SUBMISSIONS: "job_submissions",
  // Home Feed
  HOME_FEEDS: "home_feeds",
} as const;

// ============================================
// HOME FEED CONSTANTS
// ============================================
export const FEED_ITEM_TYPES = {
  COMMUNITY_POST: "COMMUNITY_POST",
  MICRO_JOB: "MICRO_JOB",
  RESELLING: "RESELLING",
  DRIVE_OFFER: "DRIVE_OFFER",
  SUGGESTED_FOLLOWING: "SUGGESTED_FOLLOWING",
  ON_DEMAND_POST: "ON_DEMAND_POST",
  BUY_SELL_POST: "BUY_SELL_POST",
  SPONSORED: "SPONSORED",
  ADS_VIEW: "ADS_VIEW",
  NATIVE_AD: "NATIVE_AD",
  ANNOUNCEMENT: "ANNOUNCEMENT",
} as const;

export const FEED_STATUS = {
  ACTIVE: "ACTIVE",
  DISABLED: "DISABLED",
  HIDDEN: "HIDDEN",
  REMOVED: "REMOVED",
} as const;

export const FEED_VISIBILITY = {
  PUBLIC: "PUBLIC",
  FRIENDS: "FRIENDS",
  ONLY_ME: "ONLY_ME",
} as const;

export const FEED_PRIORITY = {
  LOW: 5,
  NORMAL: 10,
  IMPORTANT: 20,
  CRITICAL: 30,
} as const;

// ============================================
// COMMUNITY CONSTANTS
// ============================================
export const POST_STATUS = {
  PENDING: "pending",
  APPROVED: "approved",
  REJECTED: "rejected",
} as const;

export const POST_PRIVACY = {
  PUBLIC: "public",
  FRIENDS: "friends",
  ONLY_ME: "only_me",
} as const;

export const REACTION_TYPES = {
  LIKE: "like",
  LOVE: "love",
  INSIGHTFUL: "insightful",
  SUPPORT: "support",
  INSPIRING: "inspiring",
} as const;
