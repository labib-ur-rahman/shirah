import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/features/micro_jobs/controllers/worker_submissions_controller.dart';
import 'package:intl/intl.dart';

/// Worker Submissions Screen - Shows all jobs submitted by the worker
/// Displays cover, price, submission date, status, and rejection notes
class WorkerSubmissionsScreen extends StatelessWidget {
  const WorkerSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = Get.put(WorkerSubmissionsController());

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          /// -- Filter Tabs
          _buildFilterTabs(controller, isDark),

          /// -- Content
          Expanded(
            child: Obx(() {
              // Loading state
              if (controller.isLoading.value &&
                  controller.submissions.isEmpty) {
                return _buildLoadingState(isDark);
              }

              // Empty state
              final filtered = controller.filteredSubmissions;
              if (filtered.isEmpty) {
                return _buildEmptyState(isDark, controller.filterStatus.value);
              }

              // Submissions list
              return RefreshIndicator(
                onRefresh: controller.refreshSubmissions,
                color: const Color(0xFF8B5CF6),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.all(16.w),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 14.h),
                  itemBuilder: (context, index) {
                    final submission = filtered[index];
                    return _SubmissionCard(
                      submission: submission,
                      isDark: isDark,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
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
        'My Submissions',
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

  Widget _buildFilterTabs(WorkerSubmissionsController controller, bool isDark) {
    return Obx(() {
      final currentFilter = controller.filterStatus.value;
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All',
                count: controller.submissions.length,
                isSelected: currentFilter == 'all',
                onTap: () => controller.setFilter('all'),
                isDark: isDark,
              ),
              SizedBox(width: 10.w),
              _buildFilterChip(
                label: 'Pending',
                count: controller.pendingCount,
                isSelected: currentFilter == 'pending',
                onTap: () => controller.setFilter('pending'),
                isDark: isDark,
                color: const Color(0xFFF59E0B),
              ),
              SizedBox(width: 10.w),
              _buildFilterChip(
                label: 'Approved',
                count: controller.approvedCount,
                isSelected: currentFilter == 'approved',
                onTap: () => controller.setFilter('approved'),
                isDark: isDark,
                color: const Color(0xFF10B981),
              ),
              SizedBox(width: 10.w),
              _buildFilterChip(
                label: 'Rejected',
                count: controller.rejectedCount,
                isSelected: currentFilter == 'rejected',
                onTap: () => controller.setFilter('rejected'),
                isDark: isDark,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFF8B5CF6);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: getBoldTextStyle(
                fontSize: 13,
                color: isSelected
                    ? chipColor
                    : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? chipColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: getBoldTextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (_, __) => Container(
        height: 140.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String filter) {
    String message = filter == 'all'
        ? 'No submissions yet'
        : 'No $filter submissions';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text,
            size: 64.sp,
            color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Submit job proofs to see them here',
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

/// Individual submission card
class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission, required this.isDark});

  final JobSubmissionModel submission;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
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
        border: submission.status == 'REJECTED'
            ? Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Header: Cover + Info
          Row(
            children: [
              /// Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: CachedNetworkImage(
                  imageUrl: submission.jobCoverImage ?? '',
                  width: 80.w,
                  height: 80.h,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80.w,
                    height: 80.h,
                    color: isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF3F4F6),
                    child: Icon(
                      Iconsax.image,
                      size: 24.sp,
                      color: isDark ? Colors.white24 : Colors.grey,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80.w,
                    height: 80.h,
                    color: isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF3F4F6),
                    child: Icon(
                      Iconsax.image,
                      size: 24.sp,
                      color: isDark ? Colors.white24 : Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              /// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Job Title
                    Text(
                      submission.jobTitle ?? 'Unknown Job',
                      style: getBoldTextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1E2939),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),

                    /// Price
                    Row(
                      children: [
                        Icon(
                          Iconsax.wallet_2,
                          size: 14.sp,
                          color: const Color(0xFF10B981),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '৳${(submission.perUserPrice ?? 0).toStringAsFixed(2)}',
                          style: getBoldTextStyle(
                            fontSize: 14,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),

                    /// Submission Date
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar,
                          size: 13.sp,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(submission.submittedAt),
                          style: getTextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// Status Badge
              _buildStatusBadge(),
            ],
          ),

          /// -- Rejection Note (if rejected)
          if (submission.status == 'REJECTED' &&
              submission.rejectionNote?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 14.sp,
                        color: const Color(0xFFEF4444),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Rejection Reason',
                        style: getBoldTextStyle(
                          fontSize: 12,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    submission.rejectionNote!,
                    style: getTextStyle(
                      fontSize: 13,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (submission.status) {
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Pending';
        icon = Iconsax.clock;
        break;
      case 'APPROVED':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF059669);
        label = 'Approved';
        icon = Iconsax.tick_circle;
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Rejected';
        icon = Iconsax.close_circle;
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = submission.status;
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: textColor),
          SizedBox(width: 4.w),
          Text(label, style: getBoldTextStyle(fontSize: 12, color: textColor)),
        ],
      ),
    );
  }
}
