import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';

class CreatePostShortcutActionButton extends StatelessWidget {
  const CreatePostShortcutActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.bgGradientColors,
    required this.borderColor,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final List<Color> bgGradientColors;
  final Color borderColor;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 1.3.h),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgGradientColors,
                ),
          color: isDark ? const Color(0xFF2A2A3E) : null,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : borderColor,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// -- Icon Container with Gradient
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            SizedBox(width: 8.w),

            /// -- Label
            Text(
              label,
              style: getBoldTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
