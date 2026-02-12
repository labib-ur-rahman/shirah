import 'package:cloud_firestore/cloud_firestore.dart';

/// User Network Model - Direct parent relationship
/// Stored in: users/{uid}.network
class UserNetworkModel {
  /// UID of parent user (null for super admin / root users)
  final String? parentUid;

  /// How user joined the network: "invite" | "direct" | "manual"
  final String joinedVia;

  /// When user joined (deprecated - use meta.createdAt)
  final DateTime? joinedAt;

  const UserNetworkModel({
    this.parentUid,
    required this.joinedVia,
    this.joinedAt,
  });

  /// Empty network
  factory UserNetworkModel.empty() {
    return const UserNetworkModel(
      parentUid: null,
      joinedVia: 'direct',
      joinedAt: null,
    );
  }

  /// Create from map
  factory UserNetworkModel.fromMap(Map<String, dynamic> map) {
    DateTime? joinedAt;
    if (map['joinedAt'] != null) {
      if (map['joinedAt'] is Timestamp) {
        joinedAt = (map['joinedAt'] as Timestamp).toDate();
      } else if (map['joinedAt'] is String) {
        joinedAt = DateTime.tryParse(map['joinedAt'] as String);
      }
    }

    return UserNetworkModel(
      parentUid: map['parentUid']?.toString(),
      joinedVia: map['joinedVia']?.toString() ?? 'direct',
      joinedAt: joinedAt,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'parentUid': parentUid,
      'joinedVia': joinedVia,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Copy with
  UserNetworkModel copyWith({
    String? parentUid,
    String? joinedVia,
    DateTime? joinedAt,
  }) {
    return UserNetworkModel(
      parentUid: parentUid ?? this.parentUid,
      joinedVia: joinedVia ?? this.joinedVia,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Check if user has a parent (was referred)
  bool get hasParent => parentUid != null && parentUid!.isNotEmpty;
}
