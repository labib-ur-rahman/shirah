/**
 * SHIRAH Cloud Functions - Community Module
 * Handles community posts, reactions, comments, and replies
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  COLLECTIONS,
  POST_STATUS,
  REACTION_TYPES,
  REGION,
  USER_ROLES,
} from "../../config/constants";
import {
  CommunityPost,
  PostReaction,
  PostComment,
  PostReply,
  PostAuthor,
  PostReactionSummary,
  CreatePostRequest,
  ToggleReactionRequest,
  AddCommentRequest,
  AddReplyRequest,
  ModeratePostRequest,
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
 * Get author info from user document
 */
async function getAuthorFromUser(uid: string): Promise<PostAuthor> {
  const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
  if (!userDoc.exists) {
    return { uid, name: "Unknown User", photo: "" };
  }
  const userData = userDoc.data() as UserDocument;
  const fullName =
    `${userData.identity.firstName} ${userData.identity.lastName}`.trim();
  return {
    uid,
    name: fullName || "User",
    photo: userData.identity.photoURL || "",
  };
}

/**
 * Default empty reaction summary
 */
function emptyReactionSummary(): PostReactionSummary {
  return {
    total: 0,
    like: 0,
    love: 0,
    insightful: 0,
    support: 0,
    inspiring: 0,
  };
}

/**
 * Validate reaction type
 */
function isValidReactionType(type: string): boolean {
  return Object.values(REACTION_TYPES).includes(type as any);
}

// ============================================
// CREATE POST
// ============================================

/**
 * Create a new community post
 * Authenticated users only
 */
export const createCommunityPost = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<CreatePostRequest>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { text, images, privacy } = request.data;

    if (!text && (!images || images.length === 0)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post must have text or at least one image"
      );
    }

    if (text && text.length > 5000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post text cannot exceed 5000 characters"
      );
    }

    if (images && images.length > 10) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 10 images per post"
      );
    }

    const validPrivacy = ["public", "friends", "only_me"];
    if (privacy && !validPrivacy.includes(privacy)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid privacy setting"
      );
    }

    const author = await getAuthorFromUser(uid);

    const postRef = db.collection(COLLECTIONS.POSTS).doc();
    const now = serverTimestamp();

    const post: Partial<CommunityPost> = {
      postId: postRef.id,
      author,
      content: {
        text: text || "",
        images: images || [],
      },
      privacy: privacy || "public",
      status: POST_STATUS.APPROVED, // Auto-approve for now
      reactionSummary: emptyReactionSummary(),
      commentCount: 0,
      shareCount: 0,
      isDeleted: false,
      createdAt: now as any,
      updatedAt: now as any,
    };

    await postRef.set(post);

    functions.logger.info(`📝 Post created: ${postRef.id} by ${uid}`);

    const response: ApiResponse = {
      success: true,
      message: "Post created successfully",
      data: { postId: postRef.id },
    };
    return response;
  }
);

// ============================================
// TOGGLE REACTION
// ============================================

/**
 * Toggle a reaction on a post (add, update, or remove)
 * One user = one reaction per post
 */
export const togglePostReaction = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<ToggleReactionRequest>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { postId, reactionType } = request.data;

    if (!postId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post ID is required"
      );
    }

    if (!isValidReactionType(reactionType)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid reaction type"
      );
    }

    const postRef = db.collection(COLLECTIONS.POSTS).doc(postId);
    const reactionRef = postRef
      .collection(COLLECTIONS.REACTIONS)
      .doc(uid);

    await db.runTransaction(async (transaction) => {
      const postDoc = await transaction.get(postRef);
      if (!postDoc.exists || postDoc.data()?.isDeleted) {
        throw new functions.https.HttpsError("not-found", "Post not found");
      }

      const existingReaction = await transaction.get(reactionRef);
      const postData = postDoc.data() as CommunityPost;
      const summary = postData.reactionSummary || emptyReactionSummary();

      if (existingReaction.exists) {
        const oldType = existingReaction.data()?.reaction as string;

        if (oldType === reactionType) {
          // Same reaction → remove it
          transaction.delete(reactionRef);
          (summary as any)[oldType] = Math.max(0, ((summary as any)[oldType] || 0) - 1);
          summary.total = Math.max(0, summary.total - 1);
        } else {
          // Different reaction → update
          transaction.update(reactionRef, {
            reaction: reactionType,
            createdAt: serverTimestamp(),
          });
          (summary as any)[oldType] = Math.max(0, ((summary as any)[oldType] || 0) - 1);
          (summary as any)[reactionType] = ((summary as any)[reactionType] || 0) + 1;
        }
      } else {
        // New reaction → create
        // Get user name
        const userDoc = await db
          .collection(COLLECTIONS.USERS)
          .doc(uid)
          .get();
        const userData = userDoc.data() as UserDocument | undefined;
        const userName = userData
          ? `${userData.identity.firstName} ${userData.identity.lastName}`.trim()
          : null;

        const reaction: PostReaction = {
          userId: uid,
          postId,
          reaction: reactionType as any,
          userName,
          createdAt: serverTimestamp() as any,
        };
        transaction.set(reactionRef, reaction);
        (summary as any)[reactionType] = ((summary as any)[reactionType] || 0) + 1;
        summary.total = (summary.total || 0) + 1;
      }

      transaction.update(postRef, {
        reactionSummary: summary,
        updatedAt: serverTimestamp(),
      });
    });

    functions.logger.info(
      `👍 Reaction toggled on post ${postId} by ${uid}: ${reactionType}`
    );

    const response: ApiResponse = {
      success: true,
      message: "Reaction updated",
    };
    return response;
  }
);

