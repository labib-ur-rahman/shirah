import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/payment/payment_transaction_model.dart';
import 'package:shirah/data/repositories/payment_repository.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';
import 'package:uddoktapay/models/customer_model.dart';
import 'package:uddoktapay/models/request_response.dart';
import 'package:uddoktapay/uddoktapay.dart';

/// Verification Controller
/// Manages account verification and subscription purchase flow
/// Uses UddoktaPay for Bangladeshi local payment gateway
class VerificationController extends GetxController {
  static VerificationController get instance => Get.find();

  // ===== Repository =====
  final PaymentRepository _paymentRepo = PaymentRepository();

  // ===== Observable State =====
  final RxBool isLoading = false.obs;
  final RxBool isLoadingConfig = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool hasMoreHistory = true.obs;
  final RxList<PaymentTransactionModel> paymentHistory =
      <PaymentTransactionModel>[].obs;

  // ===== Payment Config =====
  final Rx<Map<String, dynamic>> paymentConfig = Rx<Map<String, dynamic>>({});

  // ===== Getters =====
  bool get isVerified =>
      UserController.instance.user.value?.status.verified ?? false;
  String get subscriptionStatus =>
      UserController.instance.user.value?.status.subscription ?? 'none';
  bool get isSubscribed => subscriptionStatus == 'active';
  double get verificationPrice =>
      (paymentConfig.value['verificationPrice'] as num?)?.toDouble() ?? 125.0;
  double get subscriptionPrice =>
      (paymentConfig.value['subscriptionPrice'] as num?)?.toDouble() ?? 500.0;
  String get uddoktaPayApiKey =>
      paymentConfig.value['apiKey']?.toString() ?? '';
  bool get hasConfig => uddoktaPayApiKey.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadPaymentConfig();
  }

  // ===== PAYMENT CONFIG =====

  /// Load payment configuration from Cloud Functions
  Future<void> loadPaymentConfig() async {
    try {
      isLoadingConfig.value = true;
      final config = await _paymentRepo.getPaymentConfig();
      paymentConfig.value = config;
      LoggerService.info('✅ Payment config loaded');
    } catch (e) {
      LoggerService.error('Failed to load payment config', e);
    } finally {
      isLoadingConfig.value = false;
    }
  }

  // ===== PURCHASE VERIFICATION =====

  /// Start verification purchase flow with UddoktaPay
  Future<void> purchaseVerification() async {
    if (isVerified) {
      AppSnackBar.showInfoSnackBar(
        title: AppStrings.verified,
        message: AppStrings.verificationAlreadyDone,
      );
      return;
    }

    if (!hasConfig) {
      await loadPaymentConfig();
      if (!hasConfig) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: AppStrings.paymentConfigError,
        );
        return;
      }
    }

    await _processPayment(type: 'verification', amount: verificationPrice);
  }

  // ===== PURCHASE SUBSCRIPTION =====

  /// Start subscription purchase flow with UddoktaPay
  Future<void> purchaseSubscription() async {
    if (!isVerified) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.verifyAccount,
        message: AppStrings.verifyFirst,
      );
      return;
    }

    if (isSubscribed) {
      AppSnackBar.showInfoSnackBar(
        title: AppStrings.subscribed,
        message: AppStrings.subscriptionAlreadyActive,
      );
      return;
    }

    if (!hasConfig) {
      await loadPaymentConfig();
      if (!hasConfig) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: AppStrings.paymentConfigError,
        );
        return;
      }
    }

    await _processPayment(type: 'subscription', amount: subscriptionPrice);
  }

  // ===== CORE PAYMENT FLOW =====

  /// Process payment via UddoktaPay SDK
  Future<void> _processPayment({
    required String type,
    required double amount,
  }) async {
    try {
      isLoading.value = true;

      final user = UserController.instance.user.value;
      if (user == null) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: AppStrings.somethingWentWrong,
        );
        return;
      }

      final fullName = '${user.identity.firstName} ${user.identity.lastName}'
          .trim();
      final email = user.identity.email.isNotEmpty
          ? user.identity.email
          : 'user@shirah.app';

      // Initialize UddoktaPay customer
      final customerDetails = CustomerDetails(
        fullName: fullName.isEmpty ? 'Shirah User' : fullName,
        email: email,
      );

      EasyLoading.show(status: AppStrings.processingPayment);

      // Launch UddoktaPay payment page
      final result = await UddoktaPay.createPayment(
        context: Get.context!,
        customer: customerDetails,
        amount: amount.toString(),
      );

      EasyLoading.dismiss();

      if (result.status == ResponseStatus.completed) {
        // Payment completed — send to Cloud Function for processing
        await _handlePaymentSuccess(type: type, paymentResult: result);
      } else if (result.status == ResponseStatus.pending) {
        // Payment pending — create transaction record
        await _handlePaymentPending(type: type, paymentResult: result);
      } else {
        // Payment failed or cancelled
        _handlePaymentFailure(result);
      }
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Payment processing error', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.paymentFailed,
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle successful payment from UddoktaPay
  Future<void> _handlePaymentSuccess({
    required String type,
    required RequestResponse paymentResult,
  }) async {
    try {
      EasyLoading.show(status: AppStrings.verificationProcessing);

      // Create payment transaction record in Firestore via Cloud Function
      final txResult = await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: paymentResult.toJson(),
      );

      EasyLoading.dismiss();

      final transactionId = txResult['transactionId']?.toString() ?? '';

      if (txResult['processed'] == true) {
        // Already auto-processed by Cloud Function
        AppSnackBar.successSnackBar(
          title: AppStrings.success,
          message: type == 'verification'
              ? AppStrings.verificationSuccess
              : AppStrings.subscriptionSuccess,
        );
        // Refresh user data
        UserController.instance.refreshUser();
      } else if (transactionId.isNotEmpty) {
        // Transaction created but needs processing
        AppSnackBar.showInfoSnackBar(
          title: AppStrings.paymentSuccessful,
          message: AppStrings.paymentBeingProcessed,
        );
      }

      // Refresh payment history
      loadPaymentHistory();
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Error handling payment success', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    }
  }

  /// Handle pending payment from UddoktaPay
  Future<void> _handlePaymentPending({
    required String type,
    required RequestResponse paymentResult,
  }) async {
    try {
      // Create payment transaction with pending status
      await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: paymentResult.toJson(),
      );

      AppSnackBar.warningSnackBar(
        title: AppStrings.verificationPending,
        message: AppStrings.paymentPendingMessage,
      );

      // Refresh payment history
      loadPaymentHistory();
    } catch (e) {
      LoggerService.error('Error handling pending payment', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    }
  }

  /// Handle failed/cancelled payment
  void _handlePaymentFailure(RequestResponse paymentResult) {
    if (paymentResult.status == ResponseStatus.canceled) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.paymentCancelled,
        message: AppStrings.paymentCancelledMessage,
      );
    } else {
      AppSnackBar.errorSnackBar(
        title: AppStrings.paymentFailed,
        message: AppStrings.paymentFailedMessage,
      );
    }
  }

  // ===== PAYMENT HISTORY =====

  /// Load user's payment history
  Future<void> loadPaymentHistory({bool refresh = false}) async {
    if (isLoadingHistory.value && !refresh) return;

    try {
      isLoadingHistory.value = true;

      if (refresh) {
        paymentHistory.clear();
        hasMoreHistory.value = true;
      }

      final lastId = paymentHistory.isNotEmpty && !refresh
          ? paymentHistory.last.id
          : null;

      final transactions = await _paymentRepo.getPaymentHistory(
        limit: 20,
        startAfter: lastId,
      );

      if (transactions.length < 20) {
        hasMoreHistory.value = false;
      }

      if (refresh) {
        paymentHistory.assignAll(transactions);
      } else {
        paymentHistory.addAll(transactions);
      }
    } catch (e) {
      LoggerService.error('Failed to load payment history', e);
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// Get status color for UI
  Color getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.canceled:
        return Colors.grey;
      case PaymentStatus.failed:
        return Colors.red;
    }
  }

  /// Get status icon for UI
  IconData getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.access_time;
      case PaymentStatus.canceled:
        return Icons.cancel;
      case PaymentStatus.failed:
        return Icons.error;
    }
  }
}
