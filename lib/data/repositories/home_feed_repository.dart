import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/utils/constants/firebase_paths.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';

/// Home Feed Repository - Firebase operations for the unified home feed
/// Handles all Firestore reads/writes for the /home_feeds collection
/// and resolves referenced content from /posts, /jobs, etc.
///
/// Golden Rule: home_feeds decides WHAT to show and WHEN, never WHAT the content is.
class HomeFeedRepository extends GetxController {
  static HomeFeedRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== Collection References ====================

  CollectionReference<Map<String, dynamic>> get _feedsRef =>
      _db.collection(FirebasePaths.homeFeeds);

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _db.collection(FirebasePaths.posts);

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      _db.collection(FirebasePaths.microJobs);

  // ==================== FEED QUERY OPERATIONS ====================

  /// Fetch paginated feed items from /home_feeds
  /// Uses compound query: WHERE status == ACTIVE, ORDER BY priority DESC, createdAt DESC
  ///
  /// [limit] Number of items to fetch per page (default: 20)
  /// [lastDocument] Last document snapshot for cursor-based pagination
  Future<List<FeedItemModel>> fetchFeedItems({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      LoggerService.info('📰 Fetching feed items (limit: $limit)');

      Query<Map<String, dynamic>> query = _feedsRef
          .where('status', isEqualTo: FeedStatus.active)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Cursor-based pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final feedItems = snapshot.docs
          .map((doc) => FeedItemModel.fromFirestore(doc))
          .toList();

      LoggerService.info('✅ Fetched ${feedItems.length} feed items');
      return feedItems;
    } catch (e) {
      LoggerService.error('Failed to fetch feed items', e);
      rethrow;
    }
  }

  // ==================== CONTENT RESOLUTION ====================

  /// Resolve a community post by its refId
  /// Fetches the actual post document from /posts/{refId}
  Future<CommunityPostModel?> resolvePost(String postId) async {
    try {
      final doc = await _postsRef.doc(postId).get();
      if (!doc.exists) {
        LoggerService.warning('⚠️ Post not found: $postId');
        return null;
      }
      return CommunityPostModel.fromFirestore(doc);
    } catch (e) {
      LoggerService.error('Failed to resolve post: $postId', e);
      return null;
    }
  }

  /// Resolve a micro job by its refId
  /// Fetches the actual job document from /jobs/{refId}
  Future<MicroJobModel?> resolveJob(String jobId) async {
    try {
      final doc = await _jobsRef.doc(jobId).get();
      if (!doc.exists) {
        LoggerService.warning('⚠️ Job not found: $jobId');
        return null;
      }
      return MicroJobModel.fromFirestore(doc);
    } catch (e) {
      LoggerService.error('Failed to resolve job: $jobId', e);
      return null;
    }
  }

  /// Batch resolve multiple posts at once (efficient)
  /// Returns a map of postId -> CommunityPostModel
  Future<Map<String, CommunityPostModel>> batchResolvePosts(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};

    try {
      final results = <String, CommunityPostModel>{};

      // Firestore IN query supports max 30 items
      final chunks = _chunkList(postIds, 30);

      for (final chunk in chunks) {
        final snapshot = await _postsRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          results[doc.id] = CommunityPostModel.fromFirestore(doc);
        }
      }

      LoggerService.info(
        '✅ Batch resolved ${results.length}/${postIds.length} posts',
      );
      return results;
    } catch (e) {
      LoggerService.error('Failed to batch resolve posts', e);
      return {};
    }
  }

  /// Batch resolve multiple jobs at once (efficient)
  /// Returns a map of jobId -> MicroJobModel
  Future<Map<String, MicroJobModel>> batchResolveJobs(
    List<String> jobIds,
  ) async {
    if (jobIds.isEmpty) return {};

    try {
      final results = <String, MicroJobModel>{};

      final chunks = _chunkList(jobIds, 30);

      for (final chunk in chunks) {
        final snapshot = await _jobsRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          results[doc.id] = MicroJobModel.fromFirestore(doc);
        }
      }

      LoggerService.info(
        '✅ Batch resolved ${results.length}/${jobIds.length} jobs',
      );
      return results;
    } catch (e) {
      LoggerService.error('Failed to batch resolve jobs', e);
      return {};
    }
  }

  // ==================== FEED ITEM CREATION ====================
  // NOTE: Feed items are primarily created by Cloud Functions
  // These methods are here for reference and admin tools

  /// Create a feed item (called by Cloud Functions trigger, NOT client)
  /// This is exposed for testing/admin purposes only
  Future<String> createFeedItem(FeedItemModel feedItem) async {
    try {
      final docRef = await _feedsRef.add(feedItem.toCreateMap());
      LoggerService.info('✅ Feed item created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      LoggerService.error('Failed to create feed item', e);
      rethrow;
    }
  }

  // ==================== FEED STATUS OPERATIONS ====================

  /// Update feed item status (admin/moderation)
  Future<void> updateFeedStatus(String feedId, String newStatus) async {
    try {
      await _feedsRef.doc(feedId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      LoggerService.info('✅ Feed $feedId status updated to $newStatus');
    } catch (e) {
      LoggerService.error('Failed to update feed status', e);
      rethrow;
    }
  }

  // ==================== REAL-TIME LISTENER ====================

  /// Listen to feed changes in real-time
  /// Returns a stream of feed item snapshots
  Stream<List<FeedItemModel>> watchFeedItems({int limit = 20}) {
    return _feedsRef
        .where('status', isEqualTo: FeedStatus.active)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FeedItemModel.fromFirestore(doc))
              .toList(),
        );
  }

  // ==================== UTILITY ====================

  /// Split a list into chunks of the given size
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }
}
