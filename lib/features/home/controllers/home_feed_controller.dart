import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/data/repositories/home_feed_repository.dart';

/// Home Feed Controller - Manages the unified home feed state & logic
///
/// Responsibilities:
/// - Fetch paginated feed items from /home_feeds
/// - Resolve referenced content (posts, jobs) progressively
/// - Apply ad gap algorithm (Flutter-side, per documentation v3)
/// - Manage loading, refresh, and error states
class HomeFeedController extends GetxController {
  static HomeFeedController get instance => Get.find();

  // ==================== Dependencies ====================
  final HomeFeedRepository _repository = HomeFeedRepository.instance;

  // ==================== Scroll ====================
  final ScrollController scrollController = ScrollController();

  // ==================== Reactive State ====================

  /// Raw feed items from Firestore (before ad gap filtering)
  final RxList<FeedItemModel> _rawFeedItems = <FeedItemModel>[].obs;

  /// Processed feed items (after ad gap algorithm)
  final RxList<FeedItemModel> feedItems = <FeedItemModel>[].obs;

  /// Resolved community posts cache: refId → CommunityPostModel
  final RxMap<String, CommunityPostModel> resolvedPosts =
      <String, CommunityPostModel>{}.obs;

  /// Resolved micro jobs cache: refId → MicroJobModel
  final RxMap<String, MicroJobModel> resolvedJobs =
      <String, MicroJobModel>{}.obs;

  /// Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool hasError = false.obs;

  // ==================== Pagination ====================
  static const int _pageSize = 20;

  // ==================== Ad Gap Algorithm State ====================
  int _shownAds = 0;

  /// Number of ads shown in current session (for debugging/analytics)
  int get shownAdsCount => _shownAds;
  static const int _defaultMinGap = 6;
  static const int _defaultMaxPerSession = 3;

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // ==================== Feed Loading ====================

  /// Load initial feed (first page)
  Future<void> loadFeed() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      hasMore.value = true;
      _shownAds = 0;

      final items = await _repository.fetchFeedItems(limit: _pageSize);
      _rawFeedItems.assignAll(items);

      // Apply ad gap algorithm
      _applyAdGapAlgorithm();

      // Resolve content progressively (don't block UI)
      _resolveContent(items);

      if (items.length < _pageSize) {
        hasMore.value = false;
      }

      LoggerService.info(
        '📰 Home feed loaded: ${items.length} raw → ${feedItems.length} visible',
      );
    } catch (e) {
      hasError.value = true;
      LoggerService.error('Failed to load home feed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more feed items (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value || _rawFeedItems.isEmpty) return;

    try {
      isLoadingMore.value = true;

      final lastDoc = _rawFeedItems.last.documentSnapshot;
      final items = await _repository.fetchFeedItems(
        limit: _pageSize,
        lastDocument: lastDoc,
      );

      if (items.isEmpty || items.length < _pageSize) {
        hasMore.value = false;
      }

      // Append new items (avoid duplicates)
      final existingIds = _rawFeedItems.map((e) => e.feedId).toSet();
      final newItems = items
          .where((item) => !existingIds.contains(item.feedId))
          .toList();
      _rawFeedItems.addAll(newItems);

      // Re-apply ad gap algorithm with full list
      _applyAdGapAlgorithm();

      // Resolve new content progressively
      _resolveContent(newItems);
    } catch (e) {
      LoggerService.error('Failed to load more feed items', e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Refresh feed (pull-to-refresh)
  Future<void> refreshFeed() async {
    _shownAds = 0;
    resolvedPosts.clear();
    resolvedJobs.clear();
    await loadFeed();
  }

  Future<void> scrollToTopAndRefresh() async {
    if (scrollController.hasClients) {
      await scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    await refreshFeed();
  }

  // ==================== Ad Gap Algorithm ====================
  // Per documentation v3 section 12:
  // shownAds = 0, itemsSinceLastAd = ∞
  // for item in feed:
  //   if item.type == NATIVE_AD:
  //     if shownAds >= maxPerSession → SKIP
  //     if itemsSinceLastAd < minGap → SKIP
  //     SHOW AD; shownAds++; itemsSinceLastAd = 0
  //   else:
  //     SHOW ITEM; itemsSinceLastAd++

  void _applyAdGapAlgorithm() {
    final processed = <FeedItemModel>[];
    int shownAds = 0;
    int itemsSinceLastAd = 999; // ∞

    for (final item in _rawFeedItems) {
      if (item.type == FeedItemType.nativeAd) {
        final rules = item.rules ?? const FeedRulesModel();
        final minGap = rules.minGap > 0 ? rules.minGap : _defaultMinGap;
        final maxPerSession = rules.maxPerSession > 0
            ? rules.maxPerSession
            : _defaultMaxPerSession;

        // Check emergency pause
        if (item.meta.emergencyPause) continue;

        // Check max per session
        if (shownAds >= maxPerSession) continue;

        // Check minimum gap
        if (itemsSinceLastAd < minGap) continue;

        // Show ad
        processed.add(item);
        shownAds++;
        itemsSinceLastAd = 0;
      } else {
        processed.add(item);
        itemsSinceLastAd++;
      }
    }

    _shownAds = shownAds;
    feedItems.assignAll(processed);
  }

  // ==================== Content Resolution ====================
  // Progressive loading: Don't block UI for content resolution
  // Each item type resolves its own content independently

  void _resolveContent(List<FeedItemModel> items) {
    // Collect refIds by type
    final postIds = <String>[];
    final jobIds = <String>[];

    for (final item in items) {
      if (item.refId == null || item.refId!.isEmpty) continue;

      switch (item.type) {
        case FeedItemType.communityPost:
          if (!resolvedPosts.containsKey(item.refId)) {
            postIds.add(item.refId!);
          }
          break;
        case FeedItemType.microJob:
          if (!resolvedJobs.containsKey(item.refId)) {
            jobIds.add(item.refId!);
          }
          break;
      }
    }

    // Batch resolve in parallel (non-blocking)
    if (postIds.isNotEmpty) {
      _batchResolvePosts(postIds);
    }
    if (jobIds.isNotEmpty) {
      _batchResolveJobs(jobIds);
    }
  }

  Future<void> _batchResolvePosts(List<String> postIds) async {
    try {
      final results = await _repository.batchResolvePosts(postIds);
      resolvedPosts.addAll(results);
      LoggerService.info('📄 Resolved ${results.length} posts');
    } catch (e) {
      LoggerService.error('Failed to batch resolve posts', e);
    }
  }

  Future<void> _batchResolveJobs(List<String> jobIds) async {
    try {
      final results = await _repository.batchResolveJobs(jobIds);
      resolvedJobs.addAll(results);
      LoggerService.info('💼 Resolved ${results.length} jobs');
    } catch (e) {
      LoggerService.error('Failed to batch resolve jobs', e);
    }
  }

  // ==================== Content Getters ====================

  /// Get resolved post for a feed item
  CommunityPostModel? getPost(String? refId) {
    if (refId == null) return null;
    return resolvedPosts[refId];
  }

  /// Get resolved job for a feed item
  MicroJobModel? getJob(String? refId) {
    if (refId == null) return null;
    return resolvedJobs[refId];
  }

  /// Check if content is resolved for a feed item
  bool isContentResolved(FeedItemModel item) {
    if (item.refId == null) return true; // Ads don't need content

    switch (item.type) {
      case FeedItemType.communityPost:
        return resolvedPosts.containsKey(item.refId);
      case FeedItemType.microJob:
        return resolvedJobs.containsKey(item.refId);
      default:
        return true;
    }
  }
}
