/**
 * SHIRAH Cloud Functions - Home Feed Module
 * ============================================
 *
 * Responsibilities (per documentation v3):
 * MUST DO:
 *   - Auto-create feed items when posts/jobs are created or approved
 *   - Admin-only write protection for NATIVE_AD
 *   - Audit log every status change
 *   - Global ads enable/disable flag
 *
 * MUST NOT DO:
 *   - Fetch ads
 *   - Track impressions
 *   - Inject ads into feed (Flutter handles gap algorithm)
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  COLLECTIONS,
  FEED_ITEM_TYPES,
  FEED_STATUS,
  FEED_VISIBILITY,
  FEED_PRIORITY,
  REGION,
  USER_ROLES,
  AUDIT_ACTIONS,
  POST_STATUS,
} from "../../config/constants";
import {
  HomeFeedDocument,
  UpdateFeedStatusRequest,
  UpdateFeedPriorityRequest,
  AdminCreateNativeAdRequest,
  DeleteFeedItemRequest,
  ToggleFeedPinRequest,
  BulkUpdateFeedStatusRequest,
  EmergencyPauseAdsRequest,
  GetAdminFeedItemsRequest,
  ApiResponse,
  UserDocument,
} from "../../types";
import { serverTimestamp } from "../../utils/helpers";
import { validateAuthenticated } from "../../utils/validators";

const db = admin.firestore();

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Log an audit trail entry for feed operations
 */
async function logFeedAudit(
  actorUid: string,
  actorRole: string,
  action: string,
  feedId: string,
  before: Record<string, unknown> | null,
  after: Record<string, unknown> | null,
  metadata: Record<string, unknown> = {}
): Promise<void> {
  try {
    await db.collection(COLLECTIONS.AUDIT_LOGS).add({
      actorUid,
      actorRole,
      action,
      targetUid: null,
      targetCollection: COLLECTIONS.HOME_FEEDS,
      targetDocId: feedId,
      before,
      after,
      metadata,
      ipHash: null,
      device: null,
      timestamp: serverTimestamp(),
    });
  } catch (error) {
    functions.logger.error("Failed to log feed audit", error);
  }
}

/**
 * Get default priority for a feed item type
 */
export function getDefaultPriority(type: string): number {
  switch (type) {
    case FEED_ITEM_TYPES.COMMUNITY_POST:
    case FEED_ITEM_TYPES.ON_DEMAND_POST:
    case FEED_ITEM_TYPES.BUY_SELL_POST:
    case FEED_ITEM_TYPES.ANNOUNCEMENT:
      return FEED_PRIORITY.NORMAL;
    case FEED_ITEM_TYPES.MICRO_JOB:
    case FEED_ITEM_TYPES.RESELLING:
    case FEED_ITEM_TYPES.DRIVE_OFFER:
      return FEED_PRIORITY.IMPORTANT;
    case FEED_ITEM_TYPES.NATIVE_AD:
    case FEED_ITEM_TYPES.SPONSORED:
    case FEED_ITEM_TYPES.ADS_VIEW:
      return FEED_PRIORITY.CRITICAL;
    case FEED_ITEM_TYPES.SUGGESTED_FOLLOWING:
      return FEED_PRIORITY.LOW;
    default:
      return FEED_PRIORITY.NORMAL;
  }
}

/**
 * Validate feed item type
 */
function isValidFeedType(type: string): boolean {
  return Object.values(FEED_ITEM_TYPES).includes(type as any);
}

/**
 * Validate feed status
 */
function isValidFeedStatus(status: string): boolean {
  return Object.values(FEED_STATUS).includes(status as any);
}

// ============================================
// FIRESTORE TRIGGERS - Auto Feed Creation
// ============================================

/**
 * Trigger: When a community post is approved, auto-create a feed item
 * Listens to /posts/{postId} updates
 */
