import 'package:cloud_firestore/cloud_firestore.dart';

/// Post Reaction Model - Individual user reaction on a post
/// Path: posts/{postId}/reactions/{userId}
/// One user = one reaction per post
class PostReactionModel {
  final String userId;
  final String reaction;
  final DateTime createdAt;

  /// Additional display fields (loaded separately from user doc)
  final String? userName;
  final String? userPhoto;

  const PostReactionModel({
    required this.userId,
    required this.reaction,
    required this.createdAt,
    this.userName,
    this.userPhoto,
  });

  factory PostReactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostReactionModel.fromMap(doc.id, data);
  }

  factory PostReactionModel.fromMap(String id, Map<String, dynamic> data) {
    return PostReactionModel(
      userId: id,
      reaction: data['reaction'] as String? ?? 'LIKE',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userName: data['userName'] as String?,
      userPhoto: data['userPhoto'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'reaction': reaction, 'createdAt': FieldValue.serverTimestamp()};
  }
}
