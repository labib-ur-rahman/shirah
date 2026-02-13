import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/local_storage_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/utils/validators/validation.dart';
import 'package:shirah/data/repositories/authentication/auth_repository.dart';
import 'package:shirah/routes/app_routes.dart';

/// Authentication Controller
/// Manages login, signup, Google auth, forgot password, invite code flows.
/// Follows MVC + Repository pattern per shirah architecture.
class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // ===== Repository =====
  final AuthRepository _repository = AuthRepository();

  // ===== Observable State =====
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isGoogleSignIn = false.obs;
  final RxBool rememberMe = false.obs;
  final RxMap<String, dynamic> userProfile = RxMap<String, dynamic>({});

  // ===== Form Controllers =====
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  // ===== Form Keys =====
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  // ===== Streams =====
  // StreamSubscription<User?>? _authSubscription;

  // ===== Getters =====
  bool get isAuthenticated => firebaseUser.value != null;
  String? get userId => firebaseUser.value?.uid;
  String get userRole => userProfile['role'] ?? 'user';

  @override
  void onInit() {
    super.onInit();
    firebaseUser.value = _repository.currentUser;
    _repository.authStateChanges.listen((User? user) {
      firebaseUser.value = user;
    });
    // Load saved email and password if "Remember me" was checked
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    // _authSubscription?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    inviteCodeController.dispose();
    super.onClose();
  }

  // =====================================================================
  // LOGIN
  // =====================================================================

  /// Login with email and password
  Future<void> loginWithEmailPassword() async {
    if (!loginFormKey.currentState!.validate()) {
      LoggerService.warning('⚠️ Login form validation failed');
      return;
    }

    try {
      isLoading.value = true;
      LoggerService.info('🔐 Starting login process...');

      final result = await _repository.signInWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      LoggerService.info('✅ Login successful');
      LoggerService.debug('User profile: ${result['profile']}');

      userProfile.value = result['profile'] ?? {};

      // Save credentials if "Remember me" is checked
      if (rememberMe.value) {
        _saveCredentials(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        LoggerService.info('💾 Credentials saved for "Remember me"');
      } else {
        // Clear saved credentials if "Remember me" is unchecked
        _clearSavedCredentials();
        LoggerService.info('🗑️ Saved credentials cleared');
      }

      AppSnackBar.successSnackBar(
        title: AppStrings.success,
        message: AppStrings.authLoginSuccess,
      );

      // Navigate to main screen
      Get.offAllNamed(AppRoutes.MAIN);
      LoggerService.info('✅ Navigation to main screen');
    } catch (e) {
      LoggerService.error('❌ Login failed', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================================
  // SIGNUP
  // =====================================================================

  /// Signup with email and password
  Future<void> signupWithEmailPassword() async {
    if (!signupFormKey.currentState!.validate()) {
      LoggerService.warning('⚠️ Signup form validation failed');
      return;
    }

    try {
      isLoading.value = true;

      // Format invite code to uppercase
      final inviteCode = inviteCodeController.text.trim().toUpperCase();

      // Format phone (ensure clean 11-digit format)
      final phone = SLValidator.formatPhone(phoneController.text.trim());

      LoggerService.info(
        '📱 Phone formatted: ${phoneController.text} → $phone',
      );

      // Step 1: Validate invite code exists in Firestore BEFORE starting signup
      LoggerService.info('🔍 Validating invite code: $inviteCode');

      final isValidCode = await _repository.validateInviteCode(inviteCode);
      if (!isValidCode) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: 'Invalid invite code. Please check and try again.',
        );
        isLoading.value = false;
        return;
      }

      LoggerService.info('✅ Invite code is valid');

      // Step 2: Create account via Cloud Function (handles auth + all Firestore docs)
      LoggerService.info('🔐 Starting signup process...');

      final result = await _repository.signUpWithEmailPassword(
        email: emailController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phoneNumber: phone,
        password: passwordController.text,
        inviteCode: inviteCode,
      );

      LoggerService.info('✅ Signup successful');
      LoggerService.debug('User profile: ${result['profile']}');

      if (result['profile'] != null) {
        userProfile.value = result['profile'] ?? {};
        LoggerService.info('📊 User profile stored in controller');
      } else {
        LoggerService.warning('⚠️ Profile is null, using empty map');
        userProfile.value = {};
      }

      // Show success dialog
      AppSnackBar.successSnackBar(
        title: AppStrings.success,
        message: AppStrings.authSignupSuccess,
      );

      // Navigate to main screen after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/main');
      LoggerService.info('✅ Navigation to main screen');
    } catch (e) {
      LoggerService.error('❌ Signup failed', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================================
  // CONTINUE WITH GOOGLE
  // =====================================================================

  /// Sign in with Google
  /// Flow:
  /// 1. Always show Google account picker
  /// 2. After auth, check profile completeness (parentUid + phone)
  /// 3. Complete profile → go to dashboard
  /// 4. Incomplete profile → navigate to invite code screen
  /// 5. User cancels screen → sign out + delete auth credential
  Future<void> continueWithGoogle() async {
    try {
      isGoogleSignIn.value = true;
      LoggerService.info('🔐 Starting Google Sign-in flow...');

      final result = await _repository.signInWithGoogle();

      LoggerService.debug('📦 Google sign-in result: $result');

      final bool profileComplete = result['profileComplete'] == true;

      if (profileComplete) {
        // Fully complete profile — login directly to dashboard
        LoggerService.info(
          '✅ Complete profile found — navigating to dashboard',
        );
        userProfile.value = result['profile'] ?? {};

        AppSnackBar.successSnackBar(
          title: AppStrings.success,
          message: AppStrings.authLoginSuccess,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(AppRoutes.MAIN);
        LoggerService.info('✅ Navigation complete');
      } else {
        // Profile incomplete or new user — must provide phone + invite code
        LoggerService.info(
          '📝 Incomplete profile — showing invite code screen',
        );

        // Navigate to invite code screen
        // Loader will be shown on that screen when user submits form
        Get.toNamed(AppRoutes.INVITE_CODE);
      }
    } catch (e) {
      LoggerService.error('❌ Google sign in failed', e);

      // Don't show error for user-cancelled picker
      final errorMsg = e.toString();
      if (!errorMsg.contains('cancelled')) {
        AppSnackBar.errorSnackBar(
          title: AppStrings.error,
          message: errorMsg.replaceAll('Exception: ', ''),
        );
      }
    } finally {
      isGoogleSignIn.value = false;
    }
  }

  /// Complete Google signup — called from InviteCodeDialog
  /// Validates phone + invite code, calls cloud function, navigates to dashboard
  /// On failure: shows error but does NOT clean up auth (user can retry)
  Future<void> completeGoogleSignup() async {
    try {
      isLoading.value = true;

      final inviteCode = inviteCodeController.text.trim().toUpperCase();
      final phone = SLValidator.formatPhone(phoneController.text.trim());

      LoggerService.info(
        'Completing Google signup — phone: $phone, inviteCode: $inviteCode',
      );

      final result = await _repository.completeGoogleSignup(
        phoneNumber: phone,
        inviteCode: inviteCode,
      );

      LoggerService.info('Google signup completed successfully');
      LoggerService.debug('Result data: ${result['data']}');

      // Store the full user profile (not just {uid, inviteCode})
      userProfile.value = result['profile'] ?? {};
      LoggerService.info('✅ User profile stored in controller');

      AppSnackBar.successSnackBar(
        title: AppStrings.success,
        message: AppStrings.authSignupSuccess,
      );

      LoggerService.info('Navigating to main screen...');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.MAIN);
      LoggerService.info('Navigation complete');
    } catch (e) {
      LoggerService.error('Complete Google signup failed', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.error,
        message: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow; // Let the dialog handle the error state
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel Google signup — sign out and delete auth user
  Future<void> cancelGoogleSignup() async {
    try {
      await _repository.signOutAndDeleteUser();
      LoggerService.info('Google signup cancelled — auth user deleted');
    } catch (e) {
      LoggerService.error('Cancel Google signup error', e);
    }
  }

  // =====================================================================
  // FORGOT PASSWORD
  // =====================================================================

  /// Send password reset email
  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;

      await _repository.sendPasswordResetEmail(email);

      AppSnackBar.successSnackBar(
        title: AppStrings.success,
        message: AppStrings.authPasswordResetSent,
      );

      // Navigate to check email screen
      Get.toNamed(AppRoutes.CHECK_EMAIL, arguments: {'email': email});
    } catch (e) {
      LoggerService.error('Password reset failed', e);
      AppSnackBar.errorSnackBar(
        title: AppStrings.error,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================================
  // LOGOUT
  // =====================================================================

  /// Sign out user
  /// Note: Saved credentials persist even after logout
  /// User must explicitly uncheck "Remember Me" to clear them
  Future<void> logout() async {
    try {
      await _repository.signOut();
      userProfile.clear();
      // DON'T clear remembered credentials here
      // User can still log back in with saved credentials
      _clearControllers();

      AppSnackBar.successSnackBar(
        title: AppStrings.success,
        message: AppStrings.authLogoutSuccess,
      );

      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      LoggerService.error('Logout failed', e);
      AppSnackBar.errorSnackBar(title: AppStrings.error, message: e.toString());
    }
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  /// Load saved credentials from local storage
  /// Called when login screen initializes
  void loadSavedCredentials() {
    _loadSavedCredentials();
  }

  /// Save credentials when "Remember me" is checked
  void _saveCredentials({required String email, required String password}) {
    final lowerEmail = email.toLowerCase().trim();
    LocalStorageService.write('rememberMe', true);
    LocalStorageService.write('savedEmail', lowerEmail);
    LocalStorageService.write('savedPassword', password);
    LoggerService.info('💾 Credentials saved: email=$lowerEmail, password=***');
  }

  /// Load saved credentials if "Remember me" was previously checked
  void _loadSavedCredentials() {
    try {
      final rememberMe = LocalStorageService.read<bool>('rememberMe') ?? false;
      final savedEmail = LocalStorageService.read<String>('savedEmail');
      final savedPassword = LocalStorageService.read<String>('savedPassword');

      LoggerService.debug(
        '📖 Loading credentials: rememberMe=$rememberMe, email=$savedEmail, password=${savedPassword != null ? '***' : 'null'}',
      );

      if (rememberMe && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        this.rememberMe.value = true;
        LoggerService.info(
          '✅ Credentials loaded: ${emailController.text} (Remember Me: ${this.rememberMe.value})',
        );
      } else {
        this.rememberMe.value = false;
        LoggerService.info(
          'ℹ️ No saved credentials found (Remember Me was unchecked)',
        );
      }
    } catch (e) {
      LoggerService.error('Error loading credentials', e);
      rememberMe.value = false;
    }
  }

  /// Clear saved credentials when "Remember me" is unchecked
  void _clearSavedCredentials() {
    LocalStorageService.remove('rememberMe');
    LocalStorageService.remove('savedEmail');
    LocalStorageService.remove('savedPassword');
    LoggerService.info('🗑️ All saved credentials cleared');
  }

  /// Public method to clear saved credentials (for user settings/logout button)
  void clearRememberMe() {
    _clearSavedCredentials();
    rememberMe.value = false;
  }

  /// Clear all controllers
  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    inviteCodeController.clear();
  }

  /// Load last email from storage (legacy method)
  void loadLastEmail() {
    final lastEmail = LocalStorageService.read<String>('lastEmail');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      emailController.text = lastEmail;
    }
  }
}