export const onPostApproved = onDocumentUpdated(
  {
    document: `${COLLECTIONS.POSTS}/{postId}`,
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const postId = event.params.postId;

    if (!before || !after) return null;

    // Only trigger when status changes to "approved"
    if (
      before.status === POST_STATUS.APPROVED ||
      after.status !== POST_STATUS.APPROVED
    ) {
      return null;
    }

    // Check if feed item already exists for this post
    const existingFeed = await db
      .collection(COLLECTIONS.HOME_FEEDS)
      .where("refId", "==", postId)
      .where("type", "==", FEED_ITEM_TYPES.COMMUNITY_POST)
      .limit(1)
      .get();

    if (!existingFeed.empty) {
      functions.logger.info(`Feed item already exists for post: ${postId}`);
      return null;
    }

    // Determine visibility from post privacy
    let visibility: string = FEED_VISIBILITY.PUBLIC;
    if (after.privacy === "friends") {
      visibility = FEED_VISIBILITY.FRIENDS;
    } else if (after.privacy === "only_me") {
      visibility = FEED_VISIBILITY.ONLY_ME;
    }

    // Create feed item
    const feedDoc: Omit<HomeFeedDocument, "feedId"> & { feedId?: string } = {
      type: FEED_ITEM_TYPES.COMMUNITY_POST,
      refId: postId,
      priority: FEED_PRIORITY.NORMAL,
      status: FEED_STATUS.ACTIVE,
      visibility,
      createdAt: after.createdAt || serverTimestamp(),
      meta: {
        authorId: after.author?.uid || null,
        adminPinned: false,
        boosted: false,
      },
    };

    const docRef = await db.collection(COLLECTIONS.HOME_FEEDS).add(feedDoc);
    await docRef.update({ feedId: docRef.id });

    functions.logger.info(
      `✅ Feed item created for approved post: ${postId} → ${docRef.id}`
    );

    return null;
  }
);

/**
 * Trigger: When a micro job is approved, auto-create a feed item
 * Listens to /jobs/{jobId} updates
 */
export const onJobApproved = onDocumentUpdated(
  {
    document: `${COLLECTIONS.JOBS}/{jobId}`,
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const jobId = event.params.jobId;

    if (!before || !after) return null;

    // Only trigger when status changes to APPROVED
    if (before.status === "APPROVED" || after.status !== "APPROVED") {
      return null;
    }

    // Check if feed item already exists
    const existingFeed = await db
      .collection(COLLECTIONS.HOME_FEEDS)
      .where("refId", "==", jobId)
      .where("type", "==", FEED_ITEM_TYPES.MICRO_JOB)
      .limit(1)
      .get();

    if (!existingFeed.empty) {
      functions.logger.info(`Feed item already exists for job: ${jobId}`);
      return null;
    }

    const feedDoc: Omit<HomeFeedDocument, "feedId"> & { feedId?: string } = {
      type: FEED_ITEM_TYPES.MICRO_JOB,
      refId: jobId,
      priority: FEED_PRIORITY.IMPORTANT,
      status: FEED_STATUS.ACTIVE,
      visibility: FEED_VISIBILITY.PUBLIC,
      createdAt: after.createdAt || serverTimestamp(),
      meta: {
        authorId: after.authorId || null,
        adminPinned: false,
        boosted: false,
      },
    };

    const docRef = await db.collection(COLLECTIONS.HOME_FEEDS).add(feedDoc);
    await docRef.update({ feedId: docRef.id });

    functions.logger.info(
      `✅ Feed item created for approved job: ${jobId} → ${docRef.id}`
    );

    return null;
  }
);

/**
 * Trigger: When a post is deleted/removed, disable its feed item
 */
