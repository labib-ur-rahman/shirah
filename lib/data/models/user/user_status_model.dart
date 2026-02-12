/// User Status Model - Account lifecycle & risk control
/// Stored in: users/{uid}.status
class UserStatusModel {
  /// Account state: "active" | "suspended" | "under_review" | "banned" | "deleted"
  final String accountState;

  /// Profile verification status (requires 250৳ payment)
  final bool verified;

  /// Subscription status: "none" | "active" | "expired"
  final String subscription;

  /// Risk level: "normal" | "watch" | "high" | "fraud"
  final String riskLevel;

  const UserStatusModel({
    required this.accountState,
    required this.verified,
    required this.subscription,
    required this.riskLevel,
  });

  /// Empty status (new user defaults)
  factory UserStatusModel.empty() {
    return const UserStatusModel(
      accountState: 'active',
      verified: false,
      subscription: 'none',
      riskLevel: 'normal',
    );
  }

  /// Create from map
  factory UserStatusModel.fromMap(Map<String, dynamic> map) {
    return UserStatusModel(
      accountState: map['accountState']?.toString() ?? 'active',
      verified: map['verified'] as bool? ?? false,
      subscription: map['subscription']?.toString() ?? 'none',
      riskLevel: map['riskLevel']?.toString() ?? 'normal',
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'accountState': accountState,
      'verified': verified,
      'subscription': subscription,
      'riskLevel': riskLevel,
    };
  }

  /// Copy with
  UserStatusModel copyWith({
    String? accountState,
    bool? verified,
    String? subscription,
    String? riskLevel,
  }) {
    return UserStatusModel(
      accountState: accountState ?? this.accountState,
      verified: verified ?? this.verified,
      subscription: subscription ?? this.subscription,
      riskLevel: riskLevel ?? this.riskLevel,
    );
  }

  /// Check if account is active
  bool get isActive => accountState == 'active';

  /// Check if account is suspended
  bool get isSuspended => accountState == 'suspended';

  /// Check if account is banned
  bool get isBanned => accountState == 'banned';

  /// Check if account is deleted
  bool get isDeleted => accountState == 'deleted';

  /// Check if user is verified
  bool get isVerified => verified;

  /// Check if user has active subscription
  bool get isSubscribed => subscription == 'active';

  /// Check if user has any premium status
  bool get hasPremiumStatus => verified || isSubscribed;

  /// Check if high risk
  bool get isHighRisk => riskLevel == 'high' || riskLevel == 'fraud';
}
