import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// ============================================================================
/// APP DEVICE UTILITIES - Device & Platform Helpers
/// ============================================================================
/// Comprehensive utility class for device-specific operations, screen metrics,
/// and platform interactions for production-ready Flutter applications.
///
/// Features:
/// ✅ Keyboard management
/// ✅ Status bar customization
/// ✅ Orientation controls
/// ✅ Screen size calculations
/// ✅ Platform detection
/// ✅ Internet connectivity checks
/// ✅ URL launching
/// ✅ Haptic feedback
///
/// Architecture:
/// - Static methods only (no instantiation needed)
/// - Safe context access with null checks
/// - Production-ready error handling
/// - Cross-platform compatibility
///
/// Usage Examples:
///   // Hide keyboard
///   AppDeviceUtils.hideKeyboard(context);
///
///   // Get screen dimensions
///   final width = AppDeviceUtils.screenWidth;
///   final height = AppDeviceUtils.screenHeight;
///
///   // Platform checks
///   if (AppDeviceUtils.isAndroid) {
///     // Android-specific logic
///   }
/// ============================================================================

class AppDeviceUtils {
  /// Private constructor to prevent instantiation
  AppDeviceUtils._();

  // ============================================================================
  // KEYBOARD MANAGEMENT
  // ============================================================================

  /// Hide the keyboard
  ///
  /// Parameters:
  ///   - context: BuildContext (optional, uses Get.context if not provided)
  ///
  /// Example:
  ///   AppDeviceUtils.hideKeyboard(context);
  static void hideKeyboard([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      FocusScope.of(ctx).unfocus();
    }
  }

