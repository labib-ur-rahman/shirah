import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/recharge/drive_offer_model.dart';
import 'package:shirah/data/models/recharge/recharge_model.dart';
import 'package:shirah/data/repositories/mobile_recharge_repository.dart';

/// Mobile Recharge Controller - Manages recharge and drive offer flows
/// Handles phone input, operator selection, amount, offer browsing, and history
class MobileRechargeController extends GetxController {
  static MobileRechargeController get instance => Get.find();

  // ==================== Dependencies ====================
  final MobileRechargeRepository _repository =
      MobileRechargeRepository.instance;

  // ==================== Recharge Screen State ====================
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final RxString selectedOperator = ''.obs;
  final RxString selectedNumberType = '1'.obs; // 1=Prepaid, 2=Postpaid
  final RxBool isProcessing = false.obs;
  final Rx<RechargeModel?> lastResult = Rx<RechargeModel?>(null);
  final RxString selectedAmount =
      ''.obs; // Reactive variable for amount selector

  // ==================== History State ====================
  final RxList<RechargeModel> rechargeHistory = <RechargeModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool hasMoreHistory = true.obs;

  // ==================== Drive Offers State ====================
  final RxList<DriveOfferModel> driveOffers = <DriveOfferModel>[].obs;
  final RxBool isLoadingOffers = false.obs;
  final RxString selectedOfferOperator = ''.obs;
  final RxString selectedOfferType = ''.obs;

  // ==================== Operator Definitions ====================
  static const List<Map<String, String>> operators = [
    {'code': '1', 'name': 'Grameenphone', 'short': 'GP', 'prefix': '017,013'},
    {'code': '4', 'name': 'Banglalink', 'short': 'BL', 'prefix': '019,014'},
    {'code': '2', 'name': 'Robi', 'short': 'RB', 'prefix': '018'},
    {'code': '3', 'name': 'Airtel', 'short': 'AR', 'prefix': '016'},
    {'code': '5', 'name': 'Teletalk', 'short': 'TL', 'prefix': '015'},
  ];

  // ==================== Quick Amount Options ====================
  static const List<int> quickAmounts = [20, 30, 50, 100, 200, 300, 500, 1000];

