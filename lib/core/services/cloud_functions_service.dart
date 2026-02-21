import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/utils/exceptions/firebase_functions_exceptions.dart';

/// Cloud Functions Service
/// Centralized service for calling Firebase Cloud Functions
/// All functions are deployed in asia-south1 region
class CloudFunctionsService extends GetxController {
  static CloudFunctionsService get instance => Get.find();

  // ==================== Configuration ====================

  /// Cloud Functions region (Mumbai, India - closest to Bangladesh)
  static const String region = 'asia-south1';

  /// Firebase Functions instance
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: region);

  // ==================== Helper Methods ====================

  /// Call a Cloud Function with error handling
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic>? data,
  ) async {
    try {
      LoggerService.info('☁️ Calling Cloud Function: $functionName');
      if (data != null) {
        LoggerService.debug('Parameters: $data');
      }

      final result = await _functions.httpsCallable(functionName).call(data);
      final response = Map<String, dynamic>.from(result.data as Map);

      LoggerService.info('✅ Cloud Function response: $functionName');
      return response;
    } on FirebaseFunctionsException catch (e) {
      LoggerService.error('Cloud Function error: $functionName', e);
      throw SLFirebaseFunctionsException(
        e.code,
        message: e.message,
      ).formattedMessage;
    } catch (e) {
      LoggerService.error('Unknown error calling Cloud Function', e);
      throw 'Failed to execute function: $functionName';
    }
  }

  // ==================== User Functions ====================

  /// Create new user (email/password signup)
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String inviteCode,
  }) async {
    return call('createUser', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'inviteCode': inviteCode,
    });
  }

  /// Complete Google Sign-In (requires invite code for new users)
  Future<Map<String, dynamic>> completeGoogleSignIn({
    required String inviteCode,
  }) async {
    return call('completeGoogleSignIn', {'inviteCode': inviteCode});
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    return call('getUserProfile', null);
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoURL,
    String? coverURL,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (photoURL != null) data['photoURL'] = photoURL;
    if (coverURL != null) data['coverURL'] = coverURL;

    return call('updateUserProfile', data);
  }

  // ==================== Auth Functions ====================

  /// Verify user profile (after payment)
  Future<Map<String, dynamic>> verifyUserProfile({
    required String paymentTransactionId,
  }) async {
    return call('verifyUserProfile', {
      'paymentTransactionId': paymentTransactionId,
    });
  }

  /// Subscribe user (after payment)
  Future<Map<String, dynamic>> subscribeUser({
    required String paymentTransactionId,
  }) async {
    return call('subscribeUser', {
      'paymentTransactionId': paymentTransactionId,
    });
  }

  /// Check authentication status
  Future<Map<String, dynamic>> checkAuthStatus() async {
    return call('checkAuthStatus', null);
  }

  // ==================== Wallet Functions ====================

  /// Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    return call('requestWithdrawal', {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
    });
  }

  /// Get wallet transactions
  Future<Map<String, dynamic>> getMyWalletTransactions({int? limit}) async {
    return call('getMyWalletTransactions', {if (limit != null) 'limit': limit});
  }

  /// Get withdrawal requests
  Future<Map<String, dynamic>> getMyWithdrawalRequests({int? limit}) async {
    return call('getMyWithdrawalRequests', {if (limit != null) 'limit': limit});
  }

  // ==================== Reward Functions ====================

  /// Record ad view
  Future<Map<String, dynamic>> recordAdView({
    required String adType,
    required String deviceId,
  }) async {
    return call('recordAdView', {'adType': adType, 'deviceId': deviceId});
  }

  /// Convert reward points to BDT
  Future<Map<String, dynamic>> convertRewardPoints({
    required int points,
  }) async {
    return call('convertRewardPoints', {'points': points});
  }

  /// Get streak information
  Future<Map<String, dynamic>> getStreakInfo() async {
    return call('getStreakInfo', null);
  }

  /// Get reward transactions
  Future<Map<String, dynamic>> getMyRewardTransactions({int? limit}) async {
    return call('getMyRewardTransactions', {if (limit != null) 'limit': limit});
  }

  // ==================== Permission Functions ====================

  /// Get my permissions
  Future<Map<String, dynamic>> getMyPermissions() async {
    return call('getMyPermissions', null);
  }

  /// Get user permissions (Admin+)
  Future<Map<String, dynamic>> getUserPermissions({
    required String targetUid,
  }) async {
    return call('getUserPermissions', {'targetUid': targetUid});
  }

  /// Grant permissions to user (Admin+)
  Future<Map<String, dynamic>> grantUserPermissions({
    required String targetUid,
    required List<String> permissions,
  }) async {
    return call('grantUserPermissions', {
      'targetUid': targetUid,
      'permissions': permissions,
    });
  }

  /// Revoke permissions from user (Admin+)
  Future<Map<String, dynamic>> revokeUserPermissions({
    required String targetUid,
    required List<String> permissions,
  }) async {
    return call('revokeUserPermissions', {
      'targetUid': targetUid,
      'permissions': permissions,
    });
  }

  /// Change user role (Admin+)
  Future<Map<String, dynamic>> changeUserRole({
    required String targetUid,
    required String newRole,
  }) async {
    return call('changeUserRole', {'targetUid': targetUid, 'newRole': newRole});
  }

  // ==================== Admin Functions ====================

  /// Suspend user
  Future<Map<String, dynamic>> suspendUser({
    required String targetUid,
    required String reason,
    DateTime? suspendUntil,
  }) async {
    return call('suspendUser', {
      'targetUid': targetUid,
      'reason': reason,
      if (suspendUntil != null) 'suspendUntil': suspendUntil.toIso8601String(),
    });
  }

  /// Ban user
  Future<Map<String, dynamic>> banUser({
    required String targetUid,
    required String reason,
  }) async {
    return call('banUser', {'targetUid': targetUid, 'reason': reason});
  }

  /// Unban user
  Future<Map<String, dynamic>> unbanUser({
    required String targetUid,
    required String reason,
  }) async {
    return call('unbanUser', {'targetUid': targetUid, 'reason': reason});
  }

  /// Approve withdrawal
  Future<Map<String, dynamic>> approveWithdrawal({
    required String withdrawalId,
    String? adminNote,
  }) async {
    return call('approveWithdrawal', {
      'withdrawalId': withdrawalId,
      if (adminNote != null) 'adminNote': adminNote,
    });
  }

  /// Reject withdrawal
  Future<Map<String, dynamic>> rejectWithdrawal({
    required String withdrawalId,
    required String reason,
  }) async {
    return call('rejectWithdrawal', {
      'withdrawalId': withdrawalId,
      'reason': reason,
    });
  }

  /// Credit wallet (Admin)
  Future<Map<String, dynamic>> adminCreditWallet({
    required String targetUid,
    required double amount,
    required String reason,
  }) async {
    return call('adminCreditWallet', {
      'targetUid': targetUid,
      'amount': amount,
      'reason': reason,
    });
  }

  /// Credit reward points (Admin)
  Future<Map<String, dynamic>> adminCreditRewardPoints({
    required String targetUid,
    required int points,
    required String reason,
  }) async {
    return call('adminCreditRewardPoints', {
      'targetUid': targetUid,
      'points': points,
      'reason': reason,
    });
  }

  /// Lock wallet (Admin)
  Future<Map<String, dynamic>> adminLockWallet({
    required String targetUid,
    required String reason,
  }) async {
    return call('adminLockWallet', {'targetUid': targetUid, 'reason': reason});
  }

  /// Unlock wallet (Admin)
  Future<Map<String, dynamic>> adminUnlockWallet({
    required String targetUid,
    required String reason,
  }) async {
    return call('adminUnlockWallet', {
      'targetUid': targetUid,
      'reason': reason,
    });
  }

  /// Set user risk level (Admin)
  Future<Map<String, dynamic>> setUserRiskLevel({
    required String targetUid,
    required String riskLevel,
    required String reason,
  }) async {
    return call('setUserRiskLevel', {
      'targetUid': targetUid,
      'riskLevel': riskLevel,
      'reason': reason,
    });
  }

  /// Get pending withdrawals (Admin)
  Future<Map<String, dynamic>> getPendingWithdrawals({int? limit}) async {
    return call('getPendingWithdrawals', {if (limit != null) 'limit': limit});
  }

  /// Get admin user details
  Future<Map<String, dynamic>> getAdminUserDetails({
    required String targetUid,
  }) async {
    return call('getAdminUserDetails', {'targetUid': targetUid});
  }

  /// Search users (Admin)
  Future<Map<String, dynamic>> searchUsers({
    required String query,
    required String field,
    int? limit,
  }) async {
    return call('searchUsers', {
      'query': query,
      'field': field,
      if (limit != null) 'limit': limit,
    });
  }

  // ==================== Configuration Functions ====================

  /// Seed configurations (SuperAdmin)
  Future<Map<String, dynamic>> seedConfigurations() async {
    return call('seedConfigurations', null);
  }

  /// Update app config (SuperAdmin)
  Future<Map<String, dynamic>> updateAppConfig({
    required Map<String, dynamic> updates,
  }) async {
    return call('updateAppConfig', {'updates': updates});
  }

  /// Get app config (Admin+)
  Future<Map<String, dynamic>> getAppConfigAdmin() async {
    return call('getAppConfigAdmin', null);
  }

  // ==================== Community Functions ====================

  /// Create a community post
  Future<Map<String, dynamic>> createCommunityPost({
    required String text,
    required List<String> images,
    required String privacy,
  }) async {
    return call('createCommunityPost', {
      'text': text,
      'images': images,
      'privacy': privacy,
    });
  }

  /// Toggle reaction on a post
  Future<Map<String, dynamic>> togglePostReaction({
    required String postId,
    required String reactionType,
  }) async {
    return call('togglePostReaction', {
      'postId': postId,
      'reactionType': reactionType,
    });
  }

  /// Add a comment to a post
  Future<Map<String, dynamic>> addPostComment({
    required String postId,
    required String text,
  }) async {
    return call('addPostComment', {'postId': postId, 'text': text});
  }

  /// Add a reply to a comment
  Future<Map<String, dynamic>> addPostReply({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    return call('addPostReply', {
      'postId': postId,
      'commentId': commentId,
      'text': text,
    });
  }

  /// Moderate a post (Admin/Moderator)
  Future<Map<String, dynamic>> moderatePost({
    required String postId,
    required String action,
    String? reason,
  }) async {
    return call('moderatePost', {
      'postId': postId,
      'action': action,
      if (reason != null) 'reason': reason,
    });
  }

  /// Delete a community post (soft delete)
  Future<Map<String, dynamic>> deleteCommunityPost({
    required String postId,
  }) async {
    return call('deleteCommunityPost', {'postId': postId});
  }

  // ==================== Home Feed Admin Functions ====================

  /// Create a native ad feed item (Admin)
  Future<Map<String, dynamic>> createNativeAdFeed({
    required String adUnitId,
    required String platform,
    int? minGap,
    int? maxPerSession,
  }) async {
    return call('createNativeAdFeed', {
      'adUnitId': adUnitId,
      'platform': platform,
      if (minGap != null) 'minGap': minGap,
      if (maxPerSession != null) 'maxPerSession': maxPerSession,
    });
  }

  /// Update feed item status (Admin/Moderator)
  Future<Map<String, dynamic>> updateFeedItemStatus({
    required String feedId,
    required String status,
    String? reason,
  }) async {
    return call('updateFeedItemStatus', {
      'feedId': feedId,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  /// Update feed item priority (Admin)
  Future<Map<String, dynamic>> updateFeedItemPriority({
    required String feedId,
    required int priority,
  }) async {
    return call('updateFeedItemPriority', {
      'feedId': feedId,
      'priority': priority,
    });
  }

  /// Get admin feed items with filters (Admin/Moderator)
  Future<Map<String, dynamic>> getAdminFeedItems({
    int? limit,
    String? status,
    String? type,
  }) async {
    return call('getAdminFeedItems', {
      if (limit != null) 'limit': limit,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
    });
  }

  // ==================== Payment Functions ====================

  /// Create a payment transaction after UddoktaPay response
  Future<Map<String, dynamic>> createPaymentTransaction({
    required String type,
    required Map<String, dynamic> uddoktapayResponse,
  }) async {
    return call('createPaymentTransaction', {
      'type': type,
      'uddoktapayResponse': uddoktapayResponse,
    });
  }

  /// Get payment history for current user
  Future<Map<String, dynamic>> getPaymentHistory({
    int? limit,
    String? startAfter,
  }) async {
    return call('getPaymentHistory', {
      if (limit != null) 'limit': limit,
      if (startAfter != null) 'startAfter': startAfter,
    });
  }

  /// Get payment configuration (UddoktaPay credentials + prices)
  Future<Map<String, dynamic>> getPaymentConfig() async {
    return call('getPaymentConfig', null);
  }

  /// Re-verify a pending payment by calling UddoktaPay verify API server-side
  Future<Map<String, dynamic>> reVerifyPendingPayment({
    required String paymentTransactionId,
  }) async {
    return call('reVerifyPendingPayment', {
      'paymentTransactionId': paymentTransactionId,
    });
  }

  /// Admin: Approve a pending payment
  Future<Map<String, dynamic>> adminApprovePayment({
    required String paymentTransactionId,
  }) async {
    return call('adminApprovePayment', {
      'paymentTransactionId': paymentTransactionId,
    });
  }

  /// Admin: Get payment transactions for review
  Future<Map<String, dynamic>> getAdminPaymentTransactions({
    int? limit,
    String? status,
    String? type,
  }) async {
    return call('getAdminPaymentTransactions', {
      if (limit != null) 'limit': limit,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
    });
  }
}
