import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';

/// Operator selector widget - Horizontal list of Bangladesh operators
class OperatorSelector extends StatelessWidget {
  const OperatorSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = MobileRechargeController.instance;
    final appStyleColors = AppStyleColors.instance;

    return Obx(() {
      final selected = controller.selectedOperator.value;
      return SizedBox(
        height: 76.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: MobileRechargeController.operators.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            final op = MobileRechargeController.operators[index];
            final isSelected = selected == op['code'];
            return _buildOperatorChip(
              appStyleColors: appStyleColors,
              name: op['short']!,
              fullName: op['name']!,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => controller.selectOperator(op['code']!),
            );
          },
        ),
      );
    });
  }

  Widget _buildOperatorChip({
    required String name,
    required String fullName,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    required AppStyleColors appStyleColors,
  }) {
    final opColor = _operatorColor(name);
    final bgColor = isSelected
        ? opColor
        : appStyleColors.primary.withValues(alpha: 0.05);
    final textColor = isSelected
        ? AppColors.white
        : isDark
        ? AppColors.white
        : AppColors.dark;
    final borderColor = isSelected
        ? opColor
        : isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 62.w,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: opColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: getBoldTextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _shortLabel(name),
              style: getTextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _operatorColor(String op) {
    switch (op) {
      case 'GP':
        return const Color(0xFF1C6B20);
      case 'BL':
        return const Color(0xFFE87C03);
      case 'RB':
        return const Color(0xFFD41A29);
      case 'AR':
        return const Color(0xFFE11C1C);
      case 'TL':
        return const Color(0xFF0051A2);
      default:
        return AppColors.darkGrey;
    }
  }

  String _shortLabel(String op) {
    switch (op) {
      case 'GP':
        return 'Grameenphone';
      case 'BL':
        return 'Banglalink';
      case 'RB':
        return 'Robi';
      case 'AR':
        return 'Airtel';
      case 'TL':
        return 'Teletalk';
      default:
        return '';
    }
  }
}
