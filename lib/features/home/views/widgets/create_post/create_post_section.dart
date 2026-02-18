import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/common/widgets/coming_soon_dialog.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/common/widgets/images/custom_circular_image.dart';
import 'package:shirah/core/services/logger_service.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/community/views/screens/create_post_screen.dart';
import 'package:shirah/features/home/views/widgets/create_post/create_post_shortcut_action_button.dart';
import 'package:shirah/features/micro_jobs/views/screens/create_micro_job_screen.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

/// Create Post Section - Post creation shortcut with action buttons
/// Displays user profile picture, text input placeholder, and quick action buttons
/// Design: Static section, always visible, no loading animation
class CreatePostSection extends StatelessWidget {
  const CreatePostSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final isDark = AppStyleColors.instance.isDarkMode;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// -- Profile & Input Row
              Row(
                children: [
                  /// -- Profile Picture
                  Obx(() {
                    final avatarUrl = UserController.instance.avatarUrl;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {},
                        child: avatarUrl.isNotEmpty
                            ? AppCircularImage(
                                width: 40.w,
                                height: 40.h,
                                padding: 0,
                                image: avatarUrl,
                                placeholder: Iconsax.user,
                                isNetworkImage: true,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: const Color(0xFF8B5CF6),
                                ),
                                child: const Icon(
                                  Iconsax.user,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                      ),
                    );
                  }),
                  SizedBox(width: 12.w),

                  /// -- Input Placeholder Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const CreatePostScreen(),
                          transition: Transition.rightToLeftWithFade,
                        );
                      },
                      child: Container(
                        height: 44.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.whatsOnMind,
                          style: getTextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : const Color(0xFF6A7282),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 15.h),

              /// -- Divider
              Container(
                height: 1.3.h,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
              ),

              SizedBox(height: 17.h),

              /// -- Action Buttons Row (Horizontal Scroll)
              SizedBox(
                height: 51.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    /// Image Button - Green
                    CreatePostShortcutActionButton(
                      icon: Iconsax.image,
                      label: 'Image',
                      gradientColors: const [
                        Color(0xFF00C950),
                        Color(0xFF009689),
                      ],
                      bgGradientColors: const [
                        Color(0xFFF0FDF4),
                        Color(0xFFF0FDFA),
                      ],
                      borderColor: const Color(0xFFDCFCE7),
                      textColor: const Color(0xFF008236),
                      isDark: isDark,
                      onTap: () => _pickImageAndNavigate(),
                    ),
                    SizedBox(width: 8.w),

                    /// Job Post Button - Purple/Pink
                    CreatePostShortcutActionButton(
                      icon: Iconsax.briefcase,
                      label: 'Job Post',
                      gradientColors: const [
                        Color(0xFFAD46FF),
                        Color(0xFFE60076),
                      ],
                      bgGradientColors: const [
                        Color(0xFFFAF5FF),
                        Color(0xFFFDF2F8),
                      ],
                      borderColor: const Color(0xFFF3E8FF),
                      textColor: const Color(0xFF8200DB),
                      isDark: isDark,
                      onTap: () {
                        Get.to(
                          () => const CreateMicroJobScreen(),
                          transition: Transition.rightToLeftWithFade,
                        );
                      },
                    ),
                    SizedBox(width: 8.w),

                    /// Sell Post Button - Blue
                    CreatePostShortcutActionButton(
                      icon: Iconsax.shopping_cart,
                      label: 'Sell Post',
                      gradientColors: const [
                        Color(0xFF2B7FFF),
                        Color(0xFF4F39F6),
                      ],
                      bgGradientColors: const [
                        Color(0xFFEFF6FF),
                        Color(0xFFEEF2FF),
                      ],
                      borderColor: const Color(0xFFDBEAFE),
                      textColor: const Color(0xFF1447E6),
                      isDark: isDark,
                      onTap: () {
                        ComingSoonDialog.show(
                          featureName: 'Sell Post',
                          featureIcon: Iconsax.shopping_cart,
                          accentColor: const Color(0xFF2B7FFF),
                        );
                      },
                    ),
                    SizedBox(width: 8.w),

                    /// Looking for Button - Orange
                    CreatePostShortcutActionButton(
                      icon: Iconsax.bag,
                      label: 'Looking for',
                      gradientColors: const [
                        Color(0xFFFF6900),
                        Color(0xFFE17100),
                      ],
                      bgGradientColors: const [
                        Color(0xFFFFF7ED),
                        Color(0xFFFFFBEB),
                      ],
                      borderColor: const Color(0xFFFFEDD4),
                      textColor: const Color(0xFFCA3500),
                      isDark: isDark,
                      onTap: () {
                        ComingSoonDialog.show(
                          featureName: 'Looking for',
                          featureIcon: Iconsax.bag,
                          accentColor: const Color(0xFFFF6900),
                        );
                      },
                    ),
                    SizedBox(width: 8.w),

                    /// Add Product Button - Teal/Green
                    CreatePostShortcutActionButton(
                      icon: Iconsax.trend_up,
                      label: 'Add Product',
                      gradientColors: const [
                        Color(0xFF00BC7D),
                        Color(0xFF00A63E),
                      ],
                      bgGradientColors: const [
                        Color(0xFFECFDF5),
                        Color(0xFFF0FDF4),
                      ],
                      borderColor: const Color(0xFFD0FAE5),
                      textColor: const Color(0xFF007A55),
                      isDark: isDark,
                      onTap: () {
                        ComingSoonDialog.show(
                          featureName: 'Add Product',
                          featureIcon: Iconsax.trend_up,
                          accentColor: const Color(0xFF00BC7D),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  /// Pick an image from gallery and navigate to CreatePostScreen with it
  Future<void> _pickImageAndNavigate() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        Get.to(
          () => CreatePostScreen(initialImage: File(image.path)),
          transition: Transition.rightToLeftWithFade,
        );
      }
    } catch (e) {
      LoggerService.error('Failed to pick image from CreatePostSection', e);
      Get.snackbar('Error', 'Failed to pick image');
    }
  }
}
