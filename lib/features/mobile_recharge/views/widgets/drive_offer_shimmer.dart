import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              SizedBox(height: 12.h),
              // Filter chips shimmer
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
              // Offer card shimmers (reduced to 3 for better fit)
              ...List.generate(
                3,
                (i) => Container(
                  height: 110.h,
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
