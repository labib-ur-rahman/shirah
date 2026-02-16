import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';

/// Operator selector widget - Horizontal list of Bangladesh operators
class OperatorSelector extends StatelessWidget {
  const OperatorSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = MobileRechargeController.instance;

    return Obx(() {
      final selected = controller.selectedOperator.value;
      return SizedBox(
        height: 72.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: MobileRechargeController.operators.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            final op = MobileRechargeController.operators[index];
            final isSelected = selected == op['code'];
            return _buildOperatorChip(
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
  }) {
    final bgColor = isSelected
        ? _operatorColor(name)
        : isDark
        ? const Color(0xFF1E1E2E)
        : Colors.white;
    final textColor = isSelected
        ? Colors.white
        : isDark
        ? Colors.white70
        : Colors.black87;
    final borderColor = isSelected
        ? _operatorColor(name)
        : isDark
        ? Colors.white12
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60.w,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _operatorColor(name).withValues(alpha: 0.3),
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
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _shortLabel(name),
              style: TextStyle(
                fontSize: 8.sp,
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
        return const Color(0xFF1C6B20); // Green
      case 'BL':
        return const Color(0xFFE87C03); // Orange
      case 'RB':
        return const Color(0xFFD41A29); // Red
      case 'AR':
        return const Color(0xFFE11C1C); // Red
      case 'TL':
        return const Color(0xFF0051A2); // Blue
      default:
        return Colors.grey;
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
