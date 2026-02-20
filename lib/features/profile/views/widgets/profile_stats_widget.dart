import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';

class ProfileStatsWidget extends StatelessWidget {
  const ProfileStatsWidget({
    super.key,
    required this.posts,
    required this.followers,
    required this.following,
  });

  final String posts;
  final String followers;
  final String following;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: posts,
            label: AppStrings.posts,
            valueColor: const Color(0xFF00A63E),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _StatCard(
            value: followers,
            label: AppStrings.profileFollowers,
            valueColor: const Color(0xFF155DFC),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _StatCard(
            value: following,
            label: AppStrings.profileFollowing,
            valueColor: const Color(0xFF9810FA),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: appColors.border, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: appColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: getBoldTextStyle(fontSize: 22, color: valueColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: getTextStyle(fontSize: 12, color: appColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