export const onPostDeleted = onDocumentUpdated(
  {
    document: `${COLLECTIONS.POSTS}/{postId}`,
    region: REGION,
  },
  async (event) => {
    const after = event.data?.after.data();
    const postId = event.params.postId;

    if (!after) return null;

    // Only trigger when post is marked as deleted or rejected
    if (!after.isDeleted && after.status !== "rejected") {
      return null;
    }

    // Find and disable the feed item
    const feedSnapshot = await db
      .collection(COLLECTIONS.HOME_FEEDS)
      .where("refId", "==", postId)
      .where("type", "==", FEED_ITEM_TYPES.COMMUNITY_POST)
      .get();

    const batch = db.batch();
    for (const doc of feedSnapshot.docs) {
      batch.update(doc.ref, {
        status: FEED_STATUS.REMOVED,
        updatedAt: serverTimestamp(),
      });
    }
    await batch.commit();

    functions.logger.info(
      `✅ Feed items removed for deleted post: ${postId} (${feedSnapshot.size} items)`
    );

    return null;
  }
);

/**
 * Trigger: When a micro job is completed/paused, update its feed item
 */
export const onJobStatusChange = onDocumentUpdated(
  {
    document: `${COLLECTIONS.JOBS}/{jobId}`,
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const jobId = event.params.jobId;

    if (!before || !after) return null;

    // Only process relevant status changes
    if (before.status === after.status) return null;

    const completedStatuses = ["COMPLETED", "PAUSED", "REJECTED"];
    if (!completedStatuses.includes(after.status)) return null;

    // Find and update the feed item
    const feedSnapshot = await db
      .collection(COLLECTIONS.HOME_FEEDS)
      .where("refId", "==", jobId)
      .where("type", "==", FEED_ITEM_TYPES.MICRO_JOB)
      .get();

    const newStatus =
      after.status === "PAUSED" ? FEED_STATUS.DISABLED : FEED_STATUS.REMOVED;

    const batch = db.batch();
    for (const doc of feedSnapshot.docs) {
      batch.update(doc.ref, {
        status: newStatus,
        updatedAt: serverTimestamp(),
      });
    }
    await batch.commit();

    functions.logger.info(
      `✅ Feed items updated for job ${jobId}: status → ${newStatus}`
    );

    return null;
  }
);

// ============================================
// CALLABLE FUNCTIONS - Admin Operations
// ============================================

/**
 * Admin: Create a Native Ad feed item
 * Only admins can create NATIVE_AD type feeds
 */
export const createNativeAdFeed = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<AdminCreateNativeAdRequest>
  ): Promise<ApiResponse> => {
    // Auth check
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can create native ad feeds"
      );
    }

    // Validate inputs
    if (!data.adUnitId || !data.platform) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "adUnitId and platform are required"
      );
    }

    const feedDoc: Omit<HomeFeedDocument, "feedId"> & { feedId?: string } = {
      type: FEED_ITEM_TYPES.NATIVE_AD,
      refId: null,
      priority: FEED_PRIORITY.CRITICAL,
      status: FEED_STATUS.ACTIVE,
      visibility: FEED_VISIBILITY.PUBLIC,
      createdAt: serverTimestamp() as any,
      meta: {
        authorId: null,
        adminPinned: false,
        boosted: false,
        adUnitId: data.adUnitId,
        platform: data.platform,
        emergencyPause: false,
      },
      rules: {
        minGap: data.minGap || 6,
        maxPerSession: data.maxPerSession || 3,
      },
    };

    const docRef = await db.collection(COLLECTIONS.HOME_FEEDS).add(feedDoc);
    await docRef.update({ feedId: docRef.id });

    // Audit log
    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_CREATE,
      docRef.id,
      null,
      feedDoc as unknown as Record<string, unknown>,
      { type: FEED_ITEM_TYPES.NATIVE_AD, adUnitId: data.adUnitId }
    );

    return {
      success: true,
      message: "Native ad feed item created",
      data: { feedId: docRef.id },
    } as ApiResponse;
  }
);

/**
 * Admin: Update feed item status (enable/disable/remove)
 */
