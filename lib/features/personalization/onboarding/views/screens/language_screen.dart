import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/lottie_path.dart';
import 'package:shirah/features/personalization/onboarding/controllers/onboarding_language_controller.dart';
import 'package:shirah/features/personalization/onboarding/controllers/theme_controller.dart';
import 'package:shirah/features/personalization/onboarding/views/widgets/animated_onboarding_screen.dart';
import 'package:shirah/features/personalization/onboarding/views/widgets/material_tab_selector.dart';
import 'package:shirah/features/personalization/onboarding/views/widgets/circular_lottie_animation.dart';

/// Language Selection Screen - Modern animated onboarding screen
/// Allows users to choose between English and Bangla languages with smooth animations
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.isFromSplash = true});

  final bool isFromSplash; // Flag to indicate if coming from splash screen

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingLanguageController());
    final themeController = ThemeController.instance;

    return Obx(() {
      final isBangla = controller.selectedLanguage.value.languageCode == 'bn';
      final lottieAsset = isBangla
          ? LottiePath.bangladeshFlag
          : LottiePath.allCountryFlags;

      // Get background color based on current theme mode
      final bgColor = themeController.getBackgroundColor();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: bgColor,
        child: AnimatedOnboardingScreen(
          lottieWidget: CircularLottieAnimation(
            lottieAsset: lottieAsset,
            size: 210,
          ),
          title: AppStrings.chooseLanguage,
          description: AppStrings.chooseLanguageSubtitle,
          selector: MaterialTabSelector(
            leftOption: AppStrings.english,
            rightOption: AppStrings.bangla,
            selectedIndex: isBangla ? 1 : 0,
            onToggle: (index) {
              if (index == 0) {
                controller.selectEnglish();
              } else {
                controller.selectBangla();
              }
            },
            backgroundColor: Colors.black,
            indicatorColor: Colors.white,
            height: 56,
            width: 340,
          ),
          onNext: () => controller.completeOnboarding(isFromSplash: isFromSplash),
          bottomText: isBangla ? 'বাংলা নির্বাচিত' : 'English selected',
          backgroundColor: bgColor,
          showBackgroundCircles: true,
          descriptionStyle: TextStyle(
            fontSize: 14,
            color: themeController.selectedTheme.value == ThemeMode.dark
                ? Colors.white70
                : const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      );
    });
  }
}
