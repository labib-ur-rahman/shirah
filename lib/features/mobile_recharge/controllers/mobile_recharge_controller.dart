import 'dart:async';

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
/// Handles phone input, operator selection, amount, offer browsing,
/// instant offer detection, and recharge history
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
  final RxString selectedAmount = ''.obs;

  // ==================== Instant Offer Detection State ====================
  final RxList<DriveOfferModel> matchedOffers = <DriveOfferModel>[].obs;
  final RxBool isSearchingOffers = false.obs;
  final RxBool useOfferPack = false.obs;
  Timer? _searchDebouncer;

  // ==================== History State ====================
  final RxList<RechargeModel> rechargeHistory = <RechargeModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool hasMoreHistory = true.obs;

  // ==================== Drive Offers State ====================
  final RxList<DriveOfferModel> driveOffers = <DriveOfferModel>[].obs;
  final RxBool isLoadingOffers = false.obs;
  final RxString selectedOfferOperator = ''.obs;
  final RxString selectedOfferType = ''.obs;
  final RxString selectedOfferValidity = ''.obs;

  // ==================== Operator Definitions ====================
  /// Operator codes match ECARE API recharge codes
  static const List<Map<String, String>> operators = [
    {'code': '7', 'name': 'Grameenphone', 'short': 'GP', 'prefix': '017,013'},
    {'code': '4', 'name': 'Banglalink', 'short': 'BL', 'prefix': '019,014'},
    {'code': '8', 'name': 'Robi', 'short': 'RB', 'prefix': '018'},
    {'code': '6', 'name': 'Airtel', 'short': 'AR', 'prefix': '016'},
    {'code': '5', 'name': 'Teletalk', 'short': 'TL', 'prefix': '015'},
  ];

  /// Recharge code → Offer operator letter mapping
  static const Map<String, String> codeToLetterMap = {
    '7': 'GP',
    '4': 'BL',
    '8': 'RB',
    '6': 'AR',
    '5': 'TL',
  };

  // ==================== Quick Amount Options ====================
  static const List<int> quickAmounts = [
    20,
    30,
    40,
    50,
    100,
    150,
    200,
    300,
    400,
    500,
  ];

  // ==================== Offer Types ====================
  static const List<Map<String, String>> offerTypes = [
    {'value': '', 'label': 'All'},
    {'value': 'IN', 'label': 'Internet'},
    {'value': 'MN', 'label': 'Minutes'},
    {'value': 'BD', 'label': 'Bundle'},
  ];

  // ==================== Lifecycle ====================

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_onPhoneChanged);
    amountController.addListener(_onAmountChanged);
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
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
        _debouncedOfferSearch();
      }
    }
  }

  void _onAmountChanged() {
    selectedAmount.value = amountController.text;
    _debouncedOfferSearch();
  }

  String? _detectOperator(String prefix) {
    const prefixMap = {
      '017': '7', '013': '7', // GP
      '019': '4', '014': '4', // BL
      '018': '8', // Robi
      '016': '6', // Airtel
      '015': '5', // Teletalk
    };
    return prefixMap[prefix];
  }

  void selectOperator(String code) {
    selectedOperator.value = code;
    _debouncedOfferSearch();
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

  String get operatorShort {
    final op = operators.firstWhereOrNull(
      (o) => o['code'] == selectedOperator.value,
    );
    return op?['short'] ?? '';
  }

  /// Get the offer operator letter code (GP, BL, etc.) from numeric code
  String get offerOperatorCode {
    return codeToLetterMap[selectedOperator.value] ?? '';
  }

  bool get isFormValid {
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final amount = double.tryParse(amountController.text) ?? 0;

    if (phone.length != 11 || !phone.startsWith('01')) return false;
    if (selectedOperator.isEmpty) return false;
    if (amount < 20 || amount > 5000) return false;

    // If matched offer exists for non-round amount, it's valid
    if (matchedOffers.isNotEmpty && useOfferPack.value) return true;

    // Regular recharge must be round figure
    return amount % 10 == 0;
  }

  String? get phoneError {
    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) return null;
    if (phone.length < 11) return AppStrings.enterNumber;
    if (!phone.startsWith('01')) return AppStrings.enterNumber;
    return null;
  }

  String? get amountError {
    final text = amountController.text;
    if (text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null) return AppStrings.rechargeFailed;
    if (amount < 20) return 'Min ৳20';
    if (amount > 5000) return 'Max ৳5,000';
    if (amount % 10 != 0 && matchedOffers.isEmpty) return 'Must end in 0';
    return null;
  }

  // ==================== INSTANT OFFER DETECTION ====================

  /// Debounce offer search by 400ms
  void _debouncedOfferSearch() {
    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(const Duration(milliseconds: 400), () {
      _searchMatchingOffers();
    });
  }

  /// Search for matching drive offers when amount & operator are known
  Future<void> _searchMatchingOffers() async {
    final amountText = amountController.text;
    final amount = double.tryParse(amountText);
    final operatorLetter = offerOperatorCode;

    // Clear if invalid input
    if (amount == null || amount <= 0 || operatorLetter.isEmpty) {
      matchedOffers.clear();
      useOfferPack.value = false;
      return;
    }

    try {
      isSearchingOffers.value = true;
      final offers = await _repository.searchDriveOffers(
        amount: amount,
        operator: operatorLetter,
      );
      matchedOffers.assignAll(offers);

      // Default to offer pack when any matching offer exists.
      // Non-round amounts must use offer pack.
      useOfferPack.value = offers.isNotEmpty;
    } catch (e) {
      LoggerService.error('Offer search failed', e);
      matchedOffers.clear();
    } finally {
      isSearchingOffers.value = false;
    }
  }

  /// Toggle whether to use matched offer pack or regular recharge
  void toggleOfferPack(bool value) {
    useOfferPack.value = value;
  }

  // ==================== INITIATE RECHARGE ====================

  Future<void> initiateRecharge() async {
    if (!isFormValid) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.rechargeFailed,
        message: AppStrings.enterNumber,
      );
      return;
    }

    final phone = phoneController.text.replaceAll(RegExp(r'\D'), '');
    final amount = double.parse(amountController.text);

    // If using offer pack, delegate to offer purchase
    if (useOfferPack.value && matchedOffers.isNotEmpty) {
      await purchaseDriveOffer(phone: phone, offer: matchedOffers.first);
      return;
    }

    try {
      isProcessing.value = true;
      EasyLoading.show(status: AppStrings.processingRecharge);

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
          message: cashback != null && cashback > 0
              ? '$message ${AppStrings.cashback}: ৳${cashback.toStringAsFixed(2)}'
              : message,
        );
        _clearForm();
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
      _handleRechargeError(e);
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
        message: AppStrings.enterNumber,
      );
      return;
    }

    try {
      isProcessing.value = true;
      EasyLoading.show(status: AppStrings.processingRecharge);

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
        _clearForm();
        fetchRechargeHistory();
      } else {
        AppSnackBar.errorSnackBar(
          title: AppStrings.rechargeFailed,
          message: message,
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      LoggerService.error('Drive offer purchase failed', e);
      _handleRechargeError(e);
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

      final validityFilter = selectedOfferValidity.value.trim();
      if (validityFilter.isEmpty) {
        driveOffers.assignAll(offers);
      } else {
        final needle = validityFilter.toLowerCase();
        driveOffers.assignAll(
          offers.where(
            (o) => o.validity.toLowerCase().contains(needle),
          ),
        );
      }
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

  void filterOffersByValidity(String validity) {
    selectedOfferValidity.value = validity;
    fetchDriveOffers();
  }

  void clearOfferFilters() {
    selectedOfferOperator.value = '';
    selectedOfferType.value = '';
    selectedOfferValidity.value = '';
    fetchDriveOffers();
  }

  // ==================== ERROR HANDLING ====================

  void _handleRechargeError(dynamic error) {
    String message = error.toString();

    // Handle Firebase Functions timeout per implementation guide
    if (message.contains('deadline-exceeded') ||
        message.contains('DEADLINE_EXCEEDED')) {
      AppSnackBar.warningSnackBar(
        title: AppStrings.processingRecharge,
        message: 'Request submitted. Status will update shortly.',
      );
      return;
    }

    AppSnackBar.errorSnackBar(
      title: AppStrings.rechargeFailed,
      message: message,
    );
  }

  // ==================== HELPERS ====================

  void _clearForm() {
    phoneController.clear();
    amountController.clear();
    selectedOperator.value = '';
    selectedNumberType.value = '1';
    matchedOffers.clear();
    useOfferPack.value = false;
  }

  void resetAll() {
    _clearForm();
    rechargeHistory.clear();
    driveOffers.clear();
  }
}
