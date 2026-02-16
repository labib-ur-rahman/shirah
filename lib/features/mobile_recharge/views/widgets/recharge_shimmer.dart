import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shimmer loading placeholder for the recharge screen
class RechargeShimmer extends StatefulWidget {
  const RechargeShimmer({super.key});

  @override
  State<RechargeShimmer> createState() => _RechargeShimmerState();
}

class _RechargeShimmerState extends State<RechargeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = isDark
            ? Color.lerp(
                const Color(0xFF1E1E2E),
                const Color(0xFF2A2A3E),
                _animation.value,
              )!
            : Color.lerp(
                const Color(0xFFF3F4F6),
                const Color(0xFFE5E7EB),
                _animation.value,
              )!;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              // Operator selector shimmer
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Phone input shimmer
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 16.h),
              // Amount input shimmer
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 20.h),
              // Quick amounts shimmer
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: List.generate(
                  8,
                  (i) => Container(
                    width: 70.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // History shimmer
              ...List.generate(
                3,
                (i) => Container(
                  height: 72.h,
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
