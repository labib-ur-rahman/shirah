import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/community/comment_model.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/reply_model.dart';
import 'package:shirah/data/repositories/community_repository.dart';
import 'package:shirah/features/community/controllers/feed_controller.dart';

/// Post Detail Controller - Manages post detail view with comments & replies
class PostDetailController extends GetxController {
  static PostDetailController get instance => Get.find();

  // ==================== Dependencies ====================
  final CommunityRepository _repository = CommunityRepository.instance;

  // ==================== Text Controllers ====================
  final TextEditingController commentController = TextEditingController();
  final TextEditingController replyController = TextEditingController();

  // ==================== Reactive State ====================

  /// The post being viewed
  final Rx<CommunityPostModel?> post = Rx<CommunityPostModel?>(null);

  /// Comments list
  final RxList<CommentModel> comments = <CommentModel>[].obs;

  /// Replies cache: commentId -> list of replies
  final RxMap<String, List<ReplyModel>> repliesCache =
      <String, List<ReplyModel>>{}.obs;

  /// Loading states
  final RxBool isLoadingPost = false.obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool isSubmittingComment = false.obs;
  final RxBool isSubmittingReply = false.obs;

  /// Active reply target (null = adding comment, non-null = replying to comment)
  final Rx<String?> replyingToCommentId = Rx<String?>(null);
  final Rx<String?> replyingToName = Rx<String?>(null);

  /// Expanded replies: commentIds whose replies are visible
  final RxSet<String> expandedReplies = <String>{}.obs;

  // ==================== Initialization ====================

  /// Load post and comments
  Future<void> loadPost(String postId) async {
    try {
      isLoadingPost.value = true;
      post.value = await _repository.getPost(postId);
      isLoadingPost.value = false;

      // Load comments in parallel
      await loadComments(postId);
    } catch (e) {
      isLoadingPost.value = false;
      LoggerService.error('Failed to load post detail', e);
    }
  }

  /// Load comments for the post
  Future<void> loadComments(String postId) async {
    try {
      isLoadingComments.value = true;
      final result = await _repository.fetchComments(postId: postId);
      comments.assignAll(result);
    } catch (e) {
      LoggerService.error('Failed to load comments', e);
    } finally {
      isLoadingComments.value = false;
    }
  }

  // ==================== Comment Operations ====================

  /// Submit a new comment
  Future<void> submitComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty || post.value == null) return;

    try {
      isSubmittingComment.value = true;

      await _repository.addComment(postId: post.value!.postId, text: text);

      commentController.clear();

      // Refresh comments and post (for updated commentCount)
      await loadComments(post.value!.postId);
      post.value = await _repository.getPost(post.value!.postId);
      if (post.value != null) {
        FeedController.instance.upsertPost(post.value!);
      }

      LoggerService.info('💬 Comment submitted');
    } catch (e) {
      LoggerService.error('Failed to submit comment', e);
      Get.snackbar('Error', 'Failed to post comment');
    } finally {
      isSubmittingComment.value = false;
    }
  }

  // ==================== Reply Operations ====================

  /// Start replying to a comment
  void startReply(String commentId, String authorName) {
    replyingToCommentId.value = commentId;
    replyingToName.value = authorName;
    replyController.clear();
  }

  /// Cancel reply mode
  void cancelReply() {
    replyingToCommentId.value = null;
    replyingToName.value = null;
    replyController.clear();
  }

  /// Submit a reply
  Future<void> submitReply() async {
    final text = replyController.text.trim();
    final commentId = replyingToCommentId.value;
    if (text.isEmpty || commentId == null || post.value == null) return;

    try {
      isSubmittingReply.value = true;

      await _repository.addReply(
        postId: post.value!.postId,
        commentId: commentId,
        text: text,
      );

      replyController.clear();
      cancelReply();

      // Refresh replies for this comment
      await loadReplies(commentId);

      // Refresh comments to update reply count
      await loadComments(post.value!.postId);

      LoggerService.info('↩️ Reply submitted');
    } catch (e) {
      LoggerService.error('Failed to submit reply', e);
      Get.snackbar('Error', 'Failed to post reply');
    } finally {
      isSubmittingReply.value = false;
    }
  }

  /// Load replies for a comment
  Future<void> loadReplies(String commentId) async {
    try {
      final result = await _repository.fetchReplies(commentId: commentId);
      repliesCache[commentId] = result;
      repliesCache.refresh();
      expandedReplies.add(commentId);
      expandedReplies.refresh();
    } catch (e) {
      LoggerService.error('Failed to load replies', e);
    }
  }

  /// Toggle replies visibility
  void toggleReplies(String commentId) {
    if (expandedReplies.contains(commentId)) {
      expandedReplies.remove(commentId);
      expandedReplies.refresh();
    } else {
      if (!repliesCache.containsKey(commentId)) {
        loadReplies(commentId);
      } else {
        expandedReplies.add(commentId);
        expandedReplies.refresh();
      }
    }
  }

  // ==================== Lifecycle ====================

  @override
  void onClose() {
    commentController.dispose();
    replyController.dispose();
    super.onClose();
  }
}
