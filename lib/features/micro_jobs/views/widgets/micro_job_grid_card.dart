import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';

/// Micro Job Grid Card - Compact card for 2-column grid display
/// Shows cover image, title, price per task, and remaining/total slots
class MicroJobGridCard extends StatelessWidget {
  const MicroJobGridCard({super.key, required this.job, required this.onTap});

  final MicroJobModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyleColors.instance.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Cover Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 100.h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: job.coverImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        child: Center(
                          child: Icon(
                            Iconsax.image,
                            size: 24.sp,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        child: Center(
                          child: Icon(
                            Iconsax.image,
                            size: 24.sp,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),

                    /// -- Price badge overlay
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '৳${job.perUserPrice.toStringAsFixed(0)}',
                          style: getBoldTextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// -- Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// -- Title
                    Text(
                      job.title,
                      style: getBoldTextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    /// -- Bottom Row: Slots remaining
                    Row(
                      children: [
                        Icon(
                          Iconsax.people,
                          size: 13.sp,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${job.remainingSlots}/${job.limit} left',
                            style: getTextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