// ============================================
// ADD COMMENT
// ============================================

/**
 * Add a comment to a post
 */
export const addPostComment = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<AddCommentRequest>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { postId, text } = request.data;

    if (!postId || !text || text.trim().length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post ID and comment text are required"
      );
    }

    if (text.length > 2000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Comment cannot exceed 2000 characters"
      );
    }

    // Verify post exists
    const postRef = db.collection(COLLECTIONS.POSTS).doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists || postDoc.data()?.isDeleted) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const author = await getAuthorFromUser(uid);

    const commentRef = db.collection(COLLECTIONS.COMMENTS).doc();
    const now = serverTimestamp();

    const comment: Partial<PostComment> = {
      commentId: commentRef.id,
      postId,
      author,
      text: text.trim(),
      reactionSummary: emptyReactionSummary(),
      replyCount: 0,
      isDeleted: false,
      createdAt: now as any,
    };

    const batch = db.batch();
    batch.set(commentRef, comment);
    batch.update(postRef, {
      commentCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });
    await batch.commit();

    functions.logger.info(
      `💬 Comment added to post ${postId} by ${uid}: ${commentRef.id}`
    );

    const response: ApiResponse = {
      success: true,
      message: "Comment added",
      data: { commentId: commentRef.id },
    };
    return response;
  }
);

// ============================================
// ADD REPLY
// ============================================

/**
 * Add a reply to a comment
 */
export const addPostReply = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<AddReplyRequest>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { postId, commentId, text } = request.data;

    if (!postId || !commentId || !text || text.trim().length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post ID, comment ID, and reply text are required"
      );
    }

    if (text.length > 2000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Reply cannot exceed 2000 characters"
      );
    }

    // Verify comment exists
    const commentRef = db.collection(COLLECTIONS.COMMENTS).doc(commentId);
    const commentDoc = await commentRef.get();
    if (!commentDoc.exists || commentDoc.data()?.isDeleted) {
      throw new functions.https.HttpsError("not-found", "Comment not found");
    }

    const author = await getAuthorFromUser(uid);

    const replyRef = db.collection(COLLECTIONS.REPLIES).doc();
    const now = serverTimestamp();

    const reply: Partial<PostReply> = {
      replyId: replyRef.id,
      postId,
      commentId,
      author,
      text: text.trim(),
      isDeleted: false,
      createdAt: now as any,
    };

    const batch = db.batch();
    batch.set(replyRef, reply);
    batch.update(commentRef, {
      replyCount: admin.firestore.FieldValue.increment(1),
    });
    await batch.commit();

    functions.logger.info(
      `↩️ Reply added to comment ${commentId} by ${uid}: ${replyRef.id}`
    );

    const response: ApiResponse = {
      success: true,
      message: "Reply added",
      data: { replyId: replyRef.id },
    };
    return response;
  }
);

// ============================================
// MODERATE POST (Admin/Moderator)
// ============================================

/**
 * Approve or reject a community post
 * Only admins and moderators can call this
 */
export const moderatePost = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<ModeratePostRequest>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { postId, action, reason } = request.data;

    // Verify admin/moderator role
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User not found"
      );
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
        "Only admins and moderators can moderate posts"
      );
    }

    if (!postId || !action) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post ID and action are required"
      );
    }

    if (!["approve", "reject"].includes(action)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Action must be 'approve' or 'reject'"
      );
    }

    const postRef = db.collection(COLLECTIONS.POSTS).doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const newStatus =
      action === "approve" ? POST_STATUS.APPROVED : POST_STATUS.REJECTED;

    await postRef.update({
      status: newStatus,
      updatedAt: serverTimestamp(),
      ...(reason && { moderationNote: reason }),
      moderatedBy: uid,
      moderatedAt: serverTimestamp(),
    });

    functions.logger.info(
      `🛡️ Post ${postId} ${action}d by moderator ${uid}`
    );

    const response: ApiResponse = {
      success: true,
      message: `Post ${action}d successfully`,
    };
    return response;
  });

// ============================================
// DELETE POST (Soft Delete)
// ============================================

/**
 * 
);

// ============================================
// DELETE POST (Soft Delete)
// ============================================

/**
 * Soft delete a post (owner or admin)
 */
export const deleteCommunityPost = functions.https.onCall(
  { region: REGION },
  async (request: functions.https.CallableRequest<{ postId: string }>): Promise<ApiResponse> => {
    const uid = validateAuthenticated(request.auth);
    const { postId } = request.data;

    if (!postId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Post ID is required"
      );
    }

    const postRef = db.collection(COLLECTIONS.POSTS).doc(postId);
    const postDoc = await postRef.get();
    if (!postDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const postData = postDoc.data() as CommunityPost;

    // Check permission: author or admin
    if (postData.author.uid !== uid) {
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
      const userData = userDoc.data() as UserDocument;
      const adminRoles = [
        USER_ROLES.SUPER_ADMIN,
        USER_ROLES.ADMIN,
        USER_ROLES.MODERATOR,
      ];
      if (!adminRoles.includes(userData.role as any)) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You can only delete your own posts"
        );
      }
    }

    await postRef.update({
      isDeleted: true,
      updatedAt: serverTimestamp(),
    });

    functions.logger.info(`🗑️ Post ${postId} soft-deleted by ${uid}`);

    const response: ApiResponse = {
      success: true,
      message: "Post deleted",
    };
    return response;
  });
