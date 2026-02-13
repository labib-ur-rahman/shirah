import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/modules/admins/home_feed/controllers/admin_feed_controller.dart';

/// Admin Feed Type Filter Chip - Horizontal scrollable chip row
///
/// Allows filtering feed items by type (Community Post, Micro Job, Native Ad, etc.)
class AdminFeedTypeFilterChip extends StatelessWidget {
  final AdminFeedController controller;

  const AdminFeedTypeFilterChip({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: SizedBox(
        height: 40.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          separatorBuilder: (_, __) => SizedBox(width: 8.w),
          itemCount: controller.feedTypeFilters.length,
          itemBuilder: (context, index) {
            final type = controller.feedTypeFilters[index];

            return Obx(() {
              final isSelected = controller.selectedType.value == type;

              return FilterChip(
                selected: isSelected,
                label: Text(
                  type.isEmpty
                      ? AppStrings.adminFeedAll
                      : controller.getTypeLabel(type),
                  style: getTextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.white
                        : isDark
                        ? AppColors.white
                        : AppColors.textSecondary,
                  ),
                ),
                avatar: type.isEmpty
                    ? null
                    : Icon(
                        controller.getTypeIcon(type),
                        size: 14,
                        color: isSelected
                            ? AppColors.white
                            : controller.getTypeColor(type),
                      ),
                selectedColor: type.isEmpty
                    ? AppColors.primary
                    : controller.getTypeColor(type),
                backgroundColor: isDark
                    ? AppColors.white.withValues(alpha: 0.06)
                    : AppColors.white,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : isDark
                      ? AppColors.white.withValues(alpha: 0.1)
                      : AppColors.grey.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                showCheckmark: false,
                onSelected: (_) => controller.filterByType(type),
              );
            });
          },
        ),
      ),
    );
  }
}
