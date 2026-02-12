import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shirah/core/services/local_storage_service.dart';

/// ============================================================================
/// APP HELPER - Unified Application Helper Utilities
/// ============================================================================
/// Comprehensive helper class combining theme, locale, UI, and utility functions
/// for production-ready, enterprise-level Flutter applications.
///
/// Features:
/// ✅ Reactive theme management with GetX
/// ✅ Reactive language/locale management
/// ✅ UI feedback (snackbars, alerts, loading)
/// ✅ Device utilities (screen size, orientation)
/// ✅ Data formatting and manipulation
/// ✅ Type-safe, fast, reusable methods
/// ✅ Null-safe and error-resistant
///
/// Architecture:
/// - 8 organized sections for easy navigation
/// - Static methods only (no instantiation needed)
/// - Comprehensive documentation with examples
/// - Enterprise-level code organization
///
/// Usage Examples:
///   // Theme
///   final isDark = AppHelper.isDarkMode;
///   final bgColor = AppHelper.backgroundColor;
///
///   // Locale
///   final isBangla = AppHelper.isBangla;
///   final greeting = AppHelper.getGreeting();
///
///   // UI Feedback
///   AppHelper.showSnackBar('Success!');
///   AppHelper.showAlert('Error', 'Something went wrong');
///
///   // Utilities
///   final screenWidth = AppHelper.screenWidth;
///   final formattedDate = AppHelper.formatDate(DateTime.now());
/// ============================================================================

class AppHelper {
  /// Private constructor to prevent instantiation
  /// All methods are static and accessed via AppHelper.method()
  AppHelper._();

  // ============================================================================
  // SECTION 1: THEME MANAGEMENT
  // ============================================================================
  // ⚠️ DEPRECATED: Use SLHelper.isDarkMode instead for consistency
  //
  // Theme management has been moved to ThemeService for enterprise-level
  // consistency and instant theme switching.
  //
  // MIGRATION:
  //   AppHelper.isDarkMode  →  SLHelper.isDarkMode
  //   Get.changeThemeMode() →  ThemeService.changeTheme()
  //
  // See: lib/core/services/THEME_MANAGEMENT_GUIDE.md
  // ============================================================================

  /// Get current theme mode from storage
  /// ⚠️ DEPRECATED: Use ThemeService.currentThemeMode instead
  ///
  /// Example:
  ///   final themeMode = ThemeService.currentThemeMode;
  @Deprecated('Use ThemeService.currentThemeMode instead')
  static ThemeMode get currentThemeMode {
    return LocalStorageService.getThemeMode();
  }

  /// Check if current theme is dark mode
  /// ⚠️ DEPRECATED: Use SLHelper.isDarkMode instead (single source of truth)
  ///
  /// Example:
  ///   final isDark = SLHelper.isDarkMode;
  @Deprecated('Use SLHelper.isDarkMode instead')
  static bool get isDarkMode {
    return Get.isDarkMode;
  }

  /// Check if current theme is light mode
  /// ⚠️ DEPRECATED: Use SLHelper.isLightMode instead
  ///
  /// Example:
  ///   if (SLHelper.isLightMode) { /* light styles */ }
  @Deprecated('Use SLHelper.isLightMode instead')
  static bool get isLightMode {
    return !Get.isDarkMode;
  }