  /// Check if keyboard is currently visible
  ///
  /// Returns:
  ///   true if keyboard is visible, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isKeyboardVisible) {
  ///     // Adjust UI for keyboard
  ///   }
  static bool get isKeyboardVisible {
    final context = Get.context;
    if (context == null) return false;
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get current keyboard height in pixels
  ///
  /// Returns:
  ///   Keyboard height in pixels, or 0 if not visible
  ///
  /// Example:
  ///   final keyboardHeight = AppDeviceUtils.keyboardHeight;
  static double get keyboardHeight {
    final context = Get.context;
    if (context == null) return 0;
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // ============================================================================
  // STATUS BAR MANAGEMENT
  // ============================================================================

  /// Set status bar color
  ///
  /// Parameters:
  ///   - color: Color to set
  ///
  /// Example:
  ///   AppDeviceUtils.setStatusBarColor(Colors.transparent);
  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  /// Hide status bar
  ///
  /// Example:
  ///   AppDeviceUtils.hideStatusBar();
  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  /// Show status bar
  ///
  /// Example:
  ///   AppDeviceUtils.showStatusBar();
  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Get status bar height in pixels
  ///
  /// Returns:
  ///   Status bar height in pixels
  ///
  /// Example:
  ///   final statusBarHeight = AppDeviceUtils.statusBarHeight;
  static double get statusBarHeight {
    final context = Get.context;
    if (context == null) return 0;
    return MediaQuery.of(context).padding.top;
  }

  /// Get bottom safe area padding (for devices with notches/home indicators)
  ///
  /// Returns:
  ///   Bottom safe area padding in pixels
  ///
  /// Example:
  ///   final bottomPadding = AppDeviceUtils.bottomSafeAreaHeight;
  static double get bottomSafeAreaHeight {
    final context = Get.context;
    if (context == null) return 0;
    return MediaQuery.of(context).padding.bottom;
  }

  // ============================================================================
  // SCREEN METRICS
  // ============================================================================

  /// Get screen width in pixels
  ///
  /// Returns:
  ///   Screen width in pixels
  ///
  /// Example:
  ///   final width = AppDeviceUtils.screenWidth;
  static double get screenWidth {
    final context = Get.context;
    if (context == null) return 0;
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height in pixels
  ///
  /// Returns:
  ///   Screen height in pixels
  ///
  /// Example:
  ///   final height = AppDeviceUtils.screenHeight;
  static double get screenHeight {
    final context = Get.context;
    if (context == null) return 0;
    return MediaQuery.of(context).size.height;
  }

  /// Get screen size
  ///
  /// Returns:
  ///   Size object with width and height
  ///
  /// Example:
  ///   final size = AppDeviceUtils.screenSize;
  static Size get screenSize {
    final context = Get.context;
    if (context == null) return Size.zero;
    return MediaQuery.of(context).size;
  }

  /// Get device pixel ratio
  ///
  /// Returns:
  ///   Pixel ratio (e.g., 2.0 for 2x screens)
  ///
  /// Example:
  ///   final pixelRatio = AppDeviceUtils.pixelRatio;
  static double get pixelRatio {
    final context = Get.context;
    if (context == null) return 1.0;
    return MediaQuery.of(context).devicePixelRatio;
  }

  // ============================================================================
  // ORIENTATION
  // ============================================================================

  /// Check if device is in landscape orientation
  ///
  /// Returns:
  ///   true if landscape, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isLandscape) {
  ///     // Show landscape layout
  ///   }
  static bool get isLandscape {
    return screenWidth > screenHeight;
  }

  /// Check if device is in portrait orientation
  ///
  /// Returns:
  ///   true if portrait, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isPortrait) {
  ///     // Show portrait layout
  ///   }
  static bool get isPortrait {
    return screenHeight >= screenWidth;
  }

  /// Set preferred screen orientations
  ///
  /// Parameters:
  ///   - orientations: List of allowed DeviceOrientation values
  ///
  /// Example:
  ///   // Lock to portrait only
  ///   AppDeviceUtils.setPreferredOrientations([
  ///     DeviceOrientation.portraitUp,
  ///     DeviceOrientation.portraitDown,
  ///   ]);
  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Set fullscreen mode
  ///
  /// Parameters:
  ///   - enable: true for fullscreen, false for normal mode
  ///
  /// Example:
  ///   AppDeviceUtils.setFullScreen(true);
  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  // ============================================================================
  // PLATFORM DETECTION
  // ============================================================================

  /// Get standard app bar height
  ///
  /// Returns:
  ///   Standard toolbar height (56.0)
  ///
  /// Example:
  ///   final appBarHeight = AppDeviceUtils.appBarHeight;
  static double get appBarHeight {
    return kToolbarHeight;
  }

  /// Get standard bottom navigation bar height
  ///
  /// Returns:
  ///   Standard bottom navigation bar height
  ///
  /// Example:
  ///   final bottomNavHeight = AppDeviceUtils.bottomNavigationBarHeight;
  static double get bottomNavigationBarHeight {
    return kBottomNavigationBarHeight;
  }

  /// Check if running on Android platform
  ///
  /// Returns:
  ///   true if Android, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isAndroid) {
  ///     // Android-specific code
  ///   }
  static bool get isAndroid {
    return Platform.isAndroid;
  }

  /// Check if running on iOS platform
  ///
  /// Returns:
  ///   true if iOS, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isIOS) {
  ///     // iOS-specific code
  ///   }
  static bool get isIOS {
    return Platform.isIOS;
  }

  /// Check if running on web platform
  ///
  /// Returns:
  ///   true if web, false otherwise
  ///
  /// Example:
  ///   if (AppDeviceUtils.isWeb) {
  ///     // Web-specific code
  ///   }
  static bool get isWeb {
    return kIsWeb;
  }

  /// Check if physical device (not emulator/simulator)
  ///
  /// Returns:
  ///   true if physical device
  ///
  /// Example:
  ///   if (await AppDeviceUtils.isPhysicalDevice) {
  ///     // Physical device specific code
  ///   }
  static Future<bool> get isPhysicalDevice async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // ============================================================================
  // HAPTIC FEEDBACK
  // ============================================================================

  /// Trigger light haptic feedback
  ///
  /// Example:
  ///   AppDeviceUtils.lightHaptic();
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Trigger medium haptic feedback
  ///
  /// Example:
  ///   AppDeviceUtils.mediumHaptic();
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// Trigger heavy haptic feedback
  ///
  /// Example:
  ///   AppDeviceUtils.heavyHaptic();
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Trigger selection haptic feedback
  ///
  /// Example:
  ///   AppDeviceUtils.selectionHaptic();
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }

  /// Trigger vibration
  ///
  /// Example:
  ///   AppDeviceUtils.vibrate();
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // ============================================================================
  // NETWORK & CONNECTIVITY
  // ============================================================================

  /// Check internet connection availability
  ///
  /// Returns:
  ///   true if internet connection is available
  ///
  /// Example:
  ///   if (await AppDeviceUtils.hasInternetConnection) {
  ///     // Proceed with network request
  ///   }
  static Future<bool> get hasInternetConnection async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // ============================================================================
  // URL LAUNCHING
  // ============================================================================

  /// Launch URL in external browser or app
  ///
  /// Parameters:
  ///   - url: URL to launch
  ///   - mode: Launch mode (default: platformDefault)
  ///
  /// Returns:
  ///   true if successfully launched
  ///
  /// Example:
  ///   await AppDeviceUtils.launchURL('https://example.com');
  static Future<bool> launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        return await launchUrlString(url);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Launch email client with pre-filled email
  ///
  /// Parameters:
  ///   - email: Recipient email address
  ///   - subject: Optional email subject
  ///   - body: Optional email body
  ///
  /// Example:
  ///   await AppDeviceUtils.launchEmail(
  ///     'support@example.com',
  ///     subject: 'Help Request',
  ///     body: 'I need help with...',
  ///   );
  static Future<bool> launchEmail(
    String email, {
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          {
                if (subject != null) 'subject': subject,
                if (body != null) 'body': body,
              }.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&'),
    );
    return await launchURL(uri.toString());
  }

  /// Launch phone dialer
  ///
  /// Parameters:
  ///   - phoneNumber: Phone number to dial
  ///
  /// Example:
  ///   await AppDeviceUtils.launchPhone('01712345678');
  static Future<bool> launchPhone(String phoneNumber) async {
    return await launchURL('tel:$phoneNumber');
  }

  /// Launch SMS app with pre-filled message
  ///
  /// Parameters:
  ///   - phoneNumber: Recipient phone number
  ///   - message: Optional message body
  ///
  /// Example:
  ///   await AppDeviceUtils.launchSMS('01712345678', message: 'Hello!');
  static Future<bool> launchSMS(String phoneNumber, {String? message}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      query: message != null ? 'body=${Uri.encodeComponent(message)}' : null,
    );
    return await launchURL(uri.toString());
  }
}
