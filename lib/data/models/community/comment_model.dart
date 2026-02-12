import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shirah/data/models/community/post_author_model.dart';
import 'package:shirah/data/models/community/reaction_summary_model.dart';

/// Comment Model - Represents a comment in Firestore: comments/{commentId}
/// Flat collection structure for scalability (not a subcollection of posts)
class CommentModel {
  final String commentId;
  final String postId;
  final PostAuthorModel author;
  final String text;
  final ReactionSummaryModel reactionSummary;
  final int replyCount;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;

  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.author,
    required this.text,
    required this.reactionSummary,
    required this.replyCount,
    required this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
  });

  factory CommentModel.empty() {
    return CommentModel(
      commentId: '',
      postId: '',
      author: PostAuthorModel.empty(),
      text: '',
      reactionSummary: ReactionSummaryModel.empty(),
      replyCount: 0,
      isDeleted: false,
      createdAt: DateTime.now(),
    );
  }

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel.fromMap(doc.id, data);
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> data) {
    return CommentModel(
      commentId: id,
      postId: data['postId'] as String? ?? '',
      author: PostAuthorModel.fromMap(
        data['author'] as Map<String, dynamic>? ?? {},
      ),
      text: data['text'] as String? ?? '',
      reactionSummary: ReactionSummaryModel.fromMap(
        data['reactionSummary'] as Map<String, dynamic>? ?? {},
      ),
      replyCount: data['replyCount'] as int? ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'postId': postId,
      'author': author.toMap(),
      'text': text,
      'reactionSummary': ReactionSummaryModel.empty().toMap(),
      'replyCount': 0,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
