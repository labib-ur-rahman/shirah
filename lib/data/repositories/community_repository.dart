import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/community/comment_model.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/post_author_model.dart';
import 'package:shirah/data/models/community/post_reaction_model.dart';
import 'package:shirah/data/models/community/reply_model.dart';

/// Community Repository - Firebase operations for community posts
/// All Firestore reads and writes for the community feature
/// Following flat collection structure from documentation
class CommunityRepository extends GetxController {
  static CommunityRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== Collection References ====================

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _db.collection('posts');

  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _db.collection('comments');

  CollectionReference<Map<String, dynamic>> get _repliesRef =>
      _db.collection('replies');

  // ==================== Current User ====================

  String get _currentUid => _auth.currentUser?.uid ?? '';

  PostAuthorModel get currentAuthor {
    final user = _auth.currentUser;
    return PostAuthorModel(
      uid: user?.uid ?? '',
      name: user?.displayName ?? 'User',
      photo: user?.photoURL ?? '',
    );
  }

  // ==================== POST OPERATIONS ====================

  /// Create a new community post
  Future<String> createPost({
    required String text,
    required String privacy,
    File? imageFile,
  }) async {
    try {
      LoggerService.info('📝 Creating community post...');

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadPostImage(imageFile);
      }

      // Build post data
      final postData = {
        'author': currentAuthor.toMap(),
        'content': {
          'text': text,
          'images': imageUrl != null ? [imageUrl] : [],
        },
        'privacy': privacy,
        'status': PostStatus.approved, // Auto-approve for now
        'reactionSummary': {
          'total': 0,
          'like': 0,
          'love': 0,
          'insightful': 0,
          'support': 0,
          'inspiring': 0,
        },
        'commentCount': 0,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _postsRef.add(postData);
      LoggerService.info('✅ Post created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      LoggerService.error('Failed to create post', e);
      rethrow;
    }
  }

  /// Upload post image to Firebase Storage
  Future<String> _uploadPostImage(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'posts/$_currentUid/$timestamp.jpg';
      final ref = _storage.ref().child(path);

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      LoggerService.error('Failed to upload post image', e);
      rethrow;
    }
  }

  // ==================== FEED OPERATIONS ====================

  /// Fetch community posts feed with pagination
  /// Returns posts ordered by createdAt DESC
  Future<List<CommunityPostModel>> fetchFeedPosts({
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _postsRef
          .where('isDeleted', isEqualTo: false)
          .where('status', isEqualTo: PostStatus.approved)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch feed posts', e);
      rethrow;
    }
  }

  /// Get a single post by ID
  Future<CommunityPostModel?> getPost(String postId) async {
    try {
      final doc = await _postsRef.doc(postId).get();
      if (!doc.exists) return null;
      return CommunityPostModel.fromFirestore(doc);
    } catch (e) {
      LoggerService.error('Failed to get post: $postId', e);
      rethrow;
    }
  }

  /// Delete a post (soft delete)
  Future<void> deletePost(String postId) async {
    try {
      await _postsRef.doc(postId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _currentUid,
      });
      LoggerService.info('🗑️ Post soft-deleted: $postId');
    } catch (e) {
      LoggerService.error('Failed to delete post', e);
      rethrow;
    }
  }

  // ==================== REACTION OPERATIONS ====================

  /// Toggle reaction on a post
  /// If same reaction exists, remove it. If different, update it.
  Future<void> togglePostReaction({
    required String postId,
    required String reactionType,
  }) async {
    try {
      final reactionRef = _postsRef
          .doc(postId)
          .collection('reactions')
          .doc(_currentUid);
      final existing = await reactionRef.get();

      if (existing.exists) {
        final currentReaction = existing.data()?['reaction'] as String?;
        if (currentReaction == reactionType) {
          // Same reaction → remove it
          await reactionRef.delete();
          await _updateReactionSummary(postId, reactionType, -1);
          LoggerService.info('❌ Reaction removed from $postId');
        } else {
          // Different reaction → update
          await reactionRef.set({
            'reaction': reactionType,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await _updateReactionSummary(postId, currentReaction!, -1);
          await _updateReactionSummary(postId, reactionType, 1);
          LoggerService.info('🔄 Reaction updated on $postId');
        }
      } else {
        // New reaction
        await reactionRef.set({
          'reaction': reactionType,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _updateReactionSummary(postId, reactionType, 1);
        LoggerService.info('👍 Reaction added to $postId');
      }
    } catch (e) {
      LoggerService.error('Failed to toggle reaction', e);
      rethrow;
    }
  }

  /// Update reaction summary counters on post document
  Future<void> _updateReactionSummary(
    String postId,
    String reactionType,
    int delta,
  ) async {
    final field = reactionType.toLowerCase();
    await _postsRef.doc(postId).update({
      'reactionSummary.total': FieldValue.increment(delta),
      'reactionSummary.$field': FieldValue.increment(delta),
    });
  }

  /// Get current user's reaction on a post
  Future<String?> getCurrentUserReaction(String postId) async {
    try {
      final doc = await _postsRef
          .doc(postId)
          .collection('reactions')
          .doc(_currentUid)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['reaction'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get all reactions for a post (for reaction list screen)
  Future<List<PostReactionModel>> getPostReactions({
    required String postId,
    String? filterByType,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _postsRef
          .doc(postId)
          .collection('reactions');

      if (filterByType != null) {
        query = query.where('reaction', isEqualTo: filterByType);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PostReactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to get post reactions', e);
      rethrow;
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      final commentData = {
        'postId': postId,
        'author': currentAuthor.toMap(),
        'text': text,
        'reactionSummary': {
          'total': 0,
          'like': 0,
          'love': 0,
          'insightful': 0,
          'support': 0,
          'inspiring': 0,
        },
        'replyCount': 0,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _commentsRef.add(commentData);

      // Increment post commentCount
      await _postsRef.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      LoggerService.info('💬 Comment added to post $postId');
      return docRef.id;
    } catch (e) {
      LoggerService.error('Failed to add comment', e);
      rethrow;
    }
  }

  /// Fetch comments for a post with pagination
  Future<List<CommentModel>> fetchComments({
    required String postId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _commentsRef
          .where('postId', isEqualTo: postId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch comments', e);
      rethrow;
    }
  }

  /// Delete a comment (soft delete)
  Future<void> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      await _commentsRef.doc(commentId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _currentUid,
      });
      await _postsRef.doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
      LoggerService.info('🗑️ Comment soft-deleted: $commentId');
    } catch (e) {
      LoggerService.error('Failed to delete comment', e);
      rethrow;
    }
  }

  // ==================== REPLY OPERATIONS ====================

  /// Add a reply to a comment
  Future<String> addReply({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    try {
      final replyData = {
        'postId': postId,
        'commentId': commentId,
        'author': currentAuthor.toMap(),
        'text': text,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _repliesRef.add(replyData);

      // Increment comment replyCount
      await _commentsRef.doc(commentId).update({
        'replyCount': FieldValue.increment(1),
      });

      LoggerService.info('↩️ Reply added to comment $commentId');
      return docRef.id;
    } catch (e) {
      LoggerService.error('Failed to add reply', e);
      rethrow;
    }
  }

  /// Fetch replies for a comment
  Future<List<ReplyModel>> fetchReplies({
    required String commentId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _repliesRef
          .where('commentId', isEqualTo: commentId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => ReplyModel.fromFirestore(doc)).toList();
    } catch (e) {
      LoggerService.error('Failed to fetch replies', e);
      rethrow;
    }
  }
}
