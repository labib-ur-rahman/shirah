import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shirah/data/models/community/post_author_model.dart';

/// Reply Model - Represents a reply in Firestore: replies/{replyId}
/// Max nesting level = 1 (no replies to replies)
/// No reactions on replies
class ReplyModel {
  final String replyId;
  final String postId;
  final String commentId;
  final PostAuthorModel author;
  final String text;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;

  const ReplyModel({
    required this.replyId,
    required this.postId,
    required this.commentId,
    required this.author,
    required this.text,
    required this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
  });

  factory ReplyModel.empty() {
    return ReplyModel(
      replyId: '',
      postId: '',
      commentId: '',
      author: PostAuthorModel.empty(),
      text: '',
      isDeleted: false,
      createdAt: DateTime.now(),
    );
  }

  factory ReplyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReplyModel.fromMap(doc.id, data);
  }

  factory ReplyModel.fromMap(String id, Map<String, dynamic> data) {
    return ReplyModel(
      replyId: id,
      postId: data['postId'] as String? ?? '',
      commentId: data['commentId'] as String? ?? '',
      author: PostAuthorModel.fromMap(
        data['author'] as Map<String, dynamic>? ?? {},
      ),
      text: data['text'] as String? ?? '',
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'postId': postId,
      'commentId': commentId,
      'author': author.toMap(),
      'text': text,
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
