import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/payment/payment_transaction_model.dart';
import 'package:shirah/data/repositories/payment_repository.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';
import 'package:uddoktapay/models/credentials.dart';
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
  // Stores the 'data' sub-map from the getPaymentConfig Cloud Function response
  final Rx<Map<String, dynamic>> paymentConfig = Rx<Map<String, dynamic>>({});

  // ===== Getters =====
  bool get isVerified =>
      UserController.instance.user.value?.status.verified ?? false;
  String get subscriptionStatus =>
      UserController.instance.user.value?.status.subscription ?? 'none';
  bool get isSubscribed => subscriptionStatus == 'active';

  // UddoktaPay config — reads directly from the stored data map
  bool get isSandboxMode => (paymentConfig.value['isSandbox'] as bool?) ?? true;
  String get uddoktaPayApiKey =>
      paymentConfig.value['apiKey']?.toString() ?? '';
  String get uddoktaPayPanelURL =>
      paymentConfig.value['panelURL']?.toString() ?? '';
  String get uddoktaPayRedirectURL =>
      paymentConfig.value['redirectURL']?.toString() ?? '';

  // Prices — CF returns verificationPriceBDT / subscriptionPriceBDT
  double get verificationPrice =>
      (paymentConfig.value['verificationPriceBDT'] as num?)?.toDouble() ??
      250.0;
  double get subscriptionPrice =>
      (paymentConfig.value['subscriptionPriceBDT'] as num?)?.toDouble() ??
      400.0;

  // Config is ready if: sandbox mode (no key needed by SDK), OR we have an API key
  bool get hasConfig =>
      paymentConfig.value.isNotEmpty &&
      (isSandboxMode || uddoktaPayApiKey.isNotEmpty);

  @override
  void onInit() {
    super.onInit();
    loadPaymentConfig();
  }

  // ===== PAYMENT CONFIG =====

  /// Load payment configuration from Cloud Functions
  /// Unwraps the 'data' sub-map so getters can access fields directly.
  Future<void> loadPaymentConfig() async {
    try {
      isLoadingConfig.value = true;
      final response = await _paymentRepo.getPaymentConfig();
      // CF returns { success, message, data: { isSandbox, apiKey, panelURL, ... } }
      // Firebase nested maps come back as Map<Object?, Object?> — must convert explicitly
      final rawData = response['data'];
      final data = rawData != null
          ? Map<String, dynamic>.from(rawData as Map)
          : <String, dynamic>{};
      paymentConfig.value = data;
      LoggerService.info(
        '✅ Payment config loaded: sandbox=${data['isSandbox']}',
      );
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
    await _processPayment(type: 'verification', amount: verificationPrice);
  }

  // ===== PURCHASE SUBSCRIPTION =====

  /// Start subscription purchase flow with UddoktaPay
  /// Subscription auto-verifies the account — user can subscribe directly
  /// without purchasing verification separately.
  Future<void> purchaseSubscription() async {
    if (isSubscribed) {
      AppSnackBar.showInfoSnackBar(
        title: AppStrings.subscribed,
        message: AppStrings.subscriptionAlreadyActive,
      );
      return;
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

      // Always fetch fresh config so isSandbox / keys are current.
      // Do NOT rely on the cached observable — config may have changed in Firestore.
      await loadPaymentConfig();

      if (!hasConfig) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: AppStrings.paymentConfigError,
        );
        return;
      }

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

      final customerDetails = CustomerDetails(
        fullName: fullName.isEmpty ? 'Shirah User' : fullName,
        email: email,
      );

      // Snapshot the mode AFTER fresh config is loaded
      final sandboxMode = isSandboxMode;
      LoggerService.info(
        '💳 Payment mode: ${sandboxMode ? "SANDBOX" : "PRODUCTION"} | '
        'type: $type | amount: $amount',
      );

      // ⚠️ Do NOT show EasyLoading before UddoktaPay.createPayment().
      // The loading overlay would cover the payment WebView.
      // Loading is shown AFTER the WebView closes (during CF processing).
      late final RequestResponse result;
      if (sandboxMode) {
        // Sandbox: SDK uses built-in endpoint + redirect URL — no credentials needed
        result = await UddoktaPay.createPayment(
          context: Get.context!,
          customer: customerDetails,
          amount: amount.toStringAsFixed(2),
        );
      } else {
        // Production: must pass credentials fetched from Firestore config.
        // redirectURL must start with https:// so the SDK can intercept it in WebView.
        final rawRedirect = uddoktaPayRedirectURL;
        final redirectURL = rawRedirect.startsWith('http')
            ? rawRedirect
            : 'https://$rawRedirect';

        LoggerService.info(
          '💳 Production credentials | panelURL: $uddoktaPayPanelURL | '
          'redirectURL: $redirectURL',
        );

        result = await UddoktaPay.createPayment(
          context: Get.context!,
          customer: customerDetails,
          amount: amount.toStringAsFixed(2),
          credentials: UddoktapayCredentials(
            apiKey: uddoktaPayApiKey,
            panelURL: uddoktaPayPanelURL,
            redirectURL: redirectURL,
          ),
        );
      }

      LoggerService.info('💳 Payment WebView result: ${result.status}');

      if (result.status == ResponseStatus.completed) {
        await _handlePaymentSuccess(type: type, paymentResult: result);
      } else if (result.status == ResponseStatus.pending) {
        await _handlePaymentPending(type: type, paymentResult: result);
      } else {
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
      EasyLoading.dismiss(); // safety fallback
    }
  }

  /// Handle successful payment from UddoktaPay
  /// Called after the WebView closes with status = completed.
  /// Sends the UddoktaPay response to Cloud Functions which:
  ///   1. Stores the payment in Firestore (payment_transactions)
  ///   2. Sets user.status.verified = true  (for verification)
  ///   3. Sets user.status.subscription = 'active' (for subscription)
  ///   4. Distributes commission Reward Points to upline chain
  Future<void> _handlePaymentSuccess({
    required String type,
    required RequestResponse paymentResult,
  }) async {
    try {
      // Show loading NOW (WebView is already closed)
      EasyLoading.show(status: AppStrings.verificationProcessing);

      LoggerService.info(
        '💳 Sending payment to Cloud Function | invoiceId: ${paymentResult.invoiceId}',
      );

      // createPaymentTransaction CF:
      //  - validates & stores payment_transactions doc
      //  - calls processVerification / processSubscription
      //  - distributes commission to uplines
      //  - returns { success: true, data: { verified, subscribed } }
      //
      // IMPORTANT: paymentResult.toJson() serializes 'status' as a Dart enum
      // (e.g. ResponseStatus.completed) which the Cloud Function cannot parse.
      // We must override it with the plain string value the CF expects.
      final payload = Map<String, dynamic>.from(paymentResult.toJson())
        ..['status'] = _responseStatusToString(paymentResult.status);

      final txResult = await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: payload,
      );

      EasyLoading.dismiss();

      // CF returns { success: bool, message: String, data: { ... } }
      final success = txResult['success'] as bool? ?? false;

      if (success) {
        AppSnackBar.successSnackBar(
          title: AppStrings.success,
          message: type == 'verification'
              ? AppStrings.verificationSuccess
              : AppStrings.subscriptionSuccess,
        );
        // Refresh user so UI reflects new verified/subscribed state
        await UserController.instance.refreshUser();
      } else {
        // CF returned success: false (should be rare)
        AppSnackBar.showInfoSnackBar(
          title: AppStrings.paymentSuccessful,
          message: AppStrings.paymentBeingProcessed,
        );
      }

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
      final payload = Map<String, dynamic>.from(paymentResult.toJson())
        ..['status'] = _responseStatusToString(paymentResult.status);

      await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: payload,
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

  /// Convert ResponseStatus enum to the string value expected by Cloud Functions.
  /// The UddoktaPay Dart SDK uses enums internally but CF expects plain strings.
  String _responseStatusToString(ResponseStatus? status) {
    switch (status) {
      case ResponseStatus.completed:
        return 'COMPLETED';
      case ResponseStatus.pending:
        return 'PENDING';
      case ResponseStatus.canceled:
        return 'CANCELED';
      default:
        return 'ERROR';
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
