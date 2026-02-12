import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/features/micro_jobs/controllers/my_created_jobs_controller.dart';
import 'package:shirah/features/micro_jobs/views/screens/job_submissions_screen.dart';

/// My Created Jobs Screen - Shows all micro jobs created by the author
/// Tap a job to see submissions, review proofs, and approve/reject
class MyCreatedJobsScreen extends StatelessWidget {
  const MyCreatedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = Get.put(MyCreatedJobsController());

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(isDark),
      body: Obx(() {
        // Loading state
        if (controller.isLoadingJobs.value && controller.myJobs.isEmpty) {
          return _buildLoadingState(isDark);
        }

        // Empty state
        if (!controller.isLoadingJobs.value && controller.myJobs.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshMyJobs,
          color: const Color(0xFF8B5CF6),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: controller.myJobs.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final job = controller.myJobs[index];
              return _MyJobCard(
                job: job,
                isDark: isDark,
                onTap: () {
                  controller.loadJobSubmissions(job);
                  Get.to(() => const JobSubmissionsScreen());
                },
              );
            },
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      title: Text(
        'My Created Jobs',
        style: getBoldTextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.briefcase,
            size: 64.sp,
            color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
          ),
          SizedBox(height: 16.h),
          Text(
            'No jobs created yet',
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create your first micro job to get started',
            style: getTextStyle(
              fontSize: 14,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual job card showing cover, title, status, and stats
class _MyJobCard extends StatelessWidget {
  const _MyJobCard({
    required this.job,
    required this.isDark,
    required this.onTap,
  });

  final MicroJobModel job;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// -- Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                imageUrl: job.coverImage,
                width: 72.w,
                height: 72.h,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 72.w,
                  height: 72.h,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF3F4F6),
                  child: Icon(
                    Iconsax.image,
                    size: 20.sp,
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 72.w,
                  height: 72.h,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF3F4F6),
                  child: Icon(
                    Iconsax.image,
                    size: 20.sp,
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            /// -- Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -- Title + Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: getBoldTextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildStatusChip(job.status),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  /// -- Price & Slots
                  Row(
                    children: [
                      Icon(
                        Iconsax.money,
                        size: 13.sp,
                        color: const Color(0xFF10B981),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '৳${job.perUserPrice.toStringAsFixed(0)}/task',
                        style: getTextStyle(
                          fontSize: 12,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Iconsax.people,
                        size: 13.sp,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF9CA3AF),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${job.submittedCount}/${job.limit}',
                        style: getTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),

                  /// -- Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: job.progress.clamp(0.0, 1.0),
                      minHeight: 4.h,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColor(job.status),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  /// -- Bottom: Approved count + arrow
                  Row(
                    children: [
                      Icon(
                        Iconsax.tick_circle,
                        size: 12.sp,
                        color: const Color(0xFF8B5CF6),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${job.approvedCount} approved',
                        style: getTextStyle(
                          fontSize: 11,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 16.sp,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case JobStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Pending';
        break;
      case JobStatus.approved:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF059669);
        label = 'Active';
        break;
      case JobStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Rejected';
        break;
      case JobStatus.paused:
        bgColor = const Color(0xFFE0E7FF);
        textColor = const Color(0xFF4F46E5);
        label = 'Paused';
        break;
      case JobStatus.completed:
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF7C3AED);
        label = 'Completed';
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: getBoldTextStyle(fontSize: 10, color: textColor),
      ),
    );
  }

  Color _progressColor(String status) {
    switch (status) {
      case JobStatus.approved:
        return const Color(0xFF10B981);
      case JobStatus.completed:
        return const Color(0xFF8B5CF6);
      case JobStatus.rejected:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
