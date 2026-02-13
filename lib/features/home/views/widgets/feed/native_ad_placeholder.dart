import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';

/// Native Ad Placeholder - Shown while AdMob native ad is loading
/// Displays a clear "Ad" badge per Google Play policy
class NativeAdPlaceholder extends StatelessWidget {
  const NativeAdPlaceholder({super.key, this.adUnitId});

  final String? adUnitId;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad badge
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  AppStrings.feedAdBadge,
                  style: getBoldTextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Iconsax.info_circle,
                size: 16.sp,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Ad loading placeholder
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.softGrey,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.image,
                    size: 32.sp,
                    color: isDark ? Colors.white24 : AppColors.darkGrey,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppStrings.feedAdLoading,
                    style: getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
