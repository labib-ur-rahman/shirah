import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Feed Empty State - Shown when there are no feed items
class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.document_text,
              size: 64.sp,
              color: isDark ? Colors.white24 : AppColors.darkGrey,
            ),
            SizedBox(height: 16.h),
            Text(
              AppStrings.feedEmpty,
              style: getBoldTextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.feedEmptySubtitle,
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            if (onRefresh != null)
              TextButton.icon(
                onPressed: onRefresh,
                icon: Icon(Iconsax.refresh, size: 18.sp),
                label: Text(AppStrings.refresh),
                style: TextButton.styleFrom(foregroundColor: colors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
