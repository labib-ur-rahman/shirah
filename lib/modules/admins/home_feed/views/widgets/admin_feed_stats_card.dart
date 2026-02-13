import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/modules/admins/home_feed/controllers/admin_feed_controller.dart';

/// Admin Feed Stats Card - Dashboard overview with KPI metrics
///
/// Displays 4 key stats in a 2x2 grid:
///   - Total Items
///   - Active Items
///   - Native Ads
///   - Disabled Items
class AdminFeedStatsCard extends StatelessWidget {
  final AdminFeedController controller;

  const AdminFeedStatsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.chart_215,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    AppStrings.adminFeedTitle,
                    style: getBoldTextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.white : AppColors.dark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Stats Grid
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.adminFeedTotalItems,
                        value: controller.totalItems.value.toString(),
                        icon: Iconsax.document,
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.adminFeedActiveItems,
                        value: controller.activeItems.value.toString(),
                        icon: Iconsax.tick_circle,
                        color: AppColors.success,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.adminFeedAdsCount,
                        value: controller.nativeAdItems.value.toString(),
                        icon: Iconsax.chart,
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.adminFeedDisabledCount,
                        value: controller.disabledItems.value.toString(),
                        icon: Iconsax.close_circle,
                        color: AppColors.error,
                        isDark: isDark,
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

/// Individual stat tile in the 2x2 grid
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.grey.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: getBoldTextStyle(
                    fontSize: 18,
                    color: isDark ? AppColors.white : AppColors.dark,
                  ),
                ),
                Text(
                  label,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
