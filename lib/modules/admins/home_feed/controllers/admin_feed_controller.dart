import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';
import 'package:shirah/modules/admins/home_feed/repositories/admin_feed_repository.dart';

/// Admin Feed Controller - State management for Home Feed admin panel
///
/// Manages:
///   - Feed items list with filtering & stats
///   - Status updates (activate/disable/hide/remove)
///   - Priority changes
///   - Native ad creation
///   - Tab-based status filtering
class AdminFeedController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static AdminFeedController get instance => Get.find();

  final AdminFeedRepository _repository = AdminFeedRepository.instance;

  // ==================== State ====================

  /// All feed items (from server, unfiltered by tab)
  final RxList<FeedItemModel> allFeedItems = <FeedItemModel>[].obs;

  /// Currently displayed feed items (filtered)
  final RxList<FeedItemModel> displayedFeedItems = <FeedItemModel>[].obs;

  /// Loading states
  final RxBool isLoading = false.obs;
  final RxBool isActionLoading = false.obs;

  /// Error state
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  /// Filter states
  final RxString selectedStatus = ''.obs; // empty = all
  final RxString selectedType = ''.obs; // empty = all
  final RxInt selectedTabIndex = 0.obs;

  /// Stats
  final RxInt totalItems = 0.obs;
  final RxInt activeItems = 0.obs;
  final RxInt nativeAdItems = 0.obs;
  final RxInt disabledItems = 0.obs;

  /// Tab controller
  late TabController tabController;

  /// Status filter tabs
  final List<String> statusTabs = [
    '', // All
    FeedStatus.active,
    FeedStatus.disabled,
    FeedStatus.hidden,
    FeedStatus.removed,
  ];

  /// Available feed type filters
  final List<String> feedTypeFilters = [
    '', // All
    FeedItemType.communityPost,
    FeedItemType.microJob,
    FeedItemType.nativeAd,
    FeedItemType.sponsored,
    FeedItemType.announcement,
    FeedItemType.reselling,
    FeedItemType.driveOffer,
    FeedItemType.onDemandPost,
    FeedItemType.buySellPost,
    FeedItemType.adsView,
    FeedItemType.suggestedFollowing,
  ];

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: statusTabs.length, vsync: this);
    tabController.addListener(_onTabChanged);
    loadFeedItems();
  }

  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }

  // ==================== Tab Management ====================

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      selectedTabIndex.value = tabController.index;
      selectedStatus.value = statusTabs[tabController.index];
      _applyFilters();
    }
  }

  // ==================== Data Loading ====================

  /// Load all feed items from server
  Future<void> loadFeedItems() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // Fetch all items (no server-side status filter — we filter client-side for tabs)
      final items = await _repository.fetchAdminFeedItems(
        limit: 100,
        type: selectedType.value.isNotEmpty ? selectedType.value : null,
      );

      allFeedItems.assignAll(items);
      _computeStats();
      _applyFilters();

      LoggerService.info('📊 Admin feed loaded: ${items.length} items');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      LoggerService.error('Failed to load admin feed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh feed items
  Future<void> refreshFeedItems() async {
    await loadFeedItems();
  }

  // ==================== Filtering ====================

  /// Filter by feed type
  void filterByType(String type) {
    selectedType.value = type;
    loadFeedItems();
  }

  /// Apply client-side filters (status tab)
  void _applyFilters() {
    if (selectedStatus.value.isEmpty) {
      displayedFeedItems.assignAll(allFeedItems);
    } else {
      displayedFeedItems.assignAll(
        allFeedItems
            .where((item) => item.status == selectedStatus.value)
            .toList(),
      );
    }
  }

  /// Compute dashboard stats
  void _computeStats() {
    totalItems.value = allFeedItems.length;
    activeItems.value = allFeedItems
        .where((item) => item.status == FeedStatus.active)
        .length;
    nativeAdItems.value = allFeedItems
        .where((item) => item.type == FeedItemType.nativeAd)
        .length;
    disabledItems.value = allFeedItems
        .where((item) => item.status == FeedStatus.disabled)
        .length;
  }

  // ==================== Status Operations ====================

  /// Update feed item status
  Future<bool> updateStatus({
    required String feedId,
    required String newStatus,
    String? reason,
  }) async {
    try {
      isActionLoading.value = true;

      await _repository.updateFeedStatus(
        feedId: feedId,
        status: newStatus,
        reason: reason,
      );

      // Update local state
      final index = allFeedItems.indexWhere((item) => item.feedId == feedId);
      if (index != -1) {
        final oldItem = allFeedItems[index];
        allFeedItems[index] = FeedItemModel(
          feedId: oldItem.feedId,
          type: oldItem.type,
          refId: oldItem.refId,
          priority: oldItem.priority,
          status: newStatus,
          visibility: oldItem.visibility,
          createdAt: oldItem.createdAt,
          meta: oldItem.meta,
          rules: oldItem.rules,
        );
        _computeStats();
        _applyFilters();
      }

      LoggerService.info('✅ Feed status updated: $feedId → $newStatus');
      return true;
    } catch (e) {
      LoggerService.error('Failed to update feed status', e);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ==================== Priority Operations ====================

  /// Update feed item priority
  Future<bool> updatePriority({
    required String feedId,
    required int newPriority,
  }) async {
    try {
      isActionLoading.value = true;

      await _repository.updateFeedPriority(
        feedId: feedId,
        priority: newPriority,
      );

      // Update local state
      final index = allFeedItems.indexWhere((item) => item.feedId == feedId);
      if (index != -1) {
        final oldItem = allFeedItems[index];
        allFeedItems[index] = FeedItemModel(
          feedId: oldItem.feedId,
          type: oldItem.type,
          refId: oldItem.refId,
          priority: newPriority,
          status: oldItem.status,
          visibility: oldItem.visibility,
          createdAt: oldItem.createdAt,
          meta: oldItem.meta,
          rules: oldItem.rules,
        );
        _computeStats();
        _applyFilters();
      }

      LoggerService.info('✅ Feed priority updated: $feedId → $newPriority');
      return true;
    } catch (e) {
      LoggerService.error('Failed to update feed priority', e);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ==================== Native Ad Operations ====================

  /// Create a native ad feed item
  Future<bool> createNativeAd({
    required String adUnitId,
    required String platform,
    int? minGap,
    int? maxPerSession,
  }) async {
    try {
      isActionLoading.value = true;

      await _repository.createNativeAd(
        adUnitId: adUnitId,
        platform: platform,
        minGap: minGap,
        maxPerSession: maxPerSession,
      );

      // Reload to get updated list
      await loadFeedItems();

      LoggerService.info('✅ Native ad created successfully');
      return true;
    } catch (e) {
      LoggerService.error('Failed to create native ad', e);
      return false;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ==================== Helpers ====================

  /// Get human-readable feed type label
  String getTypeLabel(String type) {
    switch (type) {
      case FeedItemType.communityPost:
        return 'Community Post';
      case FeedItemType.microJob:
        return 'Micro Job';
      case FeedItemType.nativeAd:
        return 'Native Ad';
      case FeedItemType.sponsored:
        return 'Sponsored';
      case FeedItemType.announcement:
        return 'Announcement';
      case FeedItemType.reselling:
        return 'Product';
      case FeedItemType.driveOffer:
        return 'Drive Offer';
      case FeedItemType.onDemandPost:
        return 'On Demand';
      case FeedItemType.buySellPost:
        return 'Buy & Sell';
      case FeedItemType.adsView:
        return 'Ads View';
      case FeedItemType.suggestedFollowing:
        return 'Suggested';
      default:
        return type;
    }
  }

  /// Get feed type icon
  IconData getTypeIcon(String type) {
    switch (type) {
      case FeedItemType.communityPost:
        return Icons.article_outlined;
      case FeedItemType.microJob:
        return Icons.work_outline;
      case FeedItemType.nativeAd:
        return Icons.ad_units_outlined;
      case FeedItemType.sponsored:
        return Icons.campaign_outlined;
      case FeedItemType.announcement:
        return Icons.announcement_outlined;
      case FeedItemType.reselling:
        return Icons.store_outlined;
      case FeedItemType.driveOffer:
        return Icons.local_offer_outlined;
      case FeedItemType.onDemandPost:
        return Icons.search_outlined;
      case FeedItemType.buySellPost:
        return Icons.shopping_cart_outlined;
      case FeedItemType.adsView:
        return Icons.play_circle_outline;
      case FeedItemType.suggestedFollowing:
        return Icons.person_add_outlined;
      default:
        return Icons.rss_feed_outlined;
    }
  }

  /// Get feed type color
  Color getTypeColor(String type) {
    switch (type) {
      case FeedItemType.communityPost:
        return const Color(0xFF4B68FF);
      case FeedItemType.microJob:
        return const Color(0xFF388E3C);
      case FeedItemType.nativeAd:
        return const Color(0xFFF57C00);
      case FeedItemType.sponsored:
        return const Color(0xFF9C27B0);
      case FeedItemType.announcement:
        return const Color(0xFF1976D2);
      case FeedItemType.reselling:
        return const Color(0xFF00897B);
      case FeedItemType.driveOffer:
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Get status color
  Color getStatusColor(String status) {
    switch (status) {
      case FeedStatus.active:
        return const Color(0xFF388E3C);
      case FeedStatus.disabled:
        return const Color(0xFFF57C00);
      case FeedStatus.hidden:
        return const Color(0xFF757575);
      case FeedStatus.removed:
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Get priority label
  String getPriorityLabel(int priority) {
    if (priority >= FeedPriority.critical) return 'Critical';
    if (priority >= FeedPriority.important) return 'Important';
    if (priority >= FeedPriority.normal) return 'Normal';
    return 'Low';
  }

  /// Get priority color
  Color getPriorityColor(int priority) {
    if (priority >= FeedPriority.critical) return const Color(0xFFD32F2F);
    if (priority >= FeedPriority.important) return const Color(0xFFF57C00);
    if (priority >= FeedPriority.normal) return const Color(0xFF4B68FF);
    return const Color(0xFF757575);
  }
}
