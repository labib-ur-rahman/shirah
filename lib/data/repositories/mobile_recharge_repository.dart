import 'package:get/get.dart';
import 'package:shirah/core/services/cloud_functions_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/data/models/recharge/drive_offer_model.dart';
import 'package:shirah/data/models/recharge/recharge_model.dart';

/// Mobile Recharge Repository - Firebase operations for recharge & drive offers
/// All operations go through Cloud Functions (ECARE API is server-side only)
class MobileRechargeRepository extends GetxController {
  static MobileRechargeRepository get instance => Get.find();

  final CloudFunctionsService _functions = CloudFunctionsService.instance;

  // ==================== RECHARGE ====================

  /// Initiate a mobile recharge
  Future<Map<String, dynamic>> initiateRecharge({
    required String phone,
    required String operator,
    required String numberType,
    required double amount,
    required String type,
    Map<String, dynamic>? offerDetails,
  }) async {
    try {
      LoggerService.info('📱 Initiating $type: ৳$amount to $phone ($operator)');
      final result = await _functions.call('initiateRecharge', {
        'phone': phone,
        'operator': operator,
        'numberType': numberType,
        'amount': amount,
        'type': type,
        if (offerDetails != null) 'offerDetails': offerDetails,
      });
      LoggerService.info('✅ Recharge initiated: ${result['data']?['refid']}');
      return result;
    } catch (e) {
      LoggerService.error('Failed to initiate recharge', e);
      rethrow;
    }
  }

  // ==================== RECHARGE HISTORY ====================

  /// Get recharge history for current user
  Future<List<RechargeModel>> getRechargeHistory({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      LoggerService.info('📋 Fetching recharge history (limit: $limit)');
      final result = await _functions.call('getRechargeHistory', {
        'limit': limit,
        if (startAfter != null) 'startAfter': startAfter,
      });

      final transactions = result['data']?['transactions'] as List? ?? [];
      return transactions
          .map(
            (t) => RechargeModel.fromMap(Map<String, dynamic>.from(t as Map)),
          )
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch recharge history', e);
      rethrow;
    }
  }

  // ==================== DRIVE OFFERS ====================

  /// Get drive offer list with optional filters
  Future<List<DriveOfferModel>> getDriveOffers({
    String? operator,
    String? offerType,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      LoggerService.info('📦 Fetching drive offers');
      final result = await _functions.call('getDriveOffers', {
        if (operator != null) 'operator': operator,
        if (offerType != null) 'offerType': offerType,
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
      });

      final offers = result['data']?['offers'] as List? ?? [];
      return offers
          .map(
            (o) => DriveOfferModel.fromMap(Map<String, dynamic>.from(o as Map)),
          )
          .toList();
    } catch (e) {
      LoggerService.error('Failed to fetch drive offers', e);
      rethrow;
    }
  }

  /// Search drive offers by exact amount and operator
  Future<List<DriveOfferModel>> searchDriveOffers({
    required double amount,
    required String operator,
    String? offerType,
  }) async {
    try {
      LoggerService.info(
        '🔍 Searching offers: ৳$amount for operator $operator',
      );
      final result = await _functions.call('searchDriveOffers', {
        'amount': amount,
        'operator': operator,
        if (offerType != null) 'offerType': offerType,
      });

      final offers = result['data']?['offers'] as List? ?? [];
      return offers
          .map(
            (o) => DriveOfferModel.fromMap(Map<String, dynamic>.from(o as Map)),
          )
          .toList();
    } catch (e) {
      LoggerService.error('Failed to search drive offers', e);
      rethrow;
    }
  }
}
