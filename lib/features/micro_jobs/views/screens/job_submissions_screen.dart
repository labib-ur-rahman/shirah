import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/job_submission_model.dart';
import 'package:shirah/features/micro_jobs/controllers/my_created_jobs_controller.dart';

/// Job Submissions Screen - Author reviews worker submissions
/// Shows all submissions for a specific job with approve/reject actions
class JobSubmissionsScreen extends StatelessWidget {
  const JobSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = MyCreatedJobsController.instance;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(controller, isDark),
      body: Column(
        children: [
          /// -- Job Summary Header
          _buildJobSummary(controller, isDark),

          /// -- Filter Tabs
          _buildFilterTabs(controller, isDark),

          /// -- Submissions List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingSubmissions.value) {
                return _buildLoadingState(isDark);
              }

              final subs = controller.filteredSubmissions;
              if (subs.isEmpty) {
                return _buildEmptyState(controller, isDark);
              }

              return RefreshIndicator(
                onRefresh: controller.refreshSubmissions,
                color: const Color(0xFF8B5CF6),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    return _SubmissionCard(
                      submission: subs[index],
                      isDark: isDark,
                      controller: controller,
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

  // ==================== AppBar ====================

  PreferredSizeWidget _buildAppBar(
    MyCreatedJobsController controller,
    bool isDark,
  ) {
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
      title: Obx(
        () => Text(
          controller.selectedJob.value.title.isNotEmpty
              ? 'Review Submissions'
              : 'Submissions',
          style: getBoldTextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E2939),
          ),
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

  // ==================== Job Summary ====================

  Widget _buildJobSummary(MyCreatedJobsController controller, bool isDark) {
    return Obx(() {
      final job = controller.selectedJob.value;
      if (job.jobId.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E2E), const Color(0xFF2A1F3D)]
                : [const Color(0xFFFAF5FF), const Color(0xFFF5F3FF)],
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            /// -- Cover thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: job.coverImage,
                width: 48.w,
                height: 48.h,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 48.w,
                  height: 48.h,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFE5E7EB),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48.w,
                  height: 48.h,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFE5E7EB),
                  child: Icon(Iconsax.image, size: 18.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            /// -- Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: getBoldTextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '৳${job.perUserPrice.toStringAsFixed(0)}/task  •  ${job.submittedCount}/${job.limit} submitted  •  ${job.approvedCount} approved',
                    style: getTextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ==================== Filter Tabs ====================

  Widget _buildFilterTabs(MyCreatedJobsController controller, bool isDark) {
    return Obx(() {
      final pending = controller.pendingCount;
      final approved = controller.approvedCount;
      final rejected = controller.rejectedCount;

      return Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
        child: Row(
          children: [
            _buildFilterChip(
              'All',
              controller.submissions.length,
              '',
              controller.filterStatus.value,
              isDark,
              () => controller.setFilter(''),
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              'Pending',
              pending,
              SubmissionStatus.pending,
              controller.filterStatus.value,
              isDark,
              () => controller.setFilter(SubmissionStatus.pending),
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              'Approved',
              approved,
              SubmissionStatus.approved,
              controller.filterStatus.value,
              isDark,
              () => controller.setFilter(SubmissionStatus.approved),
            ),
            SizedBox(width: 8.w),
            _buildFilterChip(
              'Rejected',
              rejected,
              SubmissionStatus.rejected,
              controller.filterStatus.value,
              isDark,
              () => controller.setFilter(SubmissionStatus.rejected),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(
    String label,
    int count,
    String filterValue,
    String currentFilter,
    bool isDark,
    VoidCallback onTap,
  ) {
    final isActive = currentFilter == filterValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
              : isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive
                ? const Color(0xFF8B5CF6)
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: getTextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? const Color(0xFF8B5CF6)
                : isDark
                ? Colors.white54
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // ==================== States ====================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? Colors.white38 : const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildEmptyState(MyCreatedJobsController controller, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document,
            size: 48.sp,
            color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
          ),
          SizedBox(height: 12.h),
          Text(
            controller.filterStatus.value.isEmpty
                ? 'No submissions yet'
                : 'No ${controller.filterStatus.value.toLowerCase()} submissions',
            style: getBoldTextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Workers will appear here once they submit proofs',
            style: getTextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Submission Card ====================

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.isDark,
    required this.controller,
  });

  final JobSubmissionModel submission;
  final bool isDark;
  final MyCreatedJobsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Header: Worker name + Status
          Row(
            children: [
              /// Avatar
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(
                  0xFF8B5CF6,
                ).withValues(alpha: 0.12),
                child: Text(
                  submission.workerName.isNotEmpty
                      ? submission.workerName[0].toUpperCase()
                      : '?',
                  style: getBoldTextStyle(
                    fontSize: 14,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.workerName,
                      style: getBoldTextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (submission.createdAt != null)
                      Text(
                        _formatDate(submission.createdAt!),
                        style: getTextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white30
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
              _buildSubmissionStatusChip(submission.status),
            ],
          ),
          SizedBox(height: 12.h),

          /// -- Proof Text
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              submission.proofText,
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 10.h),

          /// -- Proof Images
          if (submission.proofImages.isNotEmpty) ...[
            SizedBox(
              height: 80.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: submission.proofImages.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImageDialog(
                      context,
                      submission.proofImages[index],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: submission.proofImages[index],
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 80.w,
                          height: 80.h,
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFF3F4F6),
                          child: Center(
                            child: SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.white30 : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 80.w,
                          height: 80.h,
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFF3F4F6),
                          child: Icon(Iconsax.image, size: 20.sp),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
          ],

          /// -- Rejection Note (if rejected)
          if (submission.status == SubmissionStatus.rejected &&
              submission.rejectionNote != null &&
              submission.rejectionNote!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFEE2E2,
                ).withValues(alpha: isDark ? 0.15 : 1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 14.sp,
                    color: const Color(0xFFEF4444),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      submission.rejectionNote!,
                      style: getTextStyle(
                        fontSize: 12,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
          ],

          /// -- Action Buttons (only for PENDING submissions)
          if (submission.status == SubmissionStatus.pending)
            _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Obx(() {
      final isReviewing = controller.isReviewing.value;

      return Row(
        children: [
          /// -- Approve Button
          Expanded(
            child: SizedBox(
              height: 40.h,
              child: ElevatedButton.icon(
                onPressed: isReviewing
                    ? null
                    : () => controller.approveSubmission(submission),
                icon: Icon(Iconsax.tick_circle, size: 16.sp),
                label: Text(
                  'Approve',
                  style: getBoldTextStyle(fontSize: 13, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF10B981,
                  ).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          /// -- Reject Button
          Expanded(
            child: SizedBox(
              height: 40.h,
              child: OutlinedButton.icon(
                onPressed: isReviewing
                    ? null
                    : () => _showRejectDialog(context),
                icon: Icon(Iconsax.close_circle, size: 16.sp),
                label: Text(
                  'Reject',
                  style: getBoldTextStyle(
                    fontSize: 13,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showRejectDialog(BuildContext context) {
    controller.rejectionNoteController.clear();

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Reject Submission',
          style: getBoldTextStyle(
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejection (min 5 characters):',
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller.rejectionNoteController,
              maxLines: 3,
              style: getTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Screenshot does not show the required action',
                hintStyle: getTextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: getTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectSubmission(submission);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Reject',
              style: getBoldTextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Get.back(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case SubmissionStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Pending';
        break;
      case SubmissionStatus.approved:
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF059669);
        label = 'Approved';
        break;
      case SubmissionStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Rejected';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
