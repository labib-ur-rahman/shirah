import 'package:get/get.dart';
import 'package:shirah/core/services/cloud_functions_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';

/// Admin Feed Repository - Cloud Functions operations for feed management
///
/// All admin feed operations go through Cloud Functions (callable).
/// This ensures proper RBAC enforcement server-side.
///
/// Callable Functions Used:
///   - getAdminFeedItems: Paginated feed list with filters
///   - createNativeAdFeed: Create native ad feed item
///   - updateFeedItemStatus: Enable/Disable/Remove feed items
///   - updateFeedItemPriority: Change feed item priority level
class AdminFeedRepository extends GetxController {
  static AdminFeedRepository get instance => Get.find();

  final CloudFunctionsService _functions = CloudFunctionsService.instance;

  // ==================== ADMIN FEED QUERIES ====================

  /// Fetch admin feed items with optional filters
  /// Server-side RBAC: Requires ADMIN, SUPER_ADMIN, or MODERATOR role
  ///
  /// [limit] Max items to return (default: 50)
  /// [status] Filter by feed status (ACTIVE, DISABLED, HIDDEN, REMOVED)
  /// [type] Filter by feed type (COMMUNITY_POST, MICRO_JOB, NATIVE_AD, etc.)
  Future<List<FeedItemModel>> fetchAdminFeedItems({
    int? limit,
    String? status,
    String? type,
  }) async {
    try {
      LoggerService.info(
        '📊 Fetching admin feed items (status: $status, type: $type)',
      );

      final result = await _functions.getAdminFeedItems(
        limit: limit,
        status: status,
        type: type,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to fetch feed items');
      }

      final feedsData = result['data']?['feeds'] as List<dynamic>? ?? [];
      final feedItems = feedsData.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return FeedItemModel.fromMap(map);
      }).toList();

      LoggerService.info('✅ Admin feed items loaded: ${feedItems.length}');
      return feedItems;
    } catch (e) {
      LoggerService.error('Failed to fetch admin feed items', e);
      rethrow;
    }
  }

  // ==================== NATIVE AD OPERATIONS ====================

  /// Create a native ad feed item
  /// Server-side RBAC: Requires ADMIN or SUPER_ADMIN role
  Future<String> createNativeAd({
    required String adUnitId,
    required String platform,
    int? minGap,
    int? maxPerSession,
  }) async {
    try {
      LoggerService.info(
        '📊 Creating native ad feed item (platform: $platform)',
      );

      final result = await _functions.createNativeAdFeed(
        adUnitId: adUnitId,
        platform: platform,
        minGap: minGap,
        maxPerSession: maxPerSession,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to create native ad');
      }

      final feedId = result['data']?['feedId'] as String? ?? '';
      LoggerService.info('✅ Native ad created: $feedId');
      return feedId;
    } catch (e) {
      LoggerService.error('Failed to create native ad', e);
      rethrow;
    }
  }

  // ==================== STATUS OPERATIONS ====================

  /// Update feed item status (enable/disable/remove/hide)
  /// Server-side RBAC: Requires ADMIN, SUPER_ADMIN, or MODERATOR role
  Future<void> updateFeedStatus({
    required String feedId,
    required String status,
    String? reason,
  }) async {
    try {
      LoggerService.info('📊 Updating feed status: $feedId → $status');

      final result = await _functions.updateFeedItemStatus(
        feedId: feedId,
        status: status,
        reason: reason,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to update feed status');
      }

      LoggerService.info('✅ Feed status updated: $feedId → $status');
    } catch (e) {
      LoggerService.error('Failed to update feed status', e);
      rethrow;
    }
  }

  // ==================== PRIORITY OPERATIONS ====================

  /// Update feed item priority level
  /// Server-side RBAC: Requires ADMIN or SUPER_ADMIN role
  Future<void> updateFeedPriority({
    required String feedId,
    required int priority,
  }) async {
    try {
      LoggerService.info('📊 Updating feed priority: $feedId → $priority');

      final result = await _functions.updateFeedItemPriority(
        feedId: feedId,
        priority: priority,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to update feed priority');
      }

      LoggerService.info('✅ Feed priority updated: $feedId → $priority');
    } catch (e) {
      LoggerService.error('Failed to update feed priority', e);
      rethrow;
    }
  }
}
