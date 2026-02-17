import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/recharge/recharge_model.dart';

/// Recharge history item card
class RechargeHistoryCard extends StatelessWidget {
  final RechargeModel recharge;
  final VoidCallback? onTap;

  const RechargeHistoryCard({super.key, required this.recharge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppStyleColors
              .instance
              .surface, // Use app style color for better theming
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? AppColors.white.withValues(alpha: 0.06)
                : AppColors.grey.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            /// -- Status icon
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 20.sp),
            ),
            SizedBox(width: 12.w),

            /// -- Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recharge.operatorName,
                        style: getBoldTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : AppColors.dark,
                        ),
                      ),
                      Text(
                        recharge.formattedAmount,
                        style: getBoldTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${recharge.phone} • ${recharge.typeDisplay}',
                        style: getTextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.white.withValues(alpha: 0.54)
                              : AppColors.darkerGrey,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          recharge.displayStatus,
                          style: getBoldTextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (recharge.isSuccess && recharge.cashback.amount > 0) ...[
                    SizedBox(height: 3.h),
                    Text(
                      '${AppStrings.cashback}: ${recharge.formattedCashback}',
                      style: getBoldTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Text(
                    _formatDate(recharge.createdAt),
                    style: getTextStyle(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.38)
                          : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    if (recharge.isSuccess) return AppColors.success;
    if (recharge.isFailed) return AppColors.error;
    return AppColors.warning;
  }

  IconData get _statusIcon {
    if (recharge.isSuccess) return Iconsax.tick_circle;
    if (recharge.isFailed) return Iconsax.close_circle;
    return Iconsax.clock;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
