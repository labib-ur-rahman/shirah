/// User Wallet Model - Wallet snapshot (real ledger in wallet_transactions)
/// Stored in: users/{uid}.wallet
class UserWalletModel {
  /// Current BDT balance (real money, withdrawable)
  final double balanceBDT;

  /// Current reward points (non-cash, convertible)
  final int rewardPoints;

  /// Whether wallet is locked (blocks all transactions)
  final bool locked;

  const UserWalletModel({
    required this.balanceBDT,
    required this.rewardPoints,
    required this.locked,
  });

  /// Empty wallet
  factory UserWalletModel.empty() {
    return const UserWalletModel(
      balanceBDT: 0.0,
      rewardPoints: 0,
      locked: false,
    );
  }

  /// Create from map
  factory UserWalletModel.fromMap(Map<String, dynamic> map) {
    return UserWalletModel(
      balanceBDT: (map['balanceBDT'] as num?)?.toDouble() ?? 0.0,
      rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 0,
      locked: map['locked'] as bool? ?? false,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'balanceBDT': balanceBDT,
      'rewardPoints': rewardPoints,
      'locked': locked,
    };
  }

  /// Copy with
  UserWalletModel copyWith({
    double? balanceBDT,
    int? rewardPoints,
    bool? locked,
  }) {
    return UserWalletModel(
      balanceBDT: balanceBDT ?? this.balanceBDT,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      locked: locked ?? this.locked,
    );
  }

  /// Convenience getter for 'balance' (alias to balanceBDT)
  double get balance => balanceBDT;

  /// Get reward points as BDT equivalent
  /// 100 Reward Points = 1 BDT
  double get rewardPointsAsBDT => rewardPoints / 100;

  /// Get total value (balance + converted points)
  double get totalValue => balanceBDT + rewardPointsAsBDT;

  /// Check if has any balance
  bool get hasBalance => balanceBDT > 0;

  /// Check if has any reward points
  bool get hasRewardPoints => rewardPoints > 0;

  /// Check if wallet is unlocked (can transact)
  bool get isUnlocked => !locked;

  /// Format balance as string
  String get formattedBalance => '৳${balanceBDT.toStringAsFixed(2)}';

  /// Format reward points as string
  String get formattedRewardPoints => '$rewardPoints pts';
}
