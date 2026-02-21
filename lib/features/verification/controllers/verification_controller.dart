import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/payment/payment_transaction_model.dart';
import 'package:shirah/data/repositories/payment_repository.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';
import 'package:shirah/features/verification/views/widgets/payment_result_dialog.dart';
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

  /// Holds the last error message if config loading failed (for debugging)
  final RxnString configError = RxnString(null);

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
  String get uddoktaPayWebhookURL =>
      paymentConfig.value['webhookURL']?.toString() ?? '';

  // Prices — CF returns verificationPriceBDT / subscriptionPriceBDT
  double get verificationPrice =>
      (paymentConfig.value['verificationPriceBDT'] as num?)?.toDouble() ??
      250.0;
  double get subscriptionPrice =>
      (paymentConfig.value['subscriptionPriceBDT'] as num?)?.toDouble() ??
      400.0;

  // Config is ready when we have the essential credentials for the SDK
  bool get hasConfig =>
      paymentConfig.value.isNotEmpty &&
      uddoktaPayApiKey.isNotEmpty &&
      uddoktaPayPanelURL.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadPaymentConfig();
  }

  // ===== PAYMENT CONFIG =====

  /// Load payment configuration from Cloud Functions.
  /// Returns `true` if config loaded successfully, `false` otherwise.
  /// On failure, stores the error in [configError] so callers can surface it.
  Future<bool> loadPaymentConfig() async {
    try {
      isLoadingConfig.value = true;
      configError.value = null;

      final response = await _paymentRepo.getPaymentConfig();
      // CF returns { success, message, data: { isSandbox, apiKey, panelURL, ... } }
      // Firebase nested maps come back as Map<Object?, Object?> — must convert explicitly
      final rawData = response['data'];
      final data = rawData != null
          ? Map<String, dynamic>.from(rawData as Map)
          : <String, dynamic>{};
      paymentConfig.value = data;

      LoggerService.info(
        '✅ Payment config loaded: sandbox=${data['isSandbox']}, '
        'hasApiKey=${(data['apiKey']?.toString() ?? '').isNotEmpty}, '
        'panelURL=${data['panelURL']}',
      );
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      configError.value = errorMsg;
      LoggerService.error('Failed to load payment config', e);
      return false;
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
      final configLoaded = await loadPaymentConfig();

      if (!configLoaded || !hasConfig) {
        // Show the actual error to the user so we know WHY it failed.
        final detail = configError.value;
        final msg = detail != null && detail.isNotEmpty
            ? '${AppStrings.paymentConfigError}\n\n$detail'
            : AppStrings.paymentConfigError;

        LoggerService.error(
          '💳 Config check failed: configLoaded=$configLoaded, '
          'hasConfig=$hasConfig, isSandbox=$isSandboxMode, '
          'apiKey=${uddoktaPayApiKey.isNotEmpty}, configError=$detail',
        );

        AppSnackBar.errorSnackBar(title: AppStrings.error, message: msg);
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
        fullName: fullName.isEmpty ? 'SHIRAH User' : fullName,
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

      // === ALWAYS pass credentials to UddoktaPay SDK (both sandbox & production) ===
      //
      // WHY: The SDK's sandbox fallback (credentials=null) uses hardcoded
      // 'programmingwormhole.com' for redirect/cancel URLs. That domain shows
      // "Forbidden" and breaks the WebView intercept. By ALWAYS providing
      // credentials we control ALL URLs ourselves.
      //
      // CRITICAL — redirectURL MUST be domain-only (no scheme):
      //   The SDK's WebView intercept checks: uri.host.contains(redirectURL)
      //   uri.host never includes the scheme, so passing
      //   'https://domain.com' will ALWAYS fail the match.
      //   Correct: 'shirahsoft.paymently.io'  Wrong: 'https://shirahsoft.paymently.io'
      //
      // CRITICAL — panelURL MUST be base domain with trailing slash:
      //   The SDK appends '/api/checkout-v2' internally to panelURL.
      //   panelURL = 'https://domain.io/'  → API = 'https://domain.io//api/checkout-v2' (OK)
      //   panelURL = 'https://domain.io/api/checkout-v2' → DOUBLED path (404 error)
      //   The SDK also builds cancel_url as '${panelURL}checkout/cancel',
      //   so trailing slash is required to produce '/checkout/cancel'.

      // Strip scheme and trailing slashes from redirectURL — must be domain-only
      String redirectURL = uddoktaPayRedirectURL
          .replaceAll(RegExp(r'^https?://'), '')
          .replaceAll(RegExp(r'/+$'), '');

      // Fallback for empty redirectURL (e.g. sandbox config)
      if (redirectURL.isEmpty) {
        redirectURL = 'shirahsoft.paymently.io';
      }

      LoggerService.info(
        '💳 ${sandboxMode ? "SANDBOX" : "PRODUCTION"} credentials | '
        'panelURL: $uddoktaPayPanelURL | redirectURL: $redirectURL',
      );

      // Build webhook URL for UddoktaPay IPN (auto-approve pending payments)
      final webhookUrl = uddoktaPayWebhookURL.isNotEmpty
          ? uddoktaPayWebhookURL
          : null;

      late final RequestResponse result;
      result = await UddoktaPay.createPayment(
        context: Get.context!,
        customer: customerDetails,
        amount: amount.toStringAsFixed(2),
        metadata: {'payment_type': type, 'uid': user.uid},
        credentials: UddoktapayCredentials(
          apiKey: uddoktaPayApiKey,
          panelURL: uddoktaPayPanelURL,
          redirectURL: redirectURL,
          webhookUrl: webhookUrl,
        ),
      );

      LoggerService.info('💳 Payment WebView result: ${result.status}');

      if (result.status == ResponseStatus.completed) {
        await _handlePaymentSuccess(type: type, paymentResult: result);
      } else if (result.status == ResponseStatus.pending) {
        await _handlePaymentPending(type: type, paymentResult: result);
      } else {
        await _handlePaymentFailure(result, type: type, amount: amount);
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
      // IMPORTANT: The UddoktaPay SDK's toJson() uses snake_case keys
      // (e.g. "full_name", "invoice_id") but the Cloud Function expects
      // camelCase keys (e.g. "fullName", "invoiceId"). We must map them.
      final payload = _buildCamelCasePayload(paymentResult);

      final txResult = await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: payload,
      );

      EasyLoading.dismiss();

      // CF returns { success: bool, message: String, data: { ... } }
      final success = txResult['success'] as bool? ?? false;

      if (success) {
        // Refresh user so UI reflects new verified/subscribed state
        await UserController.instance.refreshUser();

        // Show premium success dialog with user profile info
        await PaymentResultDialog.show(
          type: PaymentResultType.success,
          paymentType: type,
          title: type == 'verification'
              ? AppStrings.paymentResultVerifiedTitle
              : AppStrings.paymentResultSubscribedTitle,
          message: type == 'verification'
              ? AppStrings.paymentResultVerifiedMessage
              : AppStrings.paymentResultSubscribedMessage,
          transactionId: paymentResult.invoiceId,
          amount: paymentResult.amount,
          paymentMethod: paymentResult.paymentMethod,
          onPrimaryAction: () => Get.back(),
        );
      } else {
        // CF returned success: false (should be rare)
        await PaymentResultDialog.show(
          type: PaymentResultType.pending,
          paymentType: type,
          title: AppStrings.paymentSuccessful,
          message: AppStrings.paymentBeingProcessed,
          transactionId: paymentResult.invoiceId,
          onPrimaryAction: () => Get.back(),
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
      EasyLoading.show(status: AppStrings.verificationProcessing);

      final payload = _buildCamelCasePayload(paymentResult);

      final txResult = await _paymentRepo.createPaymentTransaction(
        type: type,
        uddoktapayResponse: payload,
      );

      EasyLoading.dismiss();

      // Extract paymentTransactionId for re-verify
      final data = txResult['data'] as Map?;
      final paymentTxId = data?['paymentTransactionId']?.toString() ?? '';

      // Show pending result dialog with "Check Status" button
      await PaymentResultDialog.show(
        type: PaymentResultType.pending,
        paymentType: type,
        title: AppStrings.paymentResultPendingTitle,
        message: AppStrings.paymentResultPendingMessage,
        transactionId: paymentResult.invoiceId,
        amount: paymentResult.amount,
        onPrimaryAction: paymentTxId.isNotEmpty
            ? () => _checkPendingPaymentStatus(paymentTxId, type)
            : () => Get.back(),
        primaryActionText: paymentTxId.isNotEmpty
            ? AppStrings.paymentResultCheckStatus
            : null,
        onRetry: null,
      );

      // Refresh payment history
      loadPaymentHistory();
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Error handling pending payment', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    }
  }

  /// Re-verify a pending payment by calling UddoktaPay verify API server-side.
  ///
  /// Called when user taps "Check Status" on the pending dialog.
  /// If UddoktaPay now says COMPLETED → auto-processes and shows success.
  /// If still PENDING → shows info snackbar.
  Future<void> _checkPendingPaymentStatus(
    String paymentTransactionId,
    String type,
  ) async {
    try {
      // Close the pending dialog first
      Get.back();

      EasyLoading.show(status: AppStrings.paymentCheckingStatus);

      final result = await _paymentRepo.reVerifyPendingPayment(
        paymentTransactionId: paymentTransactionId,
      );

      EasyLoading.dismiss();

      final success = result['success'] as bool? ?? false;
      final data = result['data'] as Map?;
      final status = data?['status']?.toString() ?? '';
      final message = result['message']?.toString() ?? '';

      if (success && status == 'COMPLETED') {
        // Payment is now completed! Refresh user and show success
        await UserController.instance.refreshUser();

        await PaymentResultDialog.show(
          type: PaymentResultType.success,
          paymentType: type,
          title: type == 'verification'
              ? AppStrings.paymentResultVerifiedTitle
              : AppStrings.paymentResultSubscribedTitle,
          message: type == 'verification'
              ? AppStrings.paymentResultVerifiedMessage
              : AppStrings.paymentResultSubscribedMessage,
          onPrimaryAction: () => Get.back(),
        );
      } else if (status == 'PENDING') {
        // Still pending — show the pending dialog again with check status
        AppSnackBar.showInfoSnackBar(
          title: AppStrings.pending,
          message: AppStrings.paymentStillPending,
        );

        // Re-show pending dialog
        await PaymentResultDialog.show(
          type: PaymentResultType.pending,
          paymentType: type,
          title: AppStrings.paymentResultPendingTitle,
          message: AppStrings.paymentStillPending,
          onPrimaryAction: () =>
              _checkPendingPaymentStatus(paymentTransactionId, type),
          primaryActionText: AppStrings.paymentResultCheckStatus,
        );
      } else {
        // Failed or other status
        AppSnackBar.warningSnackBar(
          title: AppStrings.paymentFailed,
          message: message,
        );
      }

      // Refresh history
      loadPaymentHistory();
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Error checking pending payment status', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.error,
        message: AppStrings.paymentStatusCheckFailed,
      );
    }
  }

  /// Handle failed/cancelled payment — show result dialog with working retry.
  ///
  /// The `onRetry` callback closes the dialog and re-invokes the full payment
  /// flow (`_processPayment`) so the user can try again without navigating away.
  Future<void> _handlePaymentFailure(
    RequestResponse paymentResult, {
    required String type,
    required double amount,
  }) async {
    if (paymentResult.status == ResponseStatus.canceled) {
      await PaymentResultDialog.show(
        type: PaymentResultType.cancelled,
        title: AppStrings.paymentCancelled,
        message: AppStrings.paymentResultCancelledMessage,
        onRetry: () => _processPayment(type: type, amount: amount),
      );
    } else {
      await PaymentResultDialog.show(
        type: PaymentResultType.failed,
        title: AppStrings.paymentFailed,
        message: AppStrings.paymentResultFailedMessage,
        onRetry: () => _processPayment(type: type, amount: amount),
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

  /// Build a camelCase-keyed map from the UddoktaPay SDK response.
  ///
  /// The SDK's `toJson()` uses snake_case (e.g. `full_name`, `invoice_id`),
  /// but the Cloud Function expects camelCase (e.g. `fullName`, `invoiceId`).
  /// This helper also converts the ResponseStatus enum to a plain string.
  Map<String, dynamic> _buildCamelCasePayload(RequestResponse result) {
    return {
      'fullName': result.fullName ?? '',
      'email': result.email ?? '',
      'amount': result.amount ?? '0.00',
      'fee': result.fee ?? '0.00',
      'chargedAmount': result.chargedAmount ?? '0.00',
      'invoiceId': result.invoiceId ?? '',
      'paymentMethod': result.paymentMethod ?? '',
      'senderNumber': result.senderNumber ?? '',
      'transactionId': result.transactionId ?? '',
      'date': result.date?.toIso8601String() ?? '',
      'status': _responseStatusToString(result.status),
    };
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
        return Iconsax.tick_circle;
      case PaymentStatus.pending:
        return Iconsax.clock;
      case PaymentStatus.canceled:
        return Iconsax.close_circle;
      case PaymentStatus.failed:
        return Iconsax.warning_2;
    }
  }
}
