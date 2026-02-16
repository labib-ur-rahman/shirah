import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
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
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(() {
          // Access reactive variable to trigger rebuild
          final currentText = controller.selectedAmount.value;
          return Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: MobileRechargeController.quickAmounts.map((amount) {
              final isSelected = currentText == amount.toString();
              return _buildAmountChip(
                amount: amount,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => controller.selectQuickAmount(amount),
              );
            }).toList(),
          );
        }),
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
              ? const Color(0xFF4B68FF)
              : isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4B68FF)
                : isDark
                ? Colors.white12
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4B68FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '৳$amount',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}
