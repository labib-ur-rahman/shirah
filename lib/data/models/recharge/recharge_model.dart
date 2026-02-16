import 'package:cloud_firestore/cloud_firestore.dart';

/// Mobile Recharge Model - Represents a recharge/drive offer transaction
/// Stored in: mobile_recharge/{refid}
class RechargeModel {
  final String refid;
  final String uid;
  final String type; // 'recharge' or 'drive_offer'
  final String phone;
  final String operator;
  final String operatorName;
  final String numberType;
  final String numberTypeName;
  final double amount;
  final RechargeOfferInfo? offer;
  final RechargeCashbackInfo cashback;
  final RechargeEcareInfo ecare;
  final RechargeWalletInfo wallet;
  final String status;
  final String? ecareStatus;
  final RechargeErrorInfo? error;
  final String? walletTransactionId;
  final String? cashbackTransactionId;
  final String? auditLogId;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RechargeModel({
    required this.refid,
    required this.uid,
    required this.type,
    required this.phone,
    required this.operator,
    required this.operatorName,
    required this.numberType,
    required this.numberTypeName,
    required this.amount,
    this.offer,
    required this.cashback,
    required this.ecare,
    required this.wallet,
    required this.status,
    this.ecareStatus,
    this.error,
    this.walletTransactionId,
    this.cashbackTransactionId,
    this.auditLogId,
    this.submittedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty instance
  factory RechargeModel.empty() {
    return RechargeModel(
      refid: '',
      uid: '',
      type: 'recharge',
      phone: '',
      operator: '',
      operatorName: '',
      numberType: '1',
      numberTypeName: 'Prepaid',
      amount: 0,
      cashback: RechargeCashbackInfo.empty(),
      ecare: RechargeEcareInfo.empty(),
      wallet: RechargeWalletInfo.empty(),
      status: 'initiated',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory RechargeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RechargeModel.fromMap(data);
  }

  /// Create from map (from Cloud Functions response)
  factory RechargeModel.fromMap(Map<String, dynamic> map) {
    return RechargeModel(
      refid: map['refid'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      type: map['type'] as String? ?? 'recharge',
      phone: map['phone'] as String? ?? '',
      operator: map['operator'] as String? ?? '',
      operatorName: map['operatorName'] as String? ?? '',
      numberType: map['numberType'] as String? ?? '1',
      numberTypeName: map['numberTypeName'] as String? ?? 'Prepaid',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      offer: map['offer'] != null
          ? RechargeOfferInfo.fromMap(
              Map<String, dynamic>.from(map['offer'] as Map),
            )
          : null,
      cashback: map['cashback'] != null
          ? RechargeCashbackInfo.fromMap(
              Map<String, dynamic>.from(map['cashback'] as Map),
            )
          : RechargeCashbackInfo.empty(),
      ecare: map['ecare'] != null
          ? RechargeEcareInfo.fromMap(
              Map<String, dynamic>.from(map['ecare'] as Map),
            )
          : RechargeEcareInfo.empty(),
      wallet: map['wallet'] != null
          ? RechargeWalletInfo.fromMap(
              Map<String, dynamic>.from(map['wallet'] as Map),
            )
          : RechargeWalletInfo.empty(),
      status: map['status'] as String? ?? 'initiated',
      ecareStatus: map['ecareStatus'] as String?,
      error: map['error'] != null
          ? RechargeErrorInfo.fromMap(
              Map<String, dynamic>.from(map['error'] as Map),
            )
          : null,
      walletTransactionId: map['walletTransactionId'] as String?,
      cashbackTransactionId: map['cashbackTransactionId'] as String?,
      auditLogId: map['auditLogId'] as String?,
      submittedAt: _parseTimestamp(map['submittedAt']),
      completedAt: _parseTimestamp(map['completedAt']),
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
    );
  }

  // ==================== Computed Properties ====================

  bool get isRecharge => type == 'recharge';
  bool get isDriveOffer => type == 'drive_offer';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed' || status == 'refunded';
  bool get isPending =>
      status == 'initiated' ||
      status == 'submitted' ||
      status == 'processing' ||
      status == 'pending_verification';

  String get formattedAmount => '৳${amount.toStringAsFixed(0)}';
  String get formattedCashback => '৳${cashback.amount.toStringAsFixed(2)}';

  String get displayStatus {
    switch (status) {
      case 'initiated':
        return 'Initiated';
      case 'submitted':
        return 'Submitted';
      case 'processing':
        return 'Processing';
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'pending_verification':
        return 'Pending Verification';
      default:
        return status;
    }
  }

  String get typeDisplay => isRecharge ? 'Recharge' : 'Drive Offer';

  // ==================== Private Helpers ====================

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        ((value['_seconds'] as num).toInt()) * 1000,
      );
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// ==================== Sub-Models ====================

class RechargeOfferInfo {
  final String offerType;
  final String offerTypeName;
  final String minutePack;
  final String internetPack;
  final String smsPack;
  final String callratePack;
  final String validity;
  final double commissionAmount;

  const RechargeOfferInfo({
    required this.offerType,
    required this.offerTypeName,
    required this.minutePack,
    required this.internetPack,
    required this.smsPack,
    required this.callratePack,
    required this.validity,
    required this.commissionAmount,
  });

  factory RechargeOfferInfo.fromMap(Map<String, dynamic> map) {
    return RechargeOfferInfo(
      offerType: map['offerType'] as String? ?? '',
      offerTypeName: map['offerTypeName'] as String? ?? '',
      minutePack: map['minutePack'] as String? ?? '-',
      internetPack: map['internetPack'] as String? ?? '-',
      smsPack: map['smsPack'] as String? ?? '-',
      callratePack: map['callratePack'] as String? ?? '-',
      validity: map['validity'] as String? ?? '',
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RechargeCashbackInfo {
  final double amount;
  final double? percentage;
  final String source;
  final bool credited;

  const RechargeCashbackInfo({
    required this.amount,
    this.percentage,
    required this.source,
    required this.credited,
  });

  factory RechargeCashbackInfo.empty() {
    return const RechargeCashbackInfo(amount: 0, source: '', credited: false);
  }

  factory RechargeCashbackInfo.fromMap(Map<String, dynamic> map) {
    return RechargeCashbackInfo(
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble(),
      source: map['source'] as String? ?? '',
      credited: map['credited'] as bool? ?? false,
    );
  }
}

class RechargeEcareInfo {
  final String? trxId;
  final String? rechargeTrxId;
  final String lastMessage;
  final int pollCount;

  const RechargeEcareInfo({
    this.trxId,
    this.rechargeTrxId,
    required this.lastMessage,
    required this.pollCount,
  });

  factory RechargeEcareInfo.empty() {
    return const RechargeEcareInfo(lastMessage: '', pollCount: 0);
  }

  factory RechargeEcareInfo.fromMap(Map<String, dynamic> map) {
    return RechargeEcareInfo(
      trxId: map['trxId'] as String?,
      rechargeTrxId: map['rechargeTrxId'] as String?,
      lastMessage: map['lastMessage'] as String? ?? '',
      pollCount: (map['pollCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RechargeWalletInfo {
  final double balanceBefore;
  final double balanceAfterDebit;
  final double? balanceAfterCashback;

  const RechargeWalletInfo({
    required this.balanceBefore,
    required this.balanceAfterDebit,
    this.balanceAfterCashback,
  });

  factory RechargeWalletInfo.empty() {
    return const RechargeWalletInfo(balanceBefore: 0, balanceAfterDebit: 0);
  }

  factory RechargeWalletInfo.fromMap(Map<String, dynamic> map) {
    return RechargeWalletInfo(
      balanceBefore: (map['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfterDebit: (map['balanceAfterDebit'] as num?)?.toDouble() ?? 0,
      balanceAfterCashback: (map['balanceAfterCashback'] as num?)?.toDouble(),
    );
  }
}

class RechargeErrorInfo {
  final String code;
  final String message;

  const RechargeErrorInfo({required this.code, required this.message});

  factory RechargeErrorInfo.fromMap(Map<String, dynamic> map) {
    return RechargeErrorInfo(
      code: map['code'] as String? ?? '',
      message: map['message'] as String? ?? '',
    );
  }
}