export const updateFeedItemStatus = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<UpdateFeedStatusRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin/moderator role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const allowedRoles = [
      USER_ROLES.SUPER_ADMIN,
      USER_ROLES.ADMIN,
      USER_ROLES.MODERATOR,
    ];
    if (!allowedRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient permissions"
      );
    }

    // Validate inputs
    if (!data.feedId || !data.status) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feedId and status are required"
      );
    }
    if (!isValidFeedStatus(data.status)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid status: ${data.status}`
      );
    }

    // Get current feed doc
    const feedRef = db.collection(COLLECTIONS.HOME_FEEDS).doc(data.feedId);
    const feedDoc = await feedRef.get();
    if (!feedDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Feed item not found");
    }

    const beforeData = feedDoc.data()!;

    // Update status
    await feedRef.update({
      status: data.status,
      updatedAt: serverTimestamp(),
    });

    // Audit log
    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_STATUS_CHANGE,
      data.feedId,
      { status: beforeData.status },
      { status: data.status },
      { reason: data.reason || "No reason provided" }
    );

    return {
      success: true,
      message: `Feed item status updated to ${data.status}`,
    } as ApiResponse;
  }
);

/**
 * Admin: Update feed item priority
 */
export const updateFeedItemPriority = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<UpdateFeedPriorityRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can change feed priority"
      );
    }

    if (!data.feedId || data.priority == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feedId and priority are required"
      );
    }

    const feedRef = db.collection(COLLECTIONS.HOME_FEEDS).doc(data.feedId);
    const feedDoc = await feedRef.get();
    if (!feedDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Feed item not found");
    }

    const beforeData = feedDoc.data()!;

    await feedRef.update({
      priority: data.priority,
      updatedAt: serverTimestamp(),
    });

    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_PRIORITY_CHANGE,
      data.feedId,
      { priority: beforeData.priority },
      { priority: data.priority }
    );

    return {
      success: true,
      message: `Feed item priority updated to ${data.priority}`,
    } as ApiResponse;
  }
);

/**
 * Admin: Get paginated feed items with filters and cursor-based pagination
 * Supports filtering by status, type, and cursor-based pagination for scale
 */
export const getAdminFeedItems = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<GetAdminFeedItemsRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [
      USER_ROLES.SUPER_ADMIN,
      USER_ROLES.ADMIN,
      USER_ROLES.MODERATOR,
    ];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient permissions"
      );
    }

    const limit = Math.min(data?.limit || 50, 100);
    const statusFilter = data?.status;
    const typeFilter = data?.type;
    const startAfterFeedId = data?.startAfterFeedId;

    let query: FirebaseFirestore.Query = db.collection(COLLECTIONS.HOME_FEEDS);

    if (statusFilter && isValidFeedStatus(statusFilter)) {
      query = query.where("status", "==", statusFilter);
    }
    if (typeFilter && isValidFeedType(typeFilter)) {
      query = query.where("type", "==", typeFilter);
    }

    query = query.orderBy("createdAt", "desc");

    // Cursor-based pagination
    if (startAfterFeedId) {
      const cursorDoc = await db
        .collection(COLLECTIONS.HOME_FEEDS)
        .doc(startAfterFeedId)
        .get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    query = query.limit(limit + 1); // fetch one extra to determine hasMore

    const snapshot = await query.get();
    const hasMore = snapshot.docs.length > limit;
    const docs = hasMore ? snapshot.docs.slice(0, limit) : snapshot.docs;

    const feedItems = docs.map((doc) => ({
      ...doc.data(),
      feedId: doc.id,
    }));

    const lastFeedId = docs.length > 0 ? docs[docs.length - 1].id : null;

    return {
      success: true,
      message: `Found ${feedItems.length} feed items`,
      data: {
        feeds: feedItems,
        total: feedItems.length,
        hasMore,
        lastFeedId,
      },
    } as ApiResponse;
  }
);

/**
 * Admin: Get aggregated feed statistics (counts by type and status)
 * Uses collection group queries for efficient counting
 */
export const getAdminFeedStats = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<void>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [
      USER_ROLES.SUPER_ADMIN,
      USER_ROLES.ADMIN,
      USER_ROLES.MODERATOR,
    ];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Insufficient permissions"
      );
    }

    // Count all feeds by querying once and aggregating in memory
    // For 100k feeds this is expensive; use count() aggregation
    const feedRef = db.collection(COLLECTIONS.HOME_FEEDS);

    // Use Firestore count() aggregation queries (cost: 1 read per 1000 docs counted)
    const [
      totalSnap,
      activeSnap,
      disabledSnap,
      hiddenSnap,
      removedSnap,
      postSnap,
      jobSnap,
      adSnap,
      pinnedSnap,
    ] = await Promise.all([
      feedRef.count().get(),
      feedRef.where("status", "==", FEED_STATUS.ACTIVE).count().get(),
      feedRef.where("status", "==", FEED_STATUS.DISABLED).count().get(),
      feedRef.where("status", "==", FEED_STATUS.HIDDEN).count().get(),
      feedRef.where("status", "==", FEED_STATUS.REMOVED).count().get(),
      feedRef
        .where("type", "==", FEED_ITEM_TYPES.COMMUNITY_POST)
        .where("status", "==", FEED_STATUS.ACTIVE)
        .count()
        .get(),
      feedRef
        .where("type", "==", FEED_ITEM_TYPES.MICRO_JOB)
        .where("status", "==", FEED_STATUS.ACTIVE)
        .count()
        .get(),
      feedRef
        .where("type", "==", FEED_ITEM_TYPES.NATIVE_AD)
        .where("status", "==", FEED_STATUS.ACTIVE)
        .count()
        .get(),
      feedRef
        .where("meta.adminPinned", "==", true)
        .where("status", "==", FEED_STATUS.ACTIVE)
        .count()
        .get(),
    ]);

    return {
      success: true,
      message: "Feed stats retrieved",
      data: {
        total: totalSnap.data().count,
        byStatus: {
          active: activeSnap.data().count,
          disabled: disabledSnap.data().count,
          hidden: hiddenSnap.data().count,
          removed: removedSnap.data().count,
        },
        byType: {
          communityPost: postSnap.data().count,
          microJob: jobSnap.data().count,
          nativeAd: adSnap.data().count,
        },
        pinned: pinnedSnap.data().count,
      },
    } as ApiResponse;
  }
);

/**
 * Admin: Delete a feed item permanently
 * Only superAdmin and admin can hard-delete
 */
export const deleteFeedItem = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<DeleteFeedItemRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can delete feed items"
      );
    }

    if (!data.feedId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feedId is required"
      );
    }

    const feedRef = db.collection(COLLECTIONS.HOME_FEEDS).doc(data.feedId);
    const feedDoc = await feedRef.get();
    if (!feedDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Feed item not found");
    }

    const beforeData = feedDoc.data()!;

    await feedRef.delete();

    // Audit log
    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_DELETE,
      data.feedId,
      beforeData as Record<string, unknown>,
      null,
      { deletedType: beforeData.type }
    );

    return {
      success: true,
      message: "Feed item deleted permanently",
    } as ApiResponse;
  }
);

/**
 * Admin: Toggle adminPinned flag on a feed item
 */
export const toggleFeedPin = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<ToggleFeedPinRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can pin feed items"
      );
    }

    if (!data.feedId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feedId is required"
      );
    }

    const feedRef = db.collection(COLLECTIONS.HOME_FEEDS).doc(data.feedId);
    const feedDoc = await feedRef.get();
    if (!feedDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Feed item not found");
    }

    const currentData = feedDoc.data()!;
    const currentPinned = currentData.meta?.adminPinned || false;
    const newPinned = !currentPinned;

    await feedRef.update({
      "meta.adminPinned": newPinned,
      updatedAt: serverTimestamp(),
    });

    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_PIN_TOGGLE,
      data.feedId,
      { adminPinned: currentPinned },
      { adminPinned: newPinned }
    );

    return {
      success: true,
      message: newPinned ? "Feed item pinned" : "Feed item unpinned",
      data: { pinned: newPinned },
    } as ApiResponse;
  }
);

/**
 * Admin: Bulk update status of multiple feed items at once
 * Maximum 25 items per batch to stay within Firestore limits
 */
export const bulkUpdateFeedStatus = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<BulkUpdateFeedStatusRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can bulk update feed items"
      );
    }

    if (!data.feedIds || !Array.isArray(data.feedIds) || data.feedIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "feedIds array is required and must not be empty"
      );
    }
    if (data.feedIds.length > 25) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 25 feed items per batch"
      );
    }
    if (!data.status || !isValidFeedStatus(data.status)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `Invalid status: ${data.status}`
      );
    }

    const batch = db.batch();
    let updated = 0;

    for (const feedId of data.feedIds) {
      const feedRef = db.collection(COLLECTIONS.HOME_FEEDS).doc(feedId);
      const feedDoc = await feedRef.get();
      if (feedDoc.exists) {
        batch.update(feedRef, {
          status: data.status,
          updatedAt: serverTimestamp(),
        });
        updated++;
      }
    }

    await batch.commit();

    // Audit log for bulk operation
    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_BULK_STATUS,
      "bulk",
      null,
      { status: data.status, feedIds: data.feedIds },
      { reason: data.reason || "Bulk status update", count: updated }
    );

    return {
      success: true,
      message: `${updated} feed items updated to ${data.status}`,
      data: { updated },
    } as ApiResponse;
  }
);

/**
 * Admin: Emergency pause/unpause all native ad feeds
 * Sets status to DISABLED (pause) or ACTIVE (unpause) for all NATIVE_AD feeds
 */
export const emergencyPauseAds = functions.https.onCall(
  { region: REGION },
  async (
    request: functions.https.CallableRequest<EmergencyPauseAdsRequest>
  ): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const data = request.data;

    // Verify admin role (only superAdmin/admin for emergency ops)
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data() as UserDocument;
    const adminRoles = [USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN];
    if (!adminRoles.includes(userData.role as any)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can use emergency pause"
      );
    }

    if (data.pause === undefined || data.pause === null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "pause (true/false) is required"
      );
    }

    const targetStatus = data.pause ? FEED_STATUS.DISABLED : FEED_STATUS.ACTIVE;
    const sourceStatus = data.pause ? FEED_STATUS.ACTIVE : FEED_STATUS.DISABLED;

    // Find all native ad feeds with source status
    const adFeeds = await db
      .collection(COLLECTIONS.HOME_FEEDS)
      .where("type", "==", FEED_ITEM_TYPES.NATIVE_AD)
      .where("status", "==", sourceStatus)
      .get();

    if (adFeeds.empty) {
      return {
        success: true,
        message: `No native ad feeds to ${data.pause ? "pause" : "unpause"}`,
        data: { updated: 0 },
      } as ApiResponse;
    }

    // Batch update in chunks of 500
    const chunks: FirebaseFirestore.DocumentSnapshot[][] = [];
    for (let i = 0; i < adFeeds.docs.length; i += 500) {
      chunks.push(adFeeds.docs.slice(i, i + 500));
    }

    let totalUpdated = 0;
    for (const chunk of chunks) {
      const batch = db.batch();
      for (const doc of chunk) {
        batch.update(doc.ref, {
          status: targetStatus,
          "meta.emergencyPause": data.pause,
          updatedAt: serverTimestamp(),
        });
      }
      await batch.commit();
      totalUpdated += chunk.length;
    }

    // Audit log
    await logFeedAudit(
      uid,
      userData.role,
      AUDIT_ACTIONS.FEED_EMERGENCY_PAUSE,
      "all_native_ads",
      null,
      { pause: data.pause, status: targetStatus },
      { reason: data.reason || "Emergency pause", count: totalUpdated }
    );

    return {
      success: true,
      message: `${totalUpdated} native ad feeds ${data.pause ? "paused" : "unpaused"}`,
      data: { updated: totalUpdated },
    } as ApiResponse;
  }
);
