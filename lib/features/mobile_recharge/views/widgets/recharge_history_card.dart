import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/data/models/recharge/recharge_model.dart';
import 'package:intl/intl.dart';

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
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            // Status icon
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

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recharge.operatorName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        recharge.formattedAmount,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
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
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
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
                          style: TextStyle(
                            fontSize: 9.sp,
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
                      'Cashback: ${recharge.formattedCashback}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Text(
                    _formatDate(recharge.createdAt),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
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
    if (recharge.isSuccess) return const Color(0xFF16A34A);
    if (recharge.isFailed) return const Color(0xFFDC2626);
    return const Color(0xFFF59E0B); // pending
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
