import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Modern image picker bottom sheet.
///
/// Usage:
/// ```dart
/// ImagePickerSheetWidget.show(
///   context,
///   title: AppStrings.pickerProfilePhoto,
///   onImageSelected: (file) => controller.uploadProfilePicture(file),
/// );
/// ```
class ImagePickerSheetWidget {
  const ImagePickerSheetWidget._();

  static final ImagePicker _picker = ImagePicker();

  /// Show the image source selection bottom sheet.
  static void show(
    BuildContext context, {
    required String title,
    required void Function(File file) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _PickerSheet(title: title, onImageSelected: onImageSelected),
    );
  }

  // ── Internal: pick from gallery ─────────────────────────────────────────

  static Future<void> _pickFromGallery(
    BuildContext context,
    void Function(File) onImageSelected,
  ) async {
    // On iOS, request photos permission. On Android, the native Photo Picker
    // (used by image_picker 1.x) does NOT require runtime permission.
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog(
          title: AppStrings.pickerPermissionDenied,
          message: AppStrings.pickerPermissionGalleryMsg,
        );
        return;
      }
      if (status.isDenied) return;
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (xFile != null) {
        onImageSelected(File(xFile.path));
      }
    } catch (e) {
      // Permission denied at OS level on Android < 13
      if (e.toString().contains('photo_access_denied') ||
          e.toString().contains('access') ||
          e.toString().contains('permission')) {
        _showPermissionDeniedDialog(
          title: AppStrings.pickerPermissionDenied,
          message: AppStrings.pickerPermissionGalleryMsg,
        );
      }
    }
  }

  // ── Internal: pick from camera ──────────────────────────────────────────

  static Future<void> _pickFromCamera(
    BuildContext context,
    void Function(File) onImageSelected,
  ) async {
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        title: AppStrings.pickerPermissionDenied,
        message: AppStrings.pickerPermissionCameraMsg,
      );
      return;
    }
    if (status.isDenied) return;

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (xFile != null) {
        onImageSelected(File(xFile.path));
      }
    } catch (_) {}
  }

  // ── Internal: permission denied dialog ──────────────────────────────────

  static void _showPermissionDeniedDialog({
    required String title,
    required String message,
  }) {
    final appColors = AppStyleColors.instance;
    Get.dialog(
      AlertDialog(
        backgroundColor: appColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          title,
          style: getBoldTextStyle(fontSize: 17, color: appColors.textPrimary),
        ),
        content: Text(
          message,
          style: getTextStyle(fontSize: 14, color: appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              AppStrings.cancel,
              style: getTextStyle(fontSize: 14, color: appColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text(
              AppStrings.pickerOpenSettings,
              style: getBoldTextStyle(fontSize: 14, color: appColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet UI
// ─────────────────────────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.onImageSelected});

  final String title;
  final void Function(File) onImageSelected;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;

    return Container(
      decoration: BoxDecoration(
        color: appColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: appColors.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: appColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Iconsax.camera,
                      size: 22.w,
                      color: appColors.primary,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      title,
                      style: getBoldTextStyle(
                        fontSize: 17,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: appColors.surface,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 18.w,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  // Gallery
                  Expanded(
                    child: _OptionCard(
                      icon: Iconsax.gallery,
                      label: AppStrings.pickerGallery,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.back();
                        ImagePickerSheetWidget._pickFromGallery(
                          context,
                          onImageSelected,
                        );
                      },
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Camera
                  Expanded(
                    child: _OptionCard(
                      icon: Iconsax.camera,
                      label: AppStrings.pickerCamera,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C950), Color(0xFF009966)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.back();
                        ImagePickerSheetWidget._pickFromCamera(
                          context,
                          onImageSelected,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 22.h),
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: appColors.border, width: 1.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 26.w, color: AppColors.white),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: getBoldTextStyle(
                fontSize: 13,
                color: appColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
