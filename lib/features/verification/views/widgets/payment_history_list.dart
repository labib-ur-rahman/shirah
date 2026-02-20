import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/payment/payment_transaction_model.dart';
import 'package:shirah/features/verification/controllers/verification_controller.dart';

/// Payment History List
/// Shows user's past payment transactions for verification/subscription
class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VerificationController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (controller.isLoadingHistory.value &&
          controller.paymentHistory.isEmpty) {
        return _buildShimmer(isDark);
      }

      if (controller.paymentHistory.isEmpty) {
        return _buildEmpty(context, isDark);
      }

      return Column(
        children: [
          ...controller.paymentHistory.map(
            (tx) => _PaymentHistoryItem(transaction: tx, isDark: isDark),
          ),

          // Load more button
          if (controller.hasMoreHistory.value)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: TextButton(
                onPressed: controller.isLoadingHistory.value
                    ? null
                    : () => controller.loadPaymentHistory(),
                child: controller.isLoadingHistory.value
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.viewMore),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildShimmer(bool isDark) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: 8.h),
          height: 72.h,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.softGrey,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.softGrey,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.receipt_item,
            size: 40.w,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.verificationNoPayments,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Single payment history item
class _PaymentHistoryItem extends StatelessWidget {
  final PaymentTransactionModel transaction;
  final bool isDark;

  const _PaymentHistoryItem({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final controller = VerificationController.instance;
    final statusColor = controller.getStatusColor(transaction.status);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderSecondary,
        ),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              transaction.isVerification ? Iconsax.verify : Iconsax.crown,
              color: statusColor,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.isVerification
                      ? AppStrings.verificationPlanTitle
                      : AppStrings.subscriptionPlanTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatDate(transaction.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // Amount + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _statusLabel(transaction.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String _statusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return AppStrings.completed;
      case PaymentStatus.pending:
        return AppStrings.pending;
      case PaymentStatus.canceled:
        return AppStrings.cancelled;
      case PaymentStatus.failed:
        return AppStrings.failed;
    }
  }
}
