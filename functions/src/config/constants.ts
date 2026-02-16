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
  RECHARGE_DEBIT: "recharge_debit",
  DRIVE_OFFER_CASHBACK: "drive_offer_cashback",
  RECHARGE_REFUND: "recharge_refund",
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
  // Mobile Recharge actions
  RECHARGE_INITIATE: "recharge.initiate",
  RECHARGE_SUCCESS: "recharge.success",
  RECHARGE_FAILED: "recharge.failed",
  RECHARGE_REFUND: "recharge.refund",
  DRIVE_OFFER_INITIATE: "drive_offer.initiate",
  DRIVE_OFFER_SUCCESS: "drive_offer.success",
  DRIVE_OFFER_FAILED: "drive_offer.failed",
  DRIVE_OFFER_REFUND: "drive_offer.refund",
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
  // Mobile Recharge
  MOBILE_RECHARGE: "mobile_recharge",
  DRIVE_OFFER_CACHE: "drive_offer_cache",
} as const;

// ============================================
// MOBILE RECHARGE CONSTANTS
// ============================================
export const RECHARGE_TYPES = {
  RECHARGE: "recharge",
  DRIVE_OFFER: "drive_offer",
} as const;

export const RECHARGE_STATUS = {
  INITIATED: "initiated",
  SUBMITTED: "submitted",
  PROCESSING: "processing",
  SUCCESS: "success",
  FAILED: "failed",
  REFUNDED: "refunded",
  PENDING_VERIFICATION: "pending_verification",
} as const;

export const OPERATOR_MAP: Record<string, { offerCode: string; name: string }> = {
  "7": { offerCode: "GP", name: "Grameenphone" },
  "3": { offerCode: "GP", name: "Grameenphone" },
  "4": { offerCode: "BL", name: "Banglalink" },
  "9": { offerCode: "BL", name: "Banglalink" },
  "8": { offerCode: "RB", name: "Robi" },
  "6": { offerCode: "AR", name: "Airtel" },
  "5": { offerCode: "TL", name: "Teletalk" },
};

export const OFFER_TO_RECHARGE_MAP: Record<string, string> = {
  "GP": "7",
  "BL": "4",
  "RB": "8",
  "AR": "6",
  "TL": "5",
};

export const NUMBER_TYPE_MAP: Record<string, string> = {
  "1": "Prepaid",
  "2": "Postpaid",
  "3": "Skitto",
  "4": "PowerLoad",
};

export const OFFER_TYPE_MAP: Record<string, string> = {
  "IN": "Internet",
  "BD": "Bundle",
  "MN": "Minutes",
};

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

// ============================================
// ECARE API CONSTANTS
// ============================================
export const ECARE_CONFIG = {
  BASE_URL: "http://118.179.129.98/myportal/api/rechargeapi/recharge_api_thirdparty.php",
  SERVICES: {
    RECHARGE: "MRC",
    STATUS: "MRCSTATUS",
    BALANCE: "BLCK",
    OFFER_PACK: "OFFERPACK",
  },
  POLL_DELAYS: [5000, 10000, 15000, 30000, 60000, 60000, 60000, 60000, 60000, 60000],
  MAX_POLLS: 10,
  HTTP_TIMEOUT: 30000,
  RECHARGE_MIN_AMOUNT: 20,
  RECHARGE_MAX_AMOUNT: 5000,
  CASHBACK_PERCENT: 1.5,
  MAX_DAILY_RECHARGES: 20,
  MAX_DAILY_OFFERS: 10,
  OFFER_CACHE_TTL_MS: 3600000, // 1 hour
} as const;
