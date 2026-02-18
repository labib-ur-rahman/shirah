import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';

/// Quick amount selector grid for mobile recharge
class AmountSelector extends StatelessWidget {
  const AmountSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MobileRechargeController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectAmount,
          style: getBoldTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.7)
                : AppColors.dark,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 44.h,
          child: Obx(() {
            final currentText = controller.selectedAmount.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: MobileRechargeController.quickAmounts.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final amount = MobileRechargeController.quickAmounts[index];
                final isSelected = currentText == amount.toString();
                return _buildAmountChip(
                  amount: amount,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => controller.selectQuickAmount(amount),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAmountChip({
    required int amount,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppStyleColors.instance.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.grey,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '৳$amount',
            style: getBoldTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.white
                  : isDark
                  ? AppColors.white.withValues(alpha: 0.7)
                  : AppColors.dark,
            ),
          ),
        ),
      ),
    );
  }
}
