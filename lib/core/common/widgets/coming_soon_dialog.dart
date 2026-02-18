import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';

/// Modern Coming Soon Dialog
/// Shows a beautiful animated coming soon dialog for features under development
class ComingSoonDialog extends StatelessWidget {
  final String featureName;
  final IconData featureIcon;
  final Color accentColor;

  const ComingSoonDialog({
    super.key,
    required this.featureName,
    required this.featureIcon,
    required this.accentColor,
  });

  /// Show the dialog as a bottom sheet-style dialog
  static void show({
    required String featureName,
    required IconData featureIcon,
    required Color accentColor,
  }) {
    Get.dialog(
      ComingSoonDialog(
        featureName: featureName,
        featureIcon: featureIcon,
        accentColor: accentColor,
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.all(Radius.circular(28.r)),
        ),
        child: Container(
          margin: EdgeInsets.only(top: 3.h),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 32.h, 28.w, 28.h),
                child: Column(
                  children: [
                    // ── Animated Icon Container
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.08),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.12),
                          ),
                        ),
                        // Inner icon container
                        Container(
                          width: 62.w,
                          height: 62.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            featureIcon,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // ── Coming Soon Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.clock, size: 13.sp, color: accentColor),
                          SizedBox(width: 5.w),
                          Text(
                            'Coming Soon',
                            style: getK2DTextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // ── Feature Name
                    Text(
                      featureName,
                      style: getK2DTextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 10.h),

                    // ── Description
                    Text(
                      'We\'re working hard to bring you this feature. Stay tuned for an exciting update!',
                      style: getTextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        lineHeight: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 28.h),

                    // ── Features list chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FeatureChip(
                          icon: Iconsax.shield_tick,
                          label: 'Secure',
                          accentColor: accentColor,
                        ),
                        SizedBox(width: 10.w),
                        _FeatureChip(
                          icon: Iconsax.flash_1,
                          label: 'Fast',
                          accentColor: accentColor,
                        ),
                        SizedBox(width: 10.w),
                        _FeatureChip(
                          icon: Iconsax.star,
                          label: 'Premium',
                          accentColor: accentColor,
                        ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    // ── Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.transparent),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.notification, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Notify Me When Ready',
                              style: getK2DTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // ── Maybe Later
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Maybe Later',
                        style: getTextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small feature chip label
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: accentColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: getTextStyle(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
