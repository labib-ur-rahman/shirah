/// User Permissions Model - Feature-level access control (for regular users)
/// Stored in: users/{uid}.permissions
class UserPermissionsModel {
  /// Can create community posts (true after verification)
  final bool canPost;

  /// Can request withdrawals (true after verification)
  final bool canWithdraw;

  /// Can view community content (default: true)
  final bool canViewCommunity;

  const UserPermissionsModel({
    required this.canPost,
    required this.canWithdraw,
    required this.canViewCommunity,
  });

  /// Default permissions for new users
  factory UserPermissionsModel.defaultPermissions() {
    return const UserPermissionsModel(
      canPost: false, // Requires verification
      canWithdraw: false, // Requires verification
      canViewCommunity: true,
    );
  }

  /// Verified user permissions
  factory UserPermissionsModel.verified() {
    return const UserPermissionsModel(
      canPost: true,
      canWithdraw: true,
      canViewCommunity: true,
    );
  }

  /// Create from map
  factory UserPermissionsModel.fromMap(Map<String, dynamic> map) {
    return UserPermissionsModel(
      canPost: map['canPost'] as bool? ?? false,
      canWithdraw: map['canWithdraw'] as bool? ?? false,
      canViewCommunity: map['canViewCommunity'] as bool? ?? true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'canPost': canPost,
      'canWithdraw': canWithdraw,
      'canViewCommunity': canViewCommunity,
    };
  }

  /// Copy with
  UserPermissionsModel copyWith({
    bool? canPost,
    bool? canWithdraw,
    bool? canViewCommunity,
  }) {
    return UserPermissionsModel(
      canPost: canPost ?? this.canPost,
      canWithdraw: canWithdraw ?? this.canWithdraw,
      canViewCommunity: canViewCommunity ?? this.canViewCommunity,
    );
  }

  /// Check if user has any restricted permission
  bool get hasRestrictedAccess => !canPost || !canWithdraw || !canViewCommunity;

  /// Check if user has full permissions
  bool get hasFullPermissions => canPost && canWithdraw && canViewCommunity;
}
