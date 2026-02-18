import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/common/utils/in_app_browser.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/micro_jobs/views/screens/micro_job_detail_screen.dart';
import 'package:shirah/routes/app_routes.dart';

/// Micro Job Card - Figma design implementation
/// Shows: Green badge, title, description, image, task link button, stats, complete button
/// Design matches Figma: Clean card with Stack-based green left border
class MicroJobCard extends StatelessWidget {
  const MicroJobCard({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.description,
    this.imageUrl,
    this.taskLink,
    this.perTaskAmount = '৳1',
    this.perTaskPoints = 5,
    this.completedTasks = 230,
    this.totalTasks = 500,
    this.onTaskLinkPressed,
    this.onCompletePressed,
  });

  final String jobTitle;
  final String description;
  final String jobId;
  final String? imageUrl;
  final String? taskLink;
  final String perTaskAmount;
  final int perTaskPoints;
  final int completedTasks;
  final int totalTasks;
  final VoidCallback? onTaskLinkPressed;
  final VoidCallback? onCompletePressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    void openDetail() {
      if (jobId.isEmpty) return;
      Get.to(
        () => MicroJobDetailScreen(jobId: jobId),
        transition: Transition.rightToLeftWithFade,
        duration: const Duration(milliseconds: 250),
      );
    }

    /// Outer container with green left border using Stack
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16.r),
      ),

      /// -- Inner card with white/dark background and padding
      child: Container(
        margin: EdgeInsets.only(left: 3.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Header with Green Badge and Title in same line
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -- Green Circle Icon
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.getMicroJobsScreen()),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF05DF72), Color(0xFF00A63E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.briefcase,
                        size: 22.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),

                  /// -- Title and MICRO JOB in one column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: openDetail,
                          child: Text(
                            jobTitle,
                            style: getBoldTextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E2939),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        GestureDetector(
                          onTap: () =>
                              Get.toNamed(AppRoutes.getMicroJobsScreen()),
                          child: Row(
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C950),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'MICRO JOB',
                                style: getBoldTextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF00A63E),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 0, 128, 255),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'GROW BUSINESS',
                                style: getBoldTextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 0, 128, 255),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// -- Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final baseStyle = getTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : const Color(0xFF4A5565),
                  );
                  final seeMoreStyle = getBoldTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF4A5565),
                  );

                  final tp = TextPainter(
                    text: TextSpan(text: description, style: baseStyle),
                    textDirection: TextDirection.ltr,
                    maxLines: 3,
                  )..layout(maxWidth: constraints.maxWidth);
                  final isOverflow = tp.didExceedMaxLines;

                  String truncateToFit(
                    String text,
                    double maxWidth,
                    int maxLines,
                  ) {
                    var low = 0;
                    var high = text.length;
                    var best = '';
                    while (low <= high) {
                      final mid = (low + high) ~/ 2;
                      final candidate = text.substring(0, mid).trimRight();
                      final testPainter = TextPainter(
                        textDirection: TextDirection.ltr,
                        maxLines: maxLines,
                        text: TextSpan(
                          style: baseStyle,
                          children: [
                            TextSpan(text: candidate),
                            const TextSpan(text: '… '),
                            TextSpan(text: 'See More', style: seeMoreStyle),
                          ],
                        ),
                      )..layout(maxWidth: maxWidth);
                      if (testPainter.didExceedMaxLines) {
                        high = mid - 1;
                      } else {
                        best = candidate;
                        low = mid + 1;
                      }
                    }
                    return best;
                  }

                  return GestureDetector(
                    onTap: openDetail,
                    behavior: HitTestBehavior.opaque,
                    child: isOverflow
                        ? RichText(
                            maxLines: 3,
                            overflow: TextOverflow.clip,
                            text: TextSpan(
                              style: baseStyle,
                              children: [
                                TextSpan(
                                  text: truncateToFit(
                                    description,
                                    constraints.maxWidth,
                                    3,
                                  ),
                                ),
                                const TextSpan(text: '… '),
                                TextSpan(text: 'See More', style: seeMoreStyle),
                              ],
                            ),
                          )
                        : Text(
                            description,
                            style: baseStyle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                  );
                },
              ),
            ),

            SizedBox(height: 10.h),

            /// -- Image (if provided)
            if (imageUrl != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(1.3.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Color(0xFF00C950).withValues(alpha: 0.3),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    onTap: openDetail,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: double.infinity,
                      height: 300.h,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 300.h,
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: 300.h,
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        child: Icon(
                          Iconsax.image,
                          size: 40.sp,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            /// -- Open Task Link Button (Blue to Purple Gradient)
            if (taskLink != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                width: double.infinity,
                height: 52.h,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF2B7FFF), Color(0xFF9810FA)],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: InkWell(
                      onTap: taskLink == null
                          ? null
                          : () {
                              if (onTaskLinkPressed != null) {
                                onTaskLinkPressed!.call();
                                return;
                              }
                              InAppBrowser.open(
                                context,
                                url: taskLink!,
                                toolbarColor: const Color(0xFF2B7FFF),
                              );
                            },
                      borderRadius: BorderRadius.circular(14.r),
                      splashColor: Colors.white.withValues(alpha: 0.15),
                      highlightColor: Colors.white.withValues(alpha: 0.08),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Transform.translate(
                              offset: const Offset(-60, 0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0x33FFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.w, right: 14.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Iconsax.export_2,
                                    size: 18.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Open Task Link',
                                      style: getBoldTextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Iconsax.arrow_right_3,
                                  size: 18.sp,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            /// -- Stats Row (Per task & Remaining)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  /// -- Per Task (Green background)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: const Color(0xFFDCFCE7),
                          width: 1.3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Per task',
                            style: getTextStyle(
                              fontSize: 12,
                              color: const Color(0xFF4A5565),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                perTaskAmount,
                                style: getBoldTextStyle(
                                  fontSize: 20,
                                  color: const Color(0xFF00A63E),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00A63E,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999.r),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00A63E,
                                    ).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  '+ $perTaskPoints Points',
                                  style: getBoldTextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF00A63E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),

                  /// -- Remaining (Orange background)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: const Color(0xFFFFD6A7),
                          width: 1.3,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -24.h,
                            right: -8.w,
                            child: Container(
                              width: 64.w,
                              height: 64.w,
                              decoration: BoxDecoration(
                                color: const Color(0x33FFD6A8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              14.w,
                              12.h,
                              14.w,
                              10.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remaining',
                                  style: getTextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF4A5565),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Text(
                                      '$completedTasks/$totalTasks',
                                      style: getBoldTextStyle(
                                        fontSize: 20,
                                        color: const Color(0xFFF54900),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(
                                      Iconsax.clock,
                                      size: 14.sp,
                                      color: const Color(0xFFF54900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            /// -- Complete and Earn Button (Green Gradient)
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              width: double.infinity,
              height: 52.h,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF00C950),
                        Color(0xFF00BC7D),
                        Color(0xFF009689),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      onCompletePressed?.call();
                      openDetail();
                    },
                    borderRadius: BorderRadius.circular(14.r),
                    splashColor: Colors.white.withValues(alpha: 0.15),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Transform.translate(
                            offset: const Offset(-60, 0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x00FFFFFF),
                                    Color(0x33FFFFFF),
                                    Color(0x00FFFFFF),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Complete and Earn',
                                style: getBoldTextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Iconsax.arrow_right_3,
                                size: 18.sp,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
