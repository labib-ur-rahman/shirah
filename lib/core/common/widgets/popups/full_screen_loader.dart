import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/widgets/loaders/animation_loader.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/core/utils/helpers/app_helper.dart';

/// A utility class for managing a full-screen loading dialog.
class SLFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  /// This method doesn't return anything.
  ///
  /// Parameters:
  ///   -  text: The text to be displayed in the loading dialog.
  ///   -  animation: The Lottie animation to be shown.
  static void openLoadingDialog(String text, String animation) {
    final isDark = AppHelper.isDarkMode;

    showDialog(
      context:
          Get.overlayContext!, // Use Get.overlayContext for overlay dialogs
      barrierDismissible:
          false, // The dialog can't be dismissed by tapping outside it
      builder: (_) => PopScope(
        canPop: false, // Disable popping with the back button
        child: Container(
          color: isDark ? AppColors.dark : AppColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 250), // Adjust the spacing as needed
              AppAnimationLoaderWidget(text: text, animation: animation),
            ],
          ),
        ),
      ),
    );
  }

  /// Stop the currently open loading dialog.
  /// This method doesn't return anything.
  static stopLoading() {
    Navigator.of(
      Get.overlayContext!,
    ).pop(); // Close the dialog using the Navigator
  }
}
