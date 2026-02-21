import 'dart:convert';

RequestResponse requestResponseFromJson(String str) =>
    RequestResponse.fromJson(json.decode(str));

String requestResponseToJson(RequestResponse data) =>
    json.encode(data.toJson());

class RequestResponse {
  String? fullName;
  String? email;
  String? amount;
  String? fee;
  String? chargedAmount;
  String? invoiceId;
  String? paymentMethod;
  String? senderNumber;
  String? transactionId;
  DateTime? date;
  ResponseStatus? status;

  RequestResponse({
    this.fullName,
    this.email,
    this.amount,
    this.fee,
    this.chargedAmount,
    this.invoiceId,
    this.paymentMethod,
    this.senderNumber,
    this.transactionId,
    this.date,
    this.status,
  });

  factory RequestResponse.fromJson(Map<String, dynamic> json) =>
      RequestResponse(
        fullName: json["full_name"],
        email: json["email"],
        amount: json["amount"],
        fee: json["fee"],
        chargedAmount: json["charged_amount"],
        invoiceId: json["invoice_id"],
        paymentMethod: json["payment_method"],
        senderNumber: json["sender_number"],
        transactionId: json["transaction_id"],
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        status: _parseStatus(json["status"]),
      );

  /// Parse UddoktaPay status string to [ResponseStatus].
  ///
  /// UddoktaPay returns:
  ///   - `"COMPLETED"` → payment fully confirmed
  ///   - `"PENDING"`   → manual payment awaiting merchant verification
  ///   - `"ERROR"`     → payment failed
  ///   - `null` / `""` → unknown, treat as pending
  ///
  /// Previously, "PENDING" fell into the catch-all `canceled` branch,
  /// which caused the app to show "Payment Cancelled" for manual payments
  /// (bKash/Nagad manual where user submits a transaction ID).
  static ResponseStatus _parseStatus(dynamic raw) {
    final status = raw?.toString().toUpperCase().trim() ?? '';
    switch (status) {
      case 'COMPLETED':
        return ResponseStatus.completed;
      case 'PENDING':
      case '':
        return ResponseStatus.pending;
      default:
        // ERROR, CANCELED, or any unexpected value
        return ResponseStatus.canceled;
    }
  }

  Map<String, dynamic> toJson() => {
        "full_name": fullName,
        "email": email,
        "amount": amount,
        "fee": fee,
        "charged_amount": chargedAmount,
        "invoice_id": invoiceId,
        "payment_method": paymentMethod,
        "sender_number": senderNumber,
        "transaction_id": transactionId,
        "date": date?.toIso8601String(),
        "status": _statusToString(status),
      };

  /// Convert [ResponseStatus] enum to the string UddoktaPay uses.
  static String _statusToString(ResponseStatus? s) {
    switch (s) {
      case ResponseStatus.completed:
        return 'COMPLETED';
      case ResponseStatus.pending:
        return 'PENDING';
      case ResponseStatus.canceled:
        return 'CANCELED';
      default:
        return '';
    }
  }
}

enum ResponseStatus {
  completed,
  canceled,
  pending,
}
