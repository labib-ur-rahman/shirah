import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment type enum
enum PaymentType {
  verification,
  subscription;

  String get value {
    switch (this) {
      case PaymentType.verification:
        return 'verification';
      case PaymentType.subscription:
        return 'subscription';
    }
  }

  static PaymentType fromString(String value) {
    switch (value) {
      case 'subscription':
        return PaymentType.subscription;
      default:
        return PaymentType.verification;
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  canceled,
  failed;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.canceled:
        return 'canceled';
      case PaymentStatus.failed:
        return 'failed';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return PaymentStatus.completed;
      case 'canceled':
        return PaymentStatus.canceled;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment Transaction Model
/// Stored in: payment_transactions/{id}
class PaymentTransactionModel {
  final String id;
  final String uid;
  final PaymentType type;
  final double amount;
  final PaymentStatus status;
  final String paymentMethod;
  final String invoiceId;
  final String transactionId;
  final String senderNumber;
  final String fee;
  final String chargedAmount;
  final Map<String, dynamic> uddoktapayResponse;
  final String? processedBy;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentTransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.invoiceId,
    required this.transactionId,
    required this.senderNumber,
    required this.fee,
    required this.chargedAmount,
    required this.uddoktapayResponse,
    this.processedBy,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore map
  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map) {
    return PaymentTransactionModel(
      id: map['id']?.toString() ?? '',
      uid: map['uid']?.toString() ?? '',
      type: PaymentType.fromString(map['type']?.toString() ?? ''),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: PaymentStatus.fromString(map['status']?.toString() ?? ''),
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      invoiceId: map['invoiceId']?.toString() ?? '',
      transactionId: map['transactionId']?.toString() ?? '',
      senderNumber: map['senderNumber']?.toString() ?? '',
      fee: map['fee']?.toString() ?? '0.00',
      chargedAmount: map['chargedAmount']?.toString() ?? '0.00',
      uddoktapayResponse: Map<String, dynamic>.from(
        map['uddoktapayResponse'] as Map? ?? {},
      ),
      processedBy: map['processedBy']?.toString(),
      processedAt: _parseTimestamp(map['processedAt']),
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(map['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type.value,
      'amount': amount,
      'status': status.value,
      'paymentMethod': paymentMethod,
      'invoiceId': invoiceId,
      'transactionId': transactionId,
      'senderNumber': senderNumber,
      'fee': fee,
      'chargedAmount': chargedAmount,
      'uddoktapayResponse': uddoktapayResponse,
      'processedBy': processedBy,
      'processedAt': processedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copy with
  PaymentTransactionModel copyWith({
    String? id,
    String? uid,
    PaymentType? type,
    double? amount,
    PaymentStatus? status,
    String? paymentMethod,
    String? invoiceId,
    String? transactionId,
    String? senderNumber,
    String? fee,
    String? chargedAmount,
    Map<String, dynamic>? uddoktapayResponse,
    String? processedBy,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceId: invoiceId ?? this.invoiceId,
      transactionId: transactionId ?? this.transactionId,
      senderNumber: senderNumber ?? this.senderNumber,
      fee: fee ?? this.fee,
      chargedAmount: chargedAmount ?? this.chargedAmount,
      uddoktapayResponse: uddoktapayResponse ?? this.uddoktapayResponse,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Check if payment is completed
  bool get isCompleted => status == PaymentStatus.completed;

  /// Check if this is a verification payment
  bool get isVerification => type == PaymentType.verification;

  /// Check if this is a subscription payment
  bool get isSubscription => type == PaymentType.subscription;

  /// Formatted amount string
  String get formattedAmount => '৳${amount.toStringAsFixed(0)}';

  /// Parse Firestore timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