  /// Get background color based on current theme
  /// ⚠️ DEPRECATED: Use AppStyleColors.instance.background for style-aware colors
  ///
  /// Example:
  ///   Scaffold(backgroundColor: AppStyleColors.instance.background)
  @Deprecated('Use AppStyleColors.instance.background instead')
  static Color get backgroundColor {
    return isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFEEEFFC);
  }

  /// Get container/card background color based on theme
  /// ⚠️ DEPRECATED: Use AppStyleColors.instance.surface instead
  ///
  /// Example:
  ///   Container(color: AppHelper.cardColor)
  static Color get cardColor {
    return isDarkMode ? const Color(0xFF1E1E2E) : Colors.white;
  }

  /// Get text color based on theme
  ///
  /// Example:
  ///   Text('Hello', style: TextStyle(color: AppHelper.textColor))
  static Color get textColor {
    return isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
  }

  /// Get secondary text color based on theme
  ///
  /// Example:
  ///   Text('Subtitle', style: TextStyle(color: AppHelper.secondaryTextColor))
  static Color get secondaryTextColor {
    return isDarkMode ? Colors.white70 : const Color(0xFF6B7280);
  }

  /// Get border color based on theme
  ///
  /// Example:
  ///   Border.all(color: AppHelper.borderColor)
  static Color get borderColor {
    return isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
  }

  /// Get shadow color based on theme
  ///
  /// Example:
  ///   BoxShadow(color: AppHelper.shadowColor)
  static Color get shadowColor {
    return isDarkMode
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.05);
  }

  // ============================================================================
  // SECTION 2: LOCALE/LANGUAGE MANAGEMENT
  // ============================================================================
  // NOTE: These getters read from Get's current locale state.
  // They are NOT GetX .obs variables — do NOT wrap in Obx().
  // Locale changes propagate via Get.updateLocale() which rebuilds
  // the widget tree through GetMaterialApp.
  // ============================================================================

  /// Get current locale from GetX
  /// Returns Locale('en', 'US') or Locale('bn', 'BD')
  ///
  /// Example:
  ///   final locale = AppHelper.currentLocale;
  static Locale get currentLocale {
    return Get.locale ?? LocalStorageService.getLocale();
  }

  /// Get current language code ('en' or 'bn')
  ///
  /// Example:
  ///   final langCode = AppHelper.currentLanguage;
  static String get currentLanguage {
    return currentLocale.languageCode;
  }

  /// Check if current language is Bangla
  ///
  /// Example:
  ///   if (AppHelper.isBangla) { /* Bangla UI */ }
  static bool get isBangla {
    return currentLanguage == 'bn';
  }

  /// Check if current language is English
  ///
  /// Example:
  ///   if (AppHelper.isEnglish) { /* English UI */ }
  static bool get isEnglish {
    return currentLanguage == 'en';
  }

  /// Get localized greeting based on time and language
  ///
  /// Example:
  ///   Text(AppHelper.getGreeting()) // 'Good Morning' or 'সুপ্রভাত'
  static String getGreeting() {
    final hour = DateTime.now().hour;
    final isBn = isBangla;

    if (hour < 12) {
      return isBn ? 'সুপ্রভাত' : 'Good Morning';
    } else if (hour < 17) {
      return isBn ? 'শুভ অপরাহ্ন' : 'Good Afternoon';
    } else if (hour < 21) {
      return isBn ? 'শুভ সন্ধ্যা' : 'Good Evening';
    } else {
      return isBn ? 'শুভ রাত্রি' : 'Good Night';
    }
  }

  // ============================================================================
  // SECTION 3: UI FEEDBACK (SNACKBARS, ALERTS, LOADING)
  // ============================================================================

  /// Show snackbar/toast message using EasyLoading
  /// Brief overlay message for quick feedback
  ///
  /// Parameters:
  ///   - message: The message to display
  ///
  /// Example:
  ///   AppHelper.showSnackBar('Profile updated successfully!');
  static void showSnackBar(String message) {
    EasyLoading.showToast(
      message,
      duration: const Duration(seconds: 2),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  /// Show success message with checkmark icon
  ///
  /// Parameters:
  ///   - message: Success message to display
  ///
  /// Example:
  ///   AppHelper.showSuccess('Login successful!');
  static void showSuccess(String message) {
    EasyLoading.showSuccess(message, duration: const Duration(seconds: 2));
  }

  /// Show error message with X icon
  ///
  /// Parameters:
  ///   - message: Error message to display
  ///
  /// Example:
  ///   AppHelper.showError('Invalid credentials');
  static void showError(String message) {
    EasyLoading.showError(message, duration: const Duration(seconds: 2));
  }

  /// Show info message with info icon
  ///
  /// Parameters:
  ///   - message: Info message to display
  ///
  /// Example:
  ///   AppHelper.showInfo('Please verify your email');
  static void showInfo(String message) {
    EasyLoading.showInfo(message, duration: const Duration(seconds: 2));
  }

  /// Show loading spinner with optional message
  ///
  /// Parameters:
  ///   - message: Optional loading message
  ///
  /// Example:
  ///   AppHelper.showLoading('Processing...');
  ///   // Do async work
  ///   AppHelper.dismissLoading();
  static void showLoading([String? message]) {
    EasyLoading.show(
      status: message ?? 'Loading...',
      maskType: EasyLoadingMaskType.black,
    );
  }

  /// Dismiss loading spinner
  ///
  /// Example:
  ///   AppHelper.dismissLoading();
  static void dismissLoading() {
    EasyLoading.dismiss();
  }

  /// Show alert dialog with title and message
  ///
  /// Parameters:
  ///   - title: Dialog title
  ///   - message: Dialog message
  ///   - onConfirm: Optional callback when OK is pressed
  ///
  /// Example:
  ///   AppHelper.showAlert('Error', 'Something went wrong');
  static void showAlert(
    String title,
    String message, {
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog with Yes/No buttons
  ///
  /// Parameters:
  ///   - title: Dialog title
  ///   - message: Dialog message
  ///   - onConfirm: Callback when Yes is pressed
  ///   - onCancel: Optional callback when No is pressed
  ///
  /// Example:
  ///   AppHelper.showConfirmDialog(
  ///     'Delete Account',
  ///     'Are you sure?',
  ///     onConfirm: () => deleteAccount(),
  ///   );
  static void showConfirmDialog(
    String title,
    String message, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // SECTION 4: DEVICE & SCREEN UTILITIES
  // ============================================================================

  /// Get screen size
  ///
  /// Example:
  ///   final size = AppHelper.screenSize;
  ///   print('Width: ${size.width}, Height: ${size.height}');
  static Size get screenSize {
    return MediaQuery.of(Get.context!).size;
  }

  /// Get screen width
  ///
  /// Example:
  ///   final width = AppHelper.screenWidth;
  static double get screenWidth {
    return MediaQuery.of(Get.context!).size.width;
  }

  /// Get screen height
  ///
  /// Example:
  ///   final height = AppHelper.screenHeight;
  static double get screenHeight {
    return MediaQuery.of(Get.context!).size.height;
  }

  /// Get status bar height
  ///
  /// Example:
  ///   final statusBarHeight = AppHelper.statusBarHeight;
  static double get statusBarHeight {
    return MediaQuery.of(Get.context!).padding.top;
  }

  /// Get bottom safe area height
  ///
  /// Example:
  ///   final bottomPadding = AppHelper.bottomPadding;
  static double get bottomPadding {
    return MediaQuery.of(Get.context!).padding.bottom;
  }

  /// Check if device is in landscape orientation
  ///
  /// Example:
  ///   if (AppHelper.isLandscape) {
  ///     // Show landscape layout
  ///   }
  static bool get isLandscape {
    return screenWidth > screenHeight;
  }

  /// Check if device is in portrait orientation
  ///
  /// Example:
  ///   if (AppHelper.isPortrait) {
  ///     // Show portrait layout
  ///   }
  static bool get isPortrait {
    return screenHeight > screenWidth;
  }

  /// Check if keyboard is visible
  ///
  /// Example:
  ///   if (AppHelper.isKeyboardVisible) {
  ///     // Adjust UI for keyboard
  ///   }
  static bool get isKeyboardVisible {
    return MediaQuery.of(Get.context!).viewInsets.bottom > 0;
  }

  /// Hide keyboard
  ///
  /// Example:
  ///   AppHelper.hideKeyboard();
  static void hideKeyboard() {
    FocusScope.of(Get.context!).unfocus();
  }

  // ============================================================================
  // SECTION 5: DATE & TIME FORMATTING
  // ============================================================================

  /// Format date with custom format
  ///
  /// Parameters:
  ///   - date: DateTime to format
  ///   - format: Date format pattern (default: 'dd MMM yyyy')
  ///
  /// Example:
  ///   final formatted = AppHelper.formatDate(DateTime.now());
  ///   // Returns: '11 Feb 2026'
  ///
  ///   final custom = AppHelper.formatDate(DateTime.now(), format: 'yyyy-MM-dd');
  ///   // Returns: '2026-02-11'
  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format date with time
  ///
  /// Example:
  ///   final formatted = AppHelper.formatDateTime(DateTime.now());
  ///   // Returns: '11 Feb 2026 15:30'
  static String formatDateTime(
    DateTime date, {
    String format = 'dd MMM yyyy HH:mm',
  }) {
    return DateFormat(format).format(date);
  }

  /// Get time ago string (e.g., '2 hours ago', '3 days ago')
  ///
  /// Example:
  ///   final timeAgo = AppHelper.timeAgo(DateTime.now().subtract(Duration(hours: 2)));
  ///   // Returns: '2 hours ago'
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // ============================================================================
  // SECTION 6: STRING UTILITIES
  // ============================================================================

  /// Truncate text with ellipsis
  ///
  /// Parameters:
  ///   - text: Text to truncate
  ///   - maxLength: Maximum length before truncation
  ///
  /// Example:
  ///   final truncated = AppHelper.truncateText('Hello World', 5);
  ///   // Returns: 'Hello...'
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  /// Capitalize first letter of each word
  ///
  /// Example:
  ///   final capitalized = AppHelper.capitalize('hello world');
  ///   // Returns: 'Hello World'
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Check if string is email
  ///
  /// Example:
  ///   final isEmail = AppHelper.isEmail('test@example.com');
  ///   // Returns: true
  static bool isEmail(String text) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(text);
  }

  /// Check if string is phone number (Bangladesh format)
  ///
  /// Example:
  ///   final isPhone = AppHelper.isPhoneNumber('01712345678');
  ///   // Returns: true
  static bool isPhoneNumber(String text) {
    final phoneRegex = RegExp(r'^01[3-9]\d{8}$');
    return phoneRegex.hasMatch(text);
  }

  // ============================================================================
  // SECTION 7: LIST/COLLECTION UTILITIES
  // ============================================================================

  /// Remove duplicates from list
  ///
  /// Example:
  ///   final unique = AppHelper.removeDuplicates([1, 2, 2, 3]);
  ///   // Returns: [1, 2, 3]
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  /// Chunk list into smaller lists
  ///
  /// Parameters:
  ///   - list: List to chunk
  ///   - size: Size of each chunk
  ///
  /// Example:
  ///   final chunked = AppHelper.chunkList([1, 2, 3, 4, 5], 2);
  ///   // Returns: [[1, 2], [3, 4], [5]]
  static List<List<T>> chunkList<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  /// Wrap widgets in rows
  ///
  /// Parameters:
  ///   - widgets: List of widgets to wrap
  ///   - rowSize: Number of widgets per row
  ///
  /// Example:
  ///   final wrapped = AppHelper.wrapWidgets([Widget1(), Widget2(), Widget3()], 2);
  ///   // Returns: [Row([Widget1, Widget2]), Row([Widget3])]
  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
        i,
        i + rowSize > widgets.length ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  // ============================================================================
  // SECTION 8: NUMBER FORMATTING
  // ============================================================================

  /// Format number with thousand separators
  ///
  /// Example:
  ///   final formatted = AppHelper.formatNumber(1234567);
  ///   // Returns: '1,234,567'
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(number);
  }

  /// Format currency (BDT)
  ///
  /// Example:
  ///   final formatted = AppHelper.formatCurrency(1234.56);
  ///   // Returns: '৳1,234.56'
  static String formatCurrency(num amount, {String symbol = '৳'}) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  /// Format percentage
  ///
  /// Example:
  ///   final formatted = AppHelper.formatPercentage(0.1234);
  ///   // Returns: '12.34%'
  static String formatPercentage(double value, {int decimals = 2}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Abbreviate large numbers (K, M, B)
  ///
  /// Example:
  ///   final abbreviated = AppHelper.abbreviateNumber(1234567);
  ///   // Returns: '1.2M'
  static String abbreviateNumber(num number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else if (number < 1000000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }
  }

  // ============================================================================
  // SECTION 9: VALIDATION HELPERS
  // ============================================================================

  /// Check if value is null or empty
  ///
  /// Example:
  ///   final isEmpty = AppHelper.isNullOrEmpty('');
  ///   // Returns: true
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Check if list is null or empty
  ///
  /// Example:
  ///   final isEmpty = AppHelper.isListEmpty([]);
  ///   // Returns: true
  static bool isListEmpty(List? list) {
    return list == null || list.isEmpty;
  }

  /// Validate Bangladesh phone number
  ///
  /// Example:
  ///   final error = AppHelper.validatePhone('01712345678');
  ///   // Returns: null (valid) or error message
  static String? validatePhone(String? value) {
    if (isNullOrEmpty(value)) {
      return 'Phone number is required';
    }
    if (!isPhoneNumber(value!)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  /// Validate email
  ///
  /// Example:
  ///   final error = AppHelper.validateEmail('test@example.com');
  ///   // Returns: null (valid) or error message
  static String? validateEmail(String? value) {
    if (isNullOrEmpty(value)) {
      return 'Email is required';
    }
    if (!isEmail(value!)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validate password strength
  ///
  /// Example:
  ///   final error = AppHelper.validatePassword('MyPass123!');
  ///   // Returns: null (valid) or error message
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (isNullOrEmpty(value)) {
      return 'Password is required';
    }
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
