import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:shirah/core/services/firebase_service.dart';
import 'package:shirah/data/models/user/user_model.dart';
import 'package:shirah/data/repositories/user_repository.dart';

/// User Controller
/// Manages current user data and profile operations
class UserController extends GetxController {
  static UserController get instance => Get.find();

  // ===== Repository =====
  final UserRepository _userRepo = UserRepository();
  final FirebaseService _firebase = FirebaseService.instance;

  // ===== Observable State =====
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isBioUpdating = false.obs;

  // ===== Image Upload State =====
  final RxBool isUploadingAvatar = false.obs;
  final RxBool isUploadingCover = false.obs;

  // ===== Community State =====
  final RxInt communityMemberCount = 0.obs;

  // ===== Bio State (fetched separately from otherInfo) =====
  final RxString bio = ''.obs;

  // ===== Streams =====
  StreamSubscription<UserModel?>? _userSubscription;

  // ===== Getters =====
  String? get uid => _firebase.currentUserId;
  bool get hasUser => user.value != null;

  // Identity
  String get fullName => user.value?.identity.fullName ?? '';
  String get phone => user.value?.identity.phone ?? '';
  String get email => user.value?.identity.email ?? '';
  String get avatarUrl => user.value?.identity.photoURL ?? '';
  String get coverUrl => user.value?.identity.coverURL ?? '';
  String get firstName => user.value?.identity.firstName ?? '';
  String get lastName => user.value?.identity.lastName ?? '';

  // Codes
  String get inviteCode => user.value?.formattedInviteCode ?? '';
  String get referralCode => user.value?.codes.referralCode ?? '';

  // Status
  bool get isActive => user.value?.isActive ?? false;
  bool get isVerified => user.value?.isVerified ?? false;
  bool get isSubscribed => user.value?.isSubscribed ?? false;
  // Note: subscriptionTier not in model, using isSubscribed instead

  // Wallet (snapshot)
  double get balance => user.value?.wallet.balance ?? 0.0;
  int get rewardPoints => user.value?.wallet.rewardPoints ?? 0;

  // Bio (from otherInfo — loaded separately)
  String get userBio => bio.value;

  // Flags
  bool get isAdmin => user.value?.flags.isAdmin ?? false;
  bool get isModerator => user.value?.flags.isModerator ?? false;

  @override
  void onInit() {
    super.onInit();
    _initUserStream();
    fetchBio();
    fetchCommunityCount();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  /// Fetch bio from Firestore otherInfo map
  Future<void> fetchBio() async {
    final currentUid = uid;
    if (currentUid == null) return;
    try {
      bio.value = await _userRepo.fetchBio(currentUid);
    } catch (_) {}
  }

  /// Update bio in Firestore at users/{uid}/otherInfo.bio
  Future<bool> updateBio(String newBio) async {
    final currentUid = uid;
    if (currentUid == null) return false;
    try {
      isBioUpdating.value = true;
      await _userRepo.updateBio(currentUid, newBio.trim());
      bio.value = newBio.trim();
      return true;
    } catch (_) {
      return false;
    } finally {
      isBioUpdating.value = false;
    }
  }

  /// Initialize user stream
  void _initUserStream() {
    final currentUid = _firebase.currentUserId;
    if (currentUid == null) return;

    _userSubscription = _userRepo
        .streamUser(currentUid)
        .listen(
          (userData) {
            user.value = userData;
          },
          onError: (error) {
            // Silently handle error
          },
        );
  }

  /// Re-initialize when user logs in
  void onUserLoggedIn() {
    _userSubscription?.cancel();
    _initUserStream();
  }

  /// Clear when user logs out
  void onUserLoggedOut() {
    _userSubscription?.cancel();
    user.value = null;
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final currentUid = _firebase.currentUserId;
    if (currentUid == null) return;

    try {
      isLoading.value = true;
      final userData = await _userRepo.getUser(currentUid);
      user.value = userData;
    } finally {
      isLoading.value = false;
    }
  }

  // ===== PROFILE UPDATES =====

  /// Update user name
  Future<bool> updateName(String newName) async {
    final currentUid = uid;
    if (currentUid == null) return false;

    try {
      isUpdating.value = true;
      await _userRepo.updateName(currentUid, newName);
      return true;
    } catch (e) {
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update user avatar
  Future<bool> updateAvatar(String avatarUrl) async {
    final currentUid = uid;
    if (currentUid == null) return false;

    try {
      isUpdating.value = true;
      await _userRepo.updateAvatar(currentUid, avatarUrl);
      return true;
    } catch (e) {
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update full identity
  Future<bool> updateIdentity({
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoURL,
    String? coverURL,
  }) async {
    final currentUid = uid;
    if (currentUid == null || user.value == null) return false;

    try {
      isUpdating.value = true;

      final updatedIdentity = user.value!.identity.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        photoURL: photoURL,
        coverURL: coverURL,
      );

      await _userRepo.updateIdentity(currentUid, updatedIdentity);
      return true;
    } catch (e) {
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // ===== REFERRAL =====

  /// Get direct referrals (users who joined with this user's invite code)
  Future<List<UserModel>> getDirectReferrals() async {
    final currentUid = uid;
    if (currentUid == null) return [];

    return _userRepo.getDirectReferrals(currentUid);
  }

  /// Count direct referrals
  Future<int> countDirectReferrals() async {
    final currentUid = uid;
    if (currentUid == null) return 0;

    return _userRepo.countDirectReferrals(currentUid);
  }

  // ===== IMAGE UPLOAD =====

  /// Upload and set new profile picture
  Future<bool> uploadProfilePicture(File imageFile) async {
    final currentUid = uid;
    if (currentUid == null) return false;
    try {
      isUploadingAvatar.value = true;
      final url = await _userRepo.uploadAvatarImage(currentUid, imageFile);
      await _userRepo.updateAvatar(currentUid, url);
      return true;
    } catch (_) {
      return false;
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// Upload and set new cover photo
  Future<bool> uploadCoverPicture(File imageFile) async {
    final currentUid = uid;
    if (currentUid == null) return false;
    try {
      isUploadingCover.value = true;
      final url = await _userRepo.uploadCoverImage(currentUid, imageFile);
      await _userRepo.updateCoverURL(currentUid, url);
      return true;
    } catch (_) {
      return false;
    } finally {
      isUploadingCover.value = false;
    }
  }

  // ===== COMMUNITY =====

  /// Fetch total community member count from user_network_stats
  Future<void> fetchCommunityCount() async {
    final currentUid = uid;
    if (currentUid == null) return;
    try {
      communityMemberCount.value = await _userRepo.fetchCommunityMemberCount(
        currentUid,
      );
    } catch (_) {}
  }

  // ===== PROFILE EDIT =====

  /// Update first/last name directly in Firestore
  Future<bool> updateProfileName({
    required String firstName,
    required String lastName,
  }) async {
    final currentUid = uid;
    if (currentUid == null || user.value == null) return false;
    try {
      isUpdating.value = true;
      await _userRepo.updateUser(currentUid, {
        'identity.firstName': firstName.trim(),
        'identity.lastName': lastName.trim(),
      });
      return true;
    } catch (_) {
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
