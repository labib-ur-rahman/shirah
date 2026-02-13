import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';

/// Feed Shimmer Card - Loading placeholder for feed items
/// Shows a realistic shimmer skeleton matching feed card structure
class FeedShimmerCard extends StatelessWidget {
  const FeedShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final shimmerColor = isDark
        ? const Color(0xFF2A2A3A)
        : const Color(0xFFE8E8E8);
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer (avatar + name + time)
          Row(
            children: [
              _shimmerBox(40.w, 40.w, shimmerColor, radius: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(120.w, 14.h, shimmerColor),
                    SizedBox(height: 6.h),
                    _shimmerBox(80.w, 10.h, shimmerColor),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Content shimmer
          _shimmerBox(double.infinity, 14.h, shimmerColor),
          SizedBox(height: 8.h),
          _shimmerBox(200.w, 14.h, shimmerColor),
          SizedBox(height: 16.h),

          // Image placeholder shimmer
          _shimmerBox(double.infinity, 180.h, shimmerColor, radius: 12),
          SizedBox(height: 16.h),

          // Action buttons shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _shimmerBox(60.w, 24.h, shimmerColor),
              _shimmerBox(60.w, 24.h, shimmerColor),
              _shimmerBox(60.w, 24.h, shimmerColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(
    double width,
    double height,
    Color color, {
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius.r),
      ),
    );
  }
}

/// Feed Shimmer List - Shows multiple shimmer cards for initial loading
class FeedShimmerList extends StatelessWidget {
  const FeedShimmerList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: const FeedShimmerCard(),
        ),
      ),
    );
  }
}
