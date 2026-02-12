/**
 * SHIRAH Cloud Functions - TypeScript Interfaces
 * All type definitions for the application
 */

import {
  ACCOUNT_STATES,
  RISK_LEVELS,
  SUBSCRIPTION_STATUS,
  USER_ROLES,
  TRANSACTION_TYPES,
} from "../config/constants";

// ============================================
// USER TYPES
// ============================================
export interface UserIdentity {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  authProvider: "password" | "google" | "phone";
  photoURL: string;
  coverURL: string;
}

export interface UserCodes {
  inviteCode: string;
  referralCode: string; // Same as UID
}

export interface UserNetwork {
  parentUid: string | null;
  joinedVia: "invite" | "direct" | "manual";
}

export interface UserStatus {
  accountState: typeof ACCOUNT_STATES[keyof typeof ACCOUNT_STATES];
  verified: boolean;
  subscription: typeof SUBSCRIPTION_STATUS[keyof typeof SUBSCRIPTION_STATUS];
  riskLevel: typeof RISK_LEVELS[keyof typeof RISK_LEVELS];
}

export interface UserWallet {
  balanceBDT: number;
  rewardPoints: number;
  locked: boolean;
}

export interface UserPermissions {
  canPost: boolean;
  canWithdraw: boolean;
  canViewCommunity: boolean;
}

export interface UserFlags {
  isTestUser: boolean;
}

export interface UserLimits {
  dailyAdsViewed: number;
  dailyRewardConverted: number;
  lastLimitReset: string; // ISO date string
}

export interface UserMeta {
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  lastLoginAt: FirebaseFirestore.Timestamp | null;
  lastActiveAt: FirebaseFirestore.Timestamp | null;
}

export interface UserSystem {
  banReason: string | null;
  suspendUntil: FirebaseFirestore.Timestamp | null;
  notes: string;
}

export interface UserDocument {
  uid: string;
  role: typeof USER_ROLES[keyof typeof USER_ROLES];
  identity: UserIdentity;
  codes: UserCodes;
  network: UserNetwork;
  status: UserStatus;
  wallet: UserWallet;
  permissions: UserPermissions;
  flags: UserFlags;
  limits: UserLimits;
  meta: UserMeta;
  system: UserSystem;
}

// ============================================
// INVITE CODE TYPES
// ============================================
export interface InviteCodeDocument {
  uid: string;
  email: string;
  createdAt: FirebaseFirestore.Timestamp;
}

