/// Drive Offer Model - Represents a telecom drive offer pack
/// Data comes from ECARE OFFERPACK API, cached in Firestore
class DriveOfferModel {
  final String operator;
  final String operatorName;
  final String numberType;
  final String offerType;
  final String offerTypeName;
  final String minutePack;
  final String internetPack;
  final String smsPack;
  final String callratePack;
  final String validity;
  final double amount;
  final double commissionAmount;
  final String status;

  const DriveOfferModel({
    required this.operator,
    required this.operatorName,
    required this.numberType,
    required this.offerType,
    required this.offerTypeName,
    required this.minutePack,
    required this.internetPack,
    required this.smsPack,
    required this.callratePack,
    required this.validity,
    required this.amount,
    required this.commissionAmount,
    required this.status,
  });

  /// Empty instance
  factory DriveOfferModel.empty() {
    return const DriveOfferModel(
      operator: '',
      operatorName: '',
      numberType: '1',
      offerType: '',
      offerTypeName: '',
      minutePack: '-',
      internetPack: '-',
      smsPack: '-',
      callratePack: '-',
      validity: '',
      amount: 0,
      commissionAmount: 0,
      status: 'A',
    );
  }

  /// Create from map (Cloud Functions response)
  factory DriveOfferModel.fromMap(Map<String, dynamic> map) {
    return DriveOfferModel(
      operator: map['operator'] as String? ?? '',
      operatorName: map['operatorName'] as String? ?? '',
      numberType: map['numberType'] as String? ?? '1',
      offerType: map['offerType'] as String? ?? '',
      offerTypeName: map['offerTypeName'] as String? ?? '',
      minutePack: map['minutePack'] as String? ?? '-',
      internetPack: map['internetPack'] as String? ?? '-',
      smsPack: map['smsPack'] as String? ?? '-',
      callratePack: map['callratePack'] as String? ?? '-',
      validity: map['validity'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'A',
    );
  }

  /// Convert to map for API request
  Map<String, dynamic> toOfferDetailsMap() {
    return {
      'offerType': offerType,
      'minutePack': minutePack,
      'internetPack': internetPack,
      'smsPack': smsPack,
      'callratePack': callratePack,
      'validity': validity,
      'commissionAmount': commissionAmount,
    };
  }

  // ==================== Computed Properties ====================

  String get formattedAmount => '৳${amount.toStringAsFixed(0)}';
  String get formattedCashback => '৳${commissionAmount.toStringAsFixed(2)}';

  bool get hasMinutes => minutePack != '-' && minutePack.isNotEmpty;
  bool get hasInternet => internetPack != '-' && internetPack.isNotEmpty;
  bool get hasSms => smsPack != '-' && smsPack.isNotEmpty;
  bool get hasCallRate => callratePack != '-' && callratePack.isNotEmpty;

  /// Numeric operator code for ECARE API
  String get numericOperatorCode {
    const mapping = {'GP': '7', 'BL': '4', 'RB': '8', 'AR': '6', 'TL': '5'};
    return mapping[operator] ?? '7';
  }

  /// Check if offer is internet-focused
  bool get isInternetOffer =>
      offerType == 'Internet' || offerType == 'internet';

  /// Check if offer is voice-focused
  bool get isVoiceOffer => offerType == 'Minute' || offerType == 'minute';

  /// Check if offer is combo type
  bool get isComboOffer => offerType == 'Combo' || offerType == 'combo';

  /// Get a short description
  String get shortDescription {
    final parts = <String>[];
    if (hasMinutes) parts.add('$minutePack Min');
    if (hasInternet) parts.add('$internetPack Data');
    if (hasSms) parts.add('$smsPack SMS');
    return parts.isEmpty ? callratePack : parts.join(' + ');
  }
}
