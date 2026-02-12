import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/features/community/controllers/create_post_controller.dart';
import 'package:shirah/routes/app_routes.dart';

/// Create Post Screen - Modern enterprise-level community post creation
/// Features: Multi-line text, image attachment, privacy selection, post button
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key, this.initialImage});

  /// Optional initial image (when user picks image from home feed)
  final File? initialImage;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    // Inject controller
    final controller = Get.put(CreatePostController());

    // Set initial image if provided
    if (initialImage != null && controller.selectedImage.value == null) {
      controller.selectedImage.value = initialImage;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      appBar: _buildAppBar(controller, isDark, colors),
      body: SafeArea(
        child: Column(
          children: [
            /// -- Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    /// -- Author Header
                    _buildAuthorHeader(controller, isDark),

                    SizedBox(height: 16.h),

                    /// -- Text Input
                    _buildTextInput(controller, isDark),

                    SizedBox(height: 16.h),

                    /// -- Image Preview
                    Obx(
                      () => controller.selectedImage.value != null
                          ? _buildImagePreview(controller, isDark)
                          : const SizedBox.shrink(),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            /// -- Bottom Action Bar
            _buildBottomBar(controller, isDark, colors),
          ],
        ),
      ),
    );
  }

  /// App Bar with Post button
  PreferredSizeWidget _buildAppBar(
    CreatePostController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      title: Text(
        'Create Post',
        style: getBoldTextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: Obx(() {
            final posting = controller.isPosting.value;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilledButton(
                onPressed: posting ? null : () => controller.submitPost(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFE5E7EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                ),
                child: posting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : Text(
                        'Post',
                        style: getBoldTextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6),
        ),
      ),
    );
  }

  /// Author header with avatar, name, and privacy selector
  Widget _buildAuthorHeader(CreatePostController controller, bool isDark) {
    return Row(
      children: [
        /// -- Avatar
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.COMMUNITY),
          child: Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
              image: controller.currentAuthor.photo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(controller.currentAuthor.photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: controller.currentAuthor.photo.isEmpty
                ? Icon(
                    Iconsax.user,
                    size: 24.sp,
                    color: isDark ? Colors.white38 : Colors.grey,
                  )
                : null,
          ),
        ),
        SizedBox(width: 12.w),

        /// -- Name & Privacy
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.currentAuthor.name.isNotEmpty
                  ? controller.currentAuthor.name
                  : 'User',
              style: getBoldTextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1E2939),
              ),
            ),
            SizedBox(height: 4.h),

            /// -- Privacy Selector Chip
            Obx(() => _buildPrivacyChip(controller, isDark)),
          ],
        ),
      ],
    );
  }

  /// Privacy dropdown chip
  Widget _buildPrivacyChip(CreatePostController controller, bool isDark) {
    final privacy = controller.selectedPrivacy.value;

    return GestureDetector(
      onTap: () => _showPrivacyPicker(controller, isDark),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPrivacyIcon(privacy),
              size: 14.sp,
              color: isDark ? Colors.white60 : const Color(0xFF6A7282),
            ),
            SizedBox(width: 6.w),
            Text(
              PostPrivacy.displayName(privacy),
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF6A7282),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Iconsax.arrow_down_1,
              size: 12.sp,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  /// Privacy picker bottom sheet
  void _showPrivacyPicker(CreatePostController controller, bool isDark) {
    // Dismiss keyboard before showing bottom sheet
    FocusManager.instance.primaryFocus?.unfocus();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -- Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                'Who can see this post?',
                style: getBoldTextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1E2939),
                ),
              ),
              SizedBox(height: 16.h),

              /// -- Privacy Options
              ...PostPrivacy.values.map(
                (p) => _buildPrivacyOption(controller, p, isDark),
              ),

              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Single privacy option in bottom sheet
  Widget _buildPrivacyOption(
    CreatePostController controller,
    String privacy,
    bool isDark,
  ) {
    return Obx(() {
      final isSelected = controller.selectedPrivacy.value == privacy;
      return ListTile(
        onTap: () {
          controller.setPrivacy(privacy);
          Get.back();
        },
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isSelected
                ? AppStyleColors.instance.primary.withValues(alpha: 0.1)
                : isDark
                ? const Color(0xFF2A2A3E)
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getPrivacyIcon(privacy),
            size: 20.sp,
            color: isSelected
                ? AppStyleColors.instance.primary
                : isDark
                ? Colors.white54
                : const Color(0xFF6A7282),
          ),
        ),
        title: Text(
          PostPrivacy.displayName(privacy),
          style: getBoldTextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1E2939),
          ),
        ),
        subtitle: Text(
          _getPrivacyDescription(privacy),
          style: getTextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Iconsax.tick_circle5,
                color: AppStyleColors.instance.primary,
                size: 20.sp,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      );
    });
  }

  /// Multi-line text input
  Widget _buildTextInput(CreatePostController controller, bool isDark) {
    return TextField(
      controller: controller.textController,
      maxLines: null,
      minLines: 5,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: getTextStyle(
        fontSize: 18,
        color: isDark ? Colors.white : const Color(0xFF1E2939),
      ),
      decoration: InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: getTextStyle(
          fontSize: 18,
          color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (_) {
        // Trigger rebuild to update post button state
        controller.update();
      },
    );
  }

  /// Image preview with remove button
  Widget _buildImagePreview(CreatePostController controller, bool isDark) {
    return Stack(
      children: [
        /// -- Image
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.file(
            controller.selectedImage.value!,
            width: double.infinity,
            height: 260.h,
            fit: BoxFit.cover,
          ),
        ),

        /// -- Remove button
        Positioned(
          top: 10.h,
          right: 10.w,
          child: GestureDetector(
            onTap: controller.removeImage,
            child: Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.close_circle,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom action bar with image/camera buttons
  Widget _buildBottomBar(
    CreatePostController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
          ),
        ),
      ),
      child: Row(
        children: [
          /// -- Gallery button
          _buildBottomAction(
            icon: Iconsax.image,
            label: 'Photo',
            color: const Color(0xFF00C950),
            isDark: isDark,
            onTap: controller.pickImageFromGallery,
          ),
          SizedBox(width: 16.w),

          /// -- Camera button
          _buildBottomAction(
            icon: Iconsax.camera,
            label: 'Camera',
            color: const Color(0xFF2B7FFF),
            isDark: isDark,
            onTap: controller.pickImageFromCamera,
          ),

          const Spacer(),

          /// -- Privacy indicator
          Obx(() {
            final privacy = controller.selectedPrivacy.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPrivacyIcon(privacy),
                  size: 16.sp,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                ),
                SizedBox(width: 4.w),
                Text(
                  PostPrivacy.displayName(privacy),
                  style: getTextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Bottom action button (Photo/Camera)
  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: getTextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF6A7282),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Helpers ====================

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case PostPrivacy.friends:
        return Iconsax.people;
      case PostPrivacy.onlyMe:
        return Iconsax.lock;
      default:
        return Iconsax.global;
    }
  }

  String _getPrivacyDescription(String privacy) {
    switch (privacy) {
      case PostPrivacy.friends:
        return 'Only your friends can see this post';
      case PostPrivacy.onlyMe:
        return 'Only you can see this post';
      default:
        return 'Everyone can see this post';
    }
  }
}