// ============================================
// NETWORK TYPES
// ============================================
export interface UserUplines {
  u1: string | null;
  u2: string | null;
  u3: string | null;
  u4: string | null;
  u5: string | null;
  u6: string | null;
  u7: string | null;
  u8: string | null;
  u9: string | null;
  u10: string | null;
  u11: string | null;
  u12: string | null;
  u13: string | null;
  u14: string | null;
  u15: string | null;
  maxDepth: number;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface UserRelation {
  ancestorUid: string;
  descendantUid: string;
  level: number;
  descendantVerified: boolean;
  descendantSubscribed: boolean;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface LevelStats {
  total: number;
  verified: number;
  subscribed: number;
}

export interface UserNetworkStats {
  [key: string]: LevelStats | FirebaseFirestore.Timestamp;
  level1: LevelStats;
  level2: LevelStats;
  level3: LevelStats;
  level4: LevelStats;
  level5: LevelStats;
  level6: LevelStats;
  level7: LevelStats;
  level8: LevelStats;
  level9: LevelStats;
  level10: LevelStats;
  level11: LevelStats;
  level12: LevelStats;
  level13: LevelStats;
  level14: LevelStats;
  level15: LevelStats;
  updatedAt: FirebaseFirestore.Timestamp;
}

// ============================================
// WALLET TYPES
// ============================================
export interface WalletTransaction {
  id: string;
  uid: string;
  type: typeof TRANSACTION_TYPES[keyof typeof TRANSACTION_TYPES];
  source: string;
  amount: number;
  balanceBefore: number;
  balanceAfter: number;
  description: string;
  reference: string | null;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface RewardTransaction {
  id: string;
  uid: string;
  type: typeof TRANSACTION_TYPES[keyof typeof TRANSACTION_TYPES];
  source: string;
  points: number;
  pointsBefore: number;
  pointsAfter: number;
  description: string;
  reference: string | null;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface WithdrawalRequest {
  id: string;
  uid: string;
  amount: number;
  fee: number;
  netAmount: number;
  paymentMethod: string;
  paymentDetails: Record<string, string>;
  status: "pending" | "approved" | "rejected" | "processing" | "completed";
  adminUid: string | null;
  adminNote: string | null;
  createdAt: FirebaseFirestore.Timestamp;
  processedAt: FirebaseFirestore.Timestamp | null;
}

// ============================================
// REWARD TYPES
// ============================================
export interface StreakData {
  uid: string;
  currentStreak: number;
  lastActiveDate: string; // ISO date string YYYY-MM-DD
  highestStreak: number;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface AdViewLog {
  id: string;
  uid: string;
  adType: string;
  pointsEarned: number;
  multiplier: number;
  deviceId: string;
  ipHash: string;
  createdAt: FirebaseFirestore.Timestamp;
}

// ============================================
// PERMISSION TYPES
// ============================================
export interface Permission {
  id: string;
  group: string;
  description: string;
  dangerLevel: "low" | "medium" | "high" | "critical";
}

export interface AdminPermissions {
  uid: string;
  permissions: Record<string, boolean>;
  assignedBy: string;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface PermissionTemplate {
  id: string;
  name: string;
  description: string;
  permissions: string[];
  createdBy: string;
  createdAt: FirebaseFirestore.Timestamp;
}

// ============================================
// AUDIT TYPES
// ============================================
export interface AuditLog {
  id: string;
  actorUid: string;
  actorRole: string;
  action: string;
  targetUid: string | null;
  targetCollection: string | null;
  targetDocId: string | null;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  metadata: Record<string, unknown>;
  ipHash: string | null;
  device: string | null;
  timestamp: FirebaseFirestore.Timestamp;
}

// ============================================
// API RESPONSE TYPES
// ============================================
export interface ApiResponse<T = unknown> {
  success: boolean;
  message: string;
  data?: T;
  error?: {
    code: string;
    details?: string;
  };
}

// ============================================
// FUNCTION REQUEST TYPES
// ============================================
export interface CreateUserRequest {
  email: string;
  password: string;
  firstName: string;
  lastName?: string;
  phone: string;
  inviteCode: string;
}

export interface GoogleSignInCompleteRequest {
  inviteCode: string;
}

export interface VerifyUserRequest {
  uid: string;
  paymentReference: string;
}

export interface SubscribeUserRequest {
  uid: string;
  paymentReference: string;
}

export interface ConvertRewardsRequest {
  points: number;
}

export interface WithdrawRequest {
  amount: number;
  paymentMethod: string;
  paymentDetails: Record<string, string>;
}

export interface AdminActionRequest {
  targetUid: string;
  action: string;
  reason?: string;
  data?: Record<string, unknown>;
}

export interface GrantPermissionRequest {
  targetUid: string;
  permissions: string[];
}

export interface RevokePermissionRequest {
  targetUid: string;
  permissions: string[];
}

export interface ChangeRoleRequest {
  targetUid: string;
  newRole: string;
}

export interface RecordAdViewRequest {
  adType: string;
  deviceId: string;
}

// ============================================
// COMMUNITY POST TYPES
// ============================================
export interface PostAuthor {
  uid: string;
  name: string;
  photo: string;
}

export interface PostContent {
  text: string;
  images: string[];
}

export interface PostReactionSummary {
  total: number;
  like: number;
  love: number;
  insightful: number;
  support: number;
  inspiring: number;
}

export interface CommunityPost {
  postId: string;
  author: PostAuthor;
  content: PostContent;
  privacy: "public" | "friends" | "only_me";
  status: "pending" | "approved" | "rejected";
  reactionSummary: PostReactionSummary;
  commentCount: number;
  shareCount: number;
  isDeleted: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface PostReaction {
  userId: string;
  postId: string;
  reaction: "like" | "love" | "insightful" | "support" | "inspiring";
  userName: string | null;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface PostComment {
  commentId: string;
  postId: string;
  author: PostAuthor;
  text: string;
  reactionSummary: PostReactionSummary;
  replyCount: number;
  isDeleted: boolean;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface PostReply {
  replyId: string;
  postId: string;
  commentId: string;
  author: PostAuthor;
  text: string;
  isDeleted: boolean;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface CreatePostRequest {
  text: string;
  images: string[];
  privacy: "public" | "friends" | "only_me";
}

export interface ToggleReactionRequest {
  postId: string;
  reactionType: "like" | "love" | "insightful" | "support" | "inspiring";
}

export interface AddCommentRequest {
  postId: string;
  text: string;
}

export interface AddReplyRequest {
  postId: string;
  commentId: string;
  text: string;
}

export interface ModeratePostRequest {
  postId: string;
  action: "approve" | "reject";
  reason?: string;
}
