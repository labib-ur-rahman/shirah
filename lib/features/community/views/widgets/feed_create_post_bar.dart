import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/community/views/screens/create_post_screen.dart';

/// Feed Create Post Bar - Compact bar at top of feed for quick post creation
/// Tapping text input → opens Create Post screen
/// Tapping Image → picks image then opens Create Post screen with image
class FeedCreatePostBar extends StatelessWidget {
  const FeedCreatePostBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyleColors.instance.isDarkMode;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: 16.h,
      ),
      decoration: BoxDecoration(
        color: AppStyleColors.instance.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          /// Avatar placeholder
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
            ),
            child: Icon(
              Iconsax.user,
              size: 20.sp,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
          SizedBox(width: 10.w),

          /// Input placeholder
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCreatePost(),
              child: Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  "What's on your mind?",
                  style: getTextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          /// Image button
          GestureDetector(
            onTap: () => _pickImageAndNavigate(),
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFDCFCE7),
                ),
              ),
              child: Icon(
                Iconsax.image,
                size: 20.sp,
                color: const Color(0xFF00C950),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to create post screen (no image)
  void _navigateToCreatePost() {
    Get.to(
      () => const CreatePostScreen(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 350),
    );
  }

  /// Pick image first, then navigate to create post with image
  Future<void> _pickImageAndNavigate() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        Get.to(
          () => CreatePostScreen(initialImage: File(image.path)),
          transition: Transition.downToUp,
          duration: const Duration(milliseconds: 350),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }
}
