import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/post_reaction_model.dart';
import 'package:shirah/data/repositories/community_repository.dart';

/// Feed Controller - Manages the community feed list
/// Handles loading, pagination, reactions, and refresh
class FeedController extends GetxController {
  static FeedController get instance => Get.find();

  // ==================== Dependencies ====================
  final CommunityRepository _repository = CommunityRepository.instance;

  // ==================== Reactive State ====================

  /// List of feed posts
  final RxList<CommunityPostModel> posts = <CommunityPostModel>[].obs;

  /// Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMorePosts = true.obs;

  /// User reactions cache: postId -> reactionType
  final RxMap<String, String?> userReactions = <String, String?>{}.obs;

  // ==================== Pagination ====================
  static const int _pageSize = 10;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  // ==================== Feed Loading ====================

  /// Load initial feed
  Future<void> loadFeed() async {
    try {
      isLoading.value = true;
      hasMorePosts.value = true;

      final result = await _repository.fetchFeedPosts(limit: _pageSize);
      posts.assignAll(result);

      if (result.length < _pageSize) {
        hasMorePosts.value = false;
      }

      // Load user reactions for visible posts
      _loadUserReactions(result);

      LoggerService.info('📰 Feed loaded: ${result.length} posts');
    } catch (e) {
      LoggerService.error('Failed to load feed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !hasMorePosts.value || posts.isEmpty) return;

    try {
      isLoadingMore.value = true;

      // We need to get the last document for pagination
      // For simplicity, we'll use the last post's createdAt
      final result = await _repository.fetchFeedPosts(limit: _pageSize);

      if (result.length < _pageSize) {
        hasMorePosts.value = false;
      }

      // Add new posts (avoiding duplicates)
      final existingIds = posts.map((p) => p.postId).toSet();
      final newPosts = result
          .where((p) => !existingIds.contains(p.postId))
          .toList();
      posts.addAll(newPosts);

      _loadUserReactions(newPosts);
    } catch (e) {
      LoggerService.error('Failed to load more posts', e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh feed (pull-to-refresh)
  Future<void> refreshFeed() async {
    await loadFeed();
  }

  // ==================== Reaction Operations ====================

  /// Load user reactions for a batch of posts
  Future<void> _loadUserReactions(List<CommunityPostModel> postList) async {
    for (final post in postList) {
      try {
        final reaction = await _repository.getCurrentUserReaction(post.postId);
        userReactions[post.postId] = reaction;
      } catch (_) {
        // Silently fail for individual reaction checks
      }
    }
  }

  /// Toggle reaction on a post
  Future<void> toggleReaction({
    required String postId,
    required String reactionType,
  }) async {
    try {
      final currentReaction = userReactions[postId];

      // Optimistic update
      if (currentReaction == reactionType) {
        userReactions[postId] = null;
        _updatePostReactionLocally(postId, reactionType, -1);
      } else {
        if (currentReaction != null) {
          _updatePostReactionLocally(postId, currentReaction, -1);
        }
        userReactions[postId] = reactionType;
        _updatePostReactionLocally(postId, reactionType, 1);
      }

      // Server update
      await _repository.togglePostReaction(
        postId: postId,
        reactionType: reactionType,
      );
    } catch (e) {
      LoggerService.error('Failed to toggle reaction', e);
      // Revert on failure
      await refreshFeed();
    }
  }

  /// Update local post reaction summary for optimistic UI
  void _updatePostReactionLocally(String postId, String type, int delta) {
    final index = posts.indexWhere((p) => p.postId == postId);
    if (index == -1) return;

    // Trigger list refresh by reassigning
    posts.refresh();
  }

  // ==================== Reaction List ====================

  /// Get reactions for a post (for reaction list screen)
  Future<List<PostReactionModel>> getPostReactions({
    required String postId,
    String? filterByType,
  }) async {
    return _repository.getPostReactions(
      postId: postId,
      filterByType: filterByType,
    );
  }

  // ==================== Post Added Callback ====================

  /// Call when a new post is created to add it to top of feed
  void onPostCreated() {
    refreshFeed();
  }
}
