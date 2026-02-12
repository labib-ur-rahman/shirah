import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/local_storage_service.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/routes/app_routes.dart';

/// Theme Controller - Manages theme selection during onboarding
///
/// Responsibilities:
/// - Handle theme selection (Dark, Light only - NO System mode)
/// - Delegate to ThemeService for actual theme changes
/// - Navigate to language selection screen
///
/// Note: This controller is for UI state during onboarding only.
/// All theme logic is handled by ThemeService for consistency.
class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();

  // Selected theme mode (reactive) - defaults to light
  final Rx<ThemeMode> selectedTheme = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentTheme();
  }

  /// Load current theme from storage
  void _loadCurrentTheme() {
    try {
      final currentTheme = LocalStorageService.getThemeMode();
      // Always default to light mode, never use system mode
      if (currentTheme == ThemeMode.system) {
        selectedTheme.value = ThemeMode.light;
      } else {
        selectedTheme.value = currentTheme;
      }
      LoggerService.info('Current theme loaded: ${selectedTheme.value.name}');
    } catch (error) {
      LoggerService.error('Error loading theme', error);
      selectedTheme.value = ThemeMode.light;
    }
  }

  /// Select a theme - delegates to ThemeService
  void selectTheme(ThemeMode themeMode) {
    try {
      selectedTheme.value = themeMode;
      // Use ThemeService for centralized theme management
      ThemeService.changeTheme(themeMode);
      LoggerService.info('Theme changed to: ${themeMode.name}');
    } catch (error) {
      LoggerService.error('Error selecting theme', error);
    }
  }

  /// Check if a theme is selected
  bool isSelected(ThemeMode themeMode) {
    return selectedTheme.value == themeMode;
  }

  /// Get Lottie path for current theme
  String getLottiePath() {
    switch (selectedTheme.value) {
      case ThemeMode.dark:
        return 'assets/lottie/dark_night.json';
      case ThemeMode.light:
      case ThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        return 'assets/lottie/light_sun_spin.json';
    }
  }

  /// Get background color for current theme
  Color getBackgroundColor() {
    switch (selectedTheme.value) {
      case ThemeMode.dark:
        return const Color(0xFF1A1A2E);
      case ThemeMode.light:
      case ThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        return const Color(0xFFEEEFFC);
    }
  }

  /// Navigate to language selection screen
  void navigateToLanguageScreen() {
    try {
      LoggerService.info('Navigating to Language Selection Screen');
      Get.toNamed(AppRoutes.getLanguageScreen());
    } catch (error) {
      LoggerService.error('Error navigating to language screen', error);
    }
  }

  /// Skip theme selection and navigate to next screen
  void skipThemeSelection({required bool isFromSplash}) {
    try {
      // Use ThemeService to save and apply theme
      ThemeService.changeTheme(selectedTheme.value);
      LoggerService.info(
        'Theme saved and applied: ${selectedTheme.value.name}',
      );

      // Small delay to ensure theme is fully applied before navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (isFromSplash) {
          Get.offNamed(AppRoutes.ONBOARDING);
        } else {
          Get.back();
        }
      });
    } catch (error) {
      LoggerService.error('Error saving theme selection', error);
      Get.toNamed(AppRoutes.ONBOARDING);
    }
  }
}
