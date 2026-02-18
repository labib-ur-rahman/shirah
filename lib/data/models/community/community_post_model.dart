import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shirah/data/models/community/post_author_model.dart';
import 'package:shirah/data/models/community/reaction_summary_model.dart';

/// Community Post Model - Represents a post document in Firestore: posts/{postId}
/// Matches the Community Post System v2 Extended Documentation
class CommunityPostModel {
  final String postId;
  final PostAuthorModel author;
  final String text;
  final List<String> images;
  final String privacy;
  final String status;
  final ReactionSummaryModel reactionSummary;
  final int commentCount;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityPostModel({
    required this.postId,
    required this.author,
    required this.text,
    required this.images,
    required this.privacy,
    required this.status,
    required this.reactionSummary,
    required this.commentCount,
    required this.isDeleted,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  CommunityPostModel copyWith({
    String? postId,
    PostAuthorModel? author,
    String? text,
    List<String>? images,
    String? privacy,
    String? status,
    ReactionSummaryModel? reactionSummary,
    int? commentCount,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPostModel(
      postId: postId ?? this.postId,
      author: author ?? this.author,
      text: text ?? this.text,
      images: images ?? this.images,
      privacy: privacy ?? this.privacy,
      status: status ?? this.status,
      reactionSummary: reactionSummary ?? this.reactionSummary,
      commentCount: commentCount ?? this.commentCount,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Empty post for initialization
  factory CommunityPostModel.empty() {
    return CommunityPostModel(
      postId: '',
      author: PostAuthorModel.empty(),
      text: '',
      images: [],
      privacy: PostPrivacy.public_,
      status: PostStatus.pending,
      reactionSummary: ReactionSummaryModel.empty(),
      commentCount: 0,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory CommunityPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityPostModel.fromMap(doc.id, data);
  }

  /// Create from map with postId
  factory CommunityPostModel.fromMap(String id, Map<String, dynamic> data) {
    return CommunityPostModel(
      postId: id,
      author: PostAuthorModel.fromMap(
        data['author'] as Map<String, dynamic>? ?? {},
      ),
      text: data['content']?['text'] as String? ?? '',
      images: List<String>.from(data['content']?['images'] ?? []),
      privacy: data['privacy'] as String? ?? PostPrivacy.public_,
      status: data['status'] as String? ?? PostStatus.pending,
      reactionSummary: ReactionSummaryModel.fromMap(
        data['reactionSummary'] as Map<String, dynamic>? ?? {},
      ),
      commentCount: data['commentCount'] as int? ?? 0,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document (for creating new post)
  Map<String, dynamic> toCreateMap() {
    return {
      'author': author.toMap(),
      'content': {'text': text, 'images': images},
      'privacy': privacy,
      'status': status,
      'reactionSummary': ReactionSummaryModel.empty().toMap(),
      'commentCount': 0,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Check if post has image
  bool get hasImage => images.isNotEmpty;

  /// Get first image URL
  String? get firstImage => images.isNotEmpty ? images.first : null;

  /// Get total reactions count
  int get totalReactions => reactionSummary.total;

  /// Privacy display icon
  String get privacyIcon {
    switch (privacy) {
      case PostPrivacy.friends:
        return '👥';
      case PostPrivacy.onlyMe:
        return '🔒';
      default:
        return '🌐';
    }
  }
}

/// Post Privacy enum values matching Firestore/Cloud Functions
class PostPrivacy {
  PostPrivacy._();
  static const String public_ = 'PUBLIC';
  static const String friends = 'FRIENDS';
  static const String onlyMe = 'ONLY_ME';

  static List<String> get values => [public_, friends, onlyMe];

  static String displayName(String privacy) {
    switch (privacy) {
      case friends:
        return 'Friends';
      case onlyMe:
        return 'Only Me';
      default:
        return 'Public';
    }
  }
}

/// Post Status enum values matching Firestore/Cloud Functions
class PostStatus {
  PostStatus._();
  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
}
