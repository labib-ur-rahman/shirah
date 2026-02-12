import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/micro_jobs/controllers/micro_job_controller.dart';

/// Job Proof Bottom Sheet - Multi-image screenshot + message submission
/// Shows image picker grid, message input, and submit button
/// One user can submit proof only once per job
class JobProofBottomSheet extends StatelessWidget {
  const JobProofBottomSheet({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyleColors.instance.isDarkMode;
    final controller = MicroJobController.instance;

    // Clear previous proof data
    // controller.proofImages.clear();
    // controller.proofMessageController.clear();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// -- Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          /// -- Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.camera,
                    size: 20.sp,
                    color: const Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Proof',
                        style: getBoldTextStyle(
                          fontSize: 18,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E2939),
                        ),
                      ),
                      Text(
                        'Upload screenshots & add a message',
                        style: getTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(
                    Iconsax.close_circle,
                    size: 24.sp,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          /// -- Divider
          Container(
            height: 1.h,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
          ),

          /// -- Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  /// -- Screenshots Section Label
                  Text(
                    'Screenshots *',
                    style: getBoldTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Add up to 5 screenshots as proof of task completion',
                    style: getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  /// -- Image Grid
                  _buildImageGrid(controller, isDark),
                  SizedBox(height: 24.h),

                  /// -- Message Section Label
                  Text(
                    'Message (Optional)',
                    style: getBoldTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  /// -- Message Input
                  TextFormField(
                    controller: controller.proofMessageController,
                    maxLines: 4,
                    minLines: 3,
                    maxLength: 500,
                    style: getTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E2939),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe what you did to complete the task...',
                      hintStyle: getTextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFF9CA3AF),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F0F1A)
                          : const Color(0xFFF9FAFB),
                      counterStyle: getTextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFF9CA3AF),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          /// -- Bottom: Submit Button
          _buildSubmitSection(controller, isDark),
        ],
      ),
    );
  }

  // ==================== Image Grid ====================

  Widget _buildImageGrid(MicroJobController controller, bool isDark) {
    return Obx(() {
      final images = controller.proofImages;
      final canAddMore = images.length < 5;

      return Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: [
          // Existing images
          ...images.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildImageTile(file, index, controller, isDark);
          }),

          // Add button
          if (canAddMore) _buildAddImageTile(controller, isDark),
        ],
      );
    });
  }

  Widget _buildImageTile(
    File file,
    int index,
    MicroJobController controller,
    bool isDark,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.file(file, width: 90.w, height: 90.h, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4.h,
          right: 4.w,
          child: GestureDetector(
            onTap: () => controller.proofImages.removeAt(index),
            child: Container(
              width: 22.w,
              height: 22.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.close_circle,
                size: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile(MicroJobController controller, bool isDark) {
    return GestureDetector(
      onTap: controller.pickProofImages,
      child: Container(
        width: 90.w,
        height: 90.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.add,
              size: 24.sp,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            ),
            SizedBox(height: 4.h),
            Obx(
              () => Text(
                '${controller.proofImages.length}/5',
                style: getTextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Submit Section ====================

  Widget _buildSubmitSection(MicroJobController controller, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final hasImages = controller.proofImages.isNotEmpty;
        final isSubmitting = controller.isSubmittingProof.value;

        return SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: (hasImages && !isSubmitting)
                ? () => controller.submitProof(jobId)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFE5E7EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: (hasImages && !isSubmitting)
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: (hasImages && !isSubmitting)
                    ? null
                    : (isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Container(
                alignment: Alignment.center,
                child: isSubmitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.send_1,
                            size: 18.sp,
                            color: hasImages
                                ? Colors.white
                                : (isDark
                                      ? Colors.white30
                                      : const Color(0xFF9CA3AF)),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Submit Proof',
                            style: getBoldTextStyle(
                              fontSize: 16,
                              color: hasImages
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white30
                                        : const Color(0xFF9CA3AF)),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
