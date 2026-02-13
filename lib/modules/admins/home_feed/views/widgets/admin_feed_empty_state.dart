import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Admin Feed Empty State - Displayed when no feed items match the filter
class AdminFeedEmptyState extends StatelessWidget {
  final bool isDark;

  const AdminFeedEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.05)
                    : AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.document_text,
                size: 48,
                color: isDark
                    ? AppColors.darkGrey
                    : AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppStrings.adminFeedEmpty,
              style: getBoldTextStyle(
                fontSize: 16,
                color: isDark ? AppColors.white : AppColors.dark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppStrings.adminFeedEmptySubtitle,
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
