import 'package:shirah/core/services/cloud_functions_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/payment/payment_transaction_model.dart';

/// Payment Repository
/// Handles all payment-related Cloud Functions calls
/// All writes go through Cloud Functions — no direct Firestore access
class PaymentRepository {
  final CloudFunctionsService _cloudFunctions = CloudFunctionsService.instance;

  // ===== CREATE =====

  /// Create a payment transaction via Cloud Function
  /// Returns the created transaction data from UddoktaPay
  Future<Map<String, dynamic>> createPaymentTransaction({
    required String type,
    required Map<String, dynamic> uddoktapayResponse,
  }) async {
    try {
      final result = await _cloudFunctions.createPaymentTransaction(
        type: type,
        uddoktapayResponse: uddoktapayResponse,
      );
      return result;
    } catch (e) {
      LoggerService.error('PaymentRepository: createPaymentTransaction', e);
      rethrow;
    }
  }

  // ===== READ =====

  /// Get payment configuration (prices, UddoktaPay credentials)
  Future<Map<String, dynamic>> getPaymentConfig() async {
    try {
      final result = await _cloudFunctions.getPaymentConfig();
      return result;
    } catch (e) {
      LoggerService.error('PaymentRepository: getPaymentConfig', e);
      rethrow;
    }
  }

  /// Get user's payment history (paginated)
  Future<List<PaymentTransactionModel>> getPaymentHistory({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      final result = await _cloudFunctions.getPaymentHistory(
        limit: limit,
        startAfter: startAfter,
      );

      final transactions = result['transactions'] as List? ?? [];
      return transactions
          .map(
            (t) => PaymentTransactionModel.fromMap(
              Map<String, dynamic>.from(t as Map),
            ),
          )
          .toList();
    } catch (e) {
      LoggerService.error('PaymentRepository: getPaymentHistory', e);
      rethrow;
    }
  }

  // ===== RE-VERIFY =====

  /// Re-verify a pending payment by checking UddoktaPay API server-side
  /// Returns { success, message, data: { status, verified?, subscribed? } }
  Future<Map<String, dynamic>> reVerifyPendingPayment({
    required String paymentTransactionId,
  }) async {
    try {
      final result = await _cloudFunctions.reVerifyPendingPayment(
        paymentTransactionId: paymentTransactionId,
      );
      return result;
    } catch (e) {
      LoggerService.error('PaymentRepository: reVerifyPendingPayment', e);
      rethrow;
    }
  }

  // ===== PROCESS =====

  /// Verify user (called after successful payment)
  Future<Map<String, dynamic>> verifyUser({
    required String paymentTransactionId,
  }) async {
    try {
      final result = await _cloudFunctions.verifyUserProfile(
        paymentTransactionId: paymentTransactionId,
      );
      return result;
    } catch (e) {
      LoggerService.error('PaymentRepository: verifyUser', e);
      rethrow;
    }
  }

  /// Subscribe user (called after successful payment)
  Future<Map<String, dynamic>> subscribeUser({
    required String paymentTransactionId,
  }) async {
    try {
      final result = await _cloudFunctions.subscribeUser(
        paymentTransactionId: paymentTransactionId,
      );
      return result;
    } catch (e) {
      LoggerService.error('PaymentRepository: subscribeUser', e);
      rethrow;
    }
  }
}
