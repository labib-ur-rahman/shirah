import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Shimmer loading placeholder for drive offers list
class DriveOfferShimmer extends StatefulWidget {
  const DriveOfferShimmer({super.key});

  @override
  State<DriveOfferShimmer> createState() => _DriveOfferShimmerState();
}

class _DriveOfferShimmerState extends State<DriveOfferShimmer>
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
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              SizedBox(height: 12.h),

              /// -- Filter chips shimmer
              Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Container(
                      width: 70.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              /// -- Offer card shimmers
              ...List.generate(
                4,
                (i) => Container(
                  height: 120.h,
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16.r),
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
