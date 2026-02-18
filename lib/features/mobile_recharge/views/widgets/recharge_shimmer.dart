import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/utils/constants/colors.dart';

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
                AppColors.dark,
                AppColors.darkerGrey,
                _animation.value,
              )!
            : Color.lerp(AppColors.softGrey, AppColors.grey, _animation.value)!;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),

              /// -- Operator selector shimmer
              Row(
                children: List.generate(
                  5,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Container(
                      width: 62.w,
                      height: 76.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              /// -- Toggle shimmer
              Row(
                children: [
                  Container(
                    width: 100.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 100.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              /// -- Phone input shimmer
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 16.h),

              /// -- Amount input shimmer
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 20.h),

              /// -- Quick amounts shimmer
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
              SizedBox(height: 24.h),

              /// -- Button shimmer
              Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              SizedBox(height: 28.h),

              /// -- History shimmer
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