  // ==================== Offer Types ====================
  static const List<Map<String, String>> offerTypes = [
    {'value': '', 'label': 'All'},
    {'value': 'Internet', 'label': 'Internet'},
    {'value': 'Minute', 'label': 'Minutes'},
    {'value': 'Combo', 'label': 'Combo'},
    {'value': 'Bundle', 'label': 'Bundle'},
    {'value': 'SMS', 'label': 'SMS'},
  ];

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    // Auto-detect operator when phone number changes
    phoneController.addListener(_onPhoneChanged);
    // Update reactive variable when amount changes
    amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    selectedAmount.value = amountController.text;
  }

  @override
  void onClose() {
    phoneController.dispose();
    amountController.dispose();
    super.onClose();
  }

  // ==================== PHONE & OPERATOR ====================

  void _onPhoneChanged() {
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length >= 3) {
      final prefix = phone.substring(0, 3);
      final detected = _detectOperator(prefix);
      if (detected != null && selectedOperator.value != detected) {
        selectedOperator.value = detected;
      }
    }
  }

  String? _detectOperator(String prefix) {
    const prefixMap = {
      '017': '1', '013': '1', // GP
      '019': '4', '014': '4', // BL
      '018': '2', // Robi
      '016': '3', // Airtel
      '015': '5', // Teletalk
    };
    return prefixMap[prefix];
  }

  void selectOperator(String code) {
    selectedOperator.value = code;
  }

  void selectNumberType(String type) {
    selectedNumberType.value = type;
  }

  void selectQuickAmount(int amount) {
    amountController.text = amount.toString();
  }

  String get operatorName {
    final op = operators.firstWhereOrNull(
      (o) => o['code'] == selectedOperator.value,
    );
    return op?['name'] ?? '';
  }

  bool get isFormValid {
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final amount = double.tryParse(amountController.text) ?? 0;
    return phone.length == 11 &&
        phone.startsWith('01') &&
        selectedOperator.isNotEmpty &&
        amount >= 20 &&
        amount <= 5000 &&
        amount % 10 == 0;
  }

  String? get phoneError {
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return null;
    if (phone.length < 11) return 'Enter 11-digit number';
    if (!phone.startsWith('01')) return 'Must start with 01';
    return null;
  }

  String? get amountError {
    final text = amountController.text;
    if (text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null) return 'Invalid amount';
    if (amount < 20) return 'Minimum ৳20';
    if (amount > 5000) return 'Maximum ৳5,000';
    if (amount % 10 != 0) return 'Must end in 0';
    return null;
  }

  // ==================== INITIATE RECHARGE ====================

  Future<void> initiateRecharge() async {
    if (!isFormValid) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.rechargeFailed,
        message: 'Please fill all fields correctly',
      );
      return;
    }

    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final amount = double.parse(amountController.text);

    try {
      isProcessing.value = true;
      EasyLoading.show(status: 'Processing recharge...');

      final result = await _repository.initiateRecharge(
        phone: phone,
        operator: selectedOperator.value,
        numberType: selectedNumberType.value,
        amount: amount,
        type: 'recharge',
      );

      EasyLoading.dismiss();

      final success = result['success'] == true;
      final message = result['message'] as String? ?? '';
      final data = result['data'] as Map<String, dynamic>?;

      if (success) {
        final cashback = data?['cashback'] as num?;
        AppSnackBar.successSnackBar(
          title: AppStrings.rechargeSuccess,
          message: cashback != null
              ? '$message Cashback: ৳${cashback.toStringAsFixed(2)}'
              : message,
        );
        // Clear form
        _clearForm();
        // Refresh history
        fetchRechargeHistory();
      } else {
        AppSnackBar.errorSnackBar(
          title: AppStrings.rechargeFailed,
          message: message,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Recharge failed', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.rechargeFailed,
        message: e.toString(),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // ==================== DRIVE OFFER PURCHASE ====================

  Future<void> purchaseDriveOffer({
    required String phone,
    required DriveOfferModel offer,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 11 || !cleanPhone.startsWith('01')) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.rechargeFailed,
        message: 'Please enter a valid phone number',
      );
      return;
    }

    try {
      isProcessing.value = true;
      EasyLoading.show(status: 'Activating offer...');

      final result = await _repository.initiateRecharge(
        phone: cleanPhone,
        operator: offer.numericOperatorCode,
        numberType: offer.numberType,
        amount: offer.amount,
        type: 'drive_offer',
        offerDetails: offer.toOfferDetailsMap(),
      );

      EasyLoading.dismiss();

      final success = result['success'] == true;
      final message = result['message'] as String? ?? '';

      if (success) {
        AppSnackBar.successSnackBar(
          title: AppStrings.rechargeSuccess,
          message: message,
        );
      } else {
        AppSnackBar.errorSnackBar(
          title: AppStrings.rechargeFailed,
          message: message,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Drive offer purchase failed', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.rechargeFailed,
        message: e.toString(),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // ==================== RECHARGE HISTORY ====================

  Future<void> fetchRechargeHistory() async {
    try {
      isLoadingHistory.value = true;
      hasMoreHistory.value = true;

      final history = await _repository.getRechargeHistory(limit: 20);
      rechargeHistory.assignAll(history);

      if (history.length < 20) hasMoreHistory.value = false;
    } catch (e) {
      LoggerService.error('Failed to fetch recharge history', e);
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingHistory.value || !hasMoreHistory.value) return;
    if (rechargeHistory.isEmpty) return;

    try {
      isLoadingHistory.value = true;

      final lastRefid = rechargeHistory.last.refid;
      final moreHistory = await _repository.getRechargeHistory(
        limit: 20,
        startAfter: lastRefid,
      );

      if (moreHistory.length < 20) hasMoreHistory.value = false;
      rechargeHistory.addAll(moreHistory);
    } catch (e) {
      LoggerService.error('Failed to load more history', e);
    } finally {
      isLoadingHistory.value = false;
    }
  }

  // ==================== DRIVE OFFERS ====================

  Future<void> fetchDriveOffers() async {
    try {
      isLoadingOffers.value = true;

      final offers = await _repository.getDriveOffers(
        operator: selectedOfferOperator.value.isNotEmpty
            ? selectedOfferOperator.value
            : null,
        offerType: selectedOfferType.value.isNotEmpty
            ? selectedOfferType.value
            : null,
      );

      driveOffers.assignAll(offers);
    } catch (e) {
      LoggerService.error('Failed to fetch drive offers', e);
    } finally {
      isLoadingOffers.value = false;
    }
  }

  void filterOffersByOperator(String operator) {
    selectedOfferOperator.value = operator;
    fetchDriveOffers();
  }

  void filterOffersByType(String type) {
    selectedOfferType.value = type;
    fetchDriveOffers();
  }

  void clearOfferFilters() {
    selectedOfferOperator.value = '';
    selectedOfferType.value = '';
    fetchDriveOffers();
  }

  // ==================== HELPERS ====================

  void _clearForm() {
    phoneController.clear();
    amountController.clear();
    selectedOperator.value = '';
    selectedNumberType.value = '1';
  }

  void resetAll() {
    _clearForm();
    rechargeHistory.clear();
    driveOffers.clear();
  }
}
