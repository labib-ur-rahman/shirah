import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/local_storage_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';

/// ============================================================================
/// THEME SERVICE - Enterprise-Level Theme Management
/// ============================================================================
/// Centralized theme management service for instant, consistent theme switching
///
/// Features:
/// ✅ Single source of truth for theme state
/// ✅ Instant theme switching (0ms delay)
/// ✅ Auto-syncs with GetX, AppStyleColors, and Local Storage
/// ✅ Prevents memory leaks
/// ✅ Works with all GetX widgets (GetBuilder, Obx, etc.)
///
/// Usage:
///   // Change theme
///   ThemeService.changeTheme(ThemeMode.dark);
///
///   // Check theme
///   final isDark = ThemeService.isDarkMode;
///   final isDark = SLHelper.isDarkMode; // Recommended
///
///   // In UI (reactive)
///   GetBuilder<ThemeService>(
///     builder: (theme) => Container(
///       color: theme.isDarkMode ? Colors.black : Colors.white,
///     ),
///   );
/// ============================================================================
class ThemeService extends GetxController {
  static ThemeService get instance => Get.find<ThemeService>();

  // Current theme mode (reactive)
  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;

  /// Get current theme mode
  ThemeMode get themeMode => _themeMode.value;

  /// Check if dark mode
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  /// Check if light mode
  bool get isLightMode => _themeMode.value == ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }

  /// Load theme from storage on app start
  void _loadThemeFromStorage() {
    try {
      final savedTheme = LocalStorageService.getThemeMode();

      // Never use system mode
      if (savedTheme == ThemeMode.system) {
        _themeMode.value = ThemeMode.light;
        LocalStorageService.setThemeMode(ThemeMode.light);
      } else {
        _themeMode.value = savedTheme;
      }

      // Sync with AppStyleColors
      AppStyleColors.instance.setTheme(_themeMode.value);

      LoggerService.info('✅ Theme loaded: ${_themeMode.value.name}');
    } catch (e) {
      LoggerService.error('❌ Error loading theme', e);
      _themeMode.value = ThemeMode.light;
    }
  }

  /// Change theme with instant synchronization
  /// This is the ONLY method that should be used to change theme
  static Future<void> changeTheme(ThemeMode newTheme) async {
    try {
      final service = ThemeService.instance;

      // Prevent unnecessary updates
      if (service._themeMode.value == newTheme) {
        return;
      }

      // Update reactive variable
      service._themeMode.value = newTheme;

      // Save to storage (no await needed - void function)
      LocalStorageService.setThemeMode(newTheme);

      // Sync with AppStyleColors
      AppStyleColors.instance.setTheme(newTheme);

      // Apply to GetX (triggers full rebuild)
      Get.changeThemeMode(newTheme);

      // Force update all GetBuilders
      service.update();

      LoggerService.info('✅ Theme changed to: ${newTheme.name}');
    } catch (e) {
      LoggerService.error('❌ Error changing theme', e);
    }
  }

  /// Toggle between dark and light mode
  static Future<void> toggleTheme() async {
    final service = ThemeService.instance;
    final newTheme = service.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await changeTheme(newTheme);
  }

  /// Get current theme mode (static access)
  static ThemeMode get currentThemeMode => instance.themeMode;

  /// Check if dark mode (static access)
  static bool get isDark => instance.isDarkMode;

  /// Check if light mode (static access)
  static bool get isLight => instance.isLightMode;
}
