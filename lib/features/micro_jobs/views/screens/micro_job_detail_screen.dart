import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/features/micro_jobs/controllers/micro_job_controller.dart';
import 'package:shirah/features/micro_jobs/views/widgets/job_proof_bottom_sheet.dart';

/// Micro Job Detail Screen - Full job info, cover, instructions, stats, submit proof
/// Shows all job details and allows workers to submit proof of completion
class MicroJobDetailScreen extends StatelessWidget {
  const MicroJobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = MicroJobController.instance;

    // Load job details on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadJobDetails(jobId);
    });

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return _buildLoadingState(isDark);
        }

        final job = controller.selectedJob.value;
        if (job.jobId.isEmpty) {
          return _buildErrorState(isDark);
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            /// -- Collapsing AppBar with Cover Image
            _buildSliverAppBar(job, isDark),

            /// -- Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    /// -- Job Type Badge + Title
                    _buildTitleSection(job, isDark),
                    SizedBox(height: 16.h),

                    /// -- Stats Row (Per Task + Remaining)
                    _buildStatsRow(job, isDark),
                    SizedBox(height: 20.h),

                    /// -- Progress Bar
                    _buildProgressBar(job, isDark),
                    SizedBox(height: 24.h),

                    /// -- Open Task Link Button
                    _buildTaskLinkButton(job, isDark),
                    SizedBox(height: 24.h),

                    /// -- Instructions Section
                    _buildSectionHeader(
                      'Instructions',
                      Iconsax.document_text,
                      isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInstructionsCard(job, isDark),
                    SizedBox(height: 24.h),

                    /// -- Job Info Section
                    _buildSectionHeader(
                      'Job Info',
                      Iconsax.info_circle,
                      isDark,
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoCard(job, isDark),
                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),
          ],
        );
      }),

      /// -- Bottom: Submit Proof Button (hidden if already submitted)
      bottomNavigationBar: Obx(() {
        final job = controller.selectedJob.value;
        if (job.jobId.isEmpty || controller.isLoadingDetail.value) {
          return const SizedBox.shrink();
        }
        return _buildBottomBar(controller, job, isDark);
      }),
    );
  }

  // ==================== Sliver AppBar ==================

  Widget _buildSliverAppBar(MicroJobModel job, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240.h,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.arrow_left, color: Colors.white, size: 20.sp),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFF3F4F6),
                child: Icon(
                  Iconsax.image,
                  size: 48.sp,
                  color: isDark ? Colors.white24 : Colors.grey,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Title Section ====================

  Widget _buildTitleSection(MicroJobModel job, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -- Title
        Text(
          job.title,
          style: getBoldTextStyle(
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        SizedBox(height: 6.h),

        /// -- Author
        Text(
          'Posted by ${job.authorName}',
          style: getTextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  // ==================== Stats Row ====================

  Widget _buildStatsRow(MicroJobModel job, bool isDark) {
    return Row(
      children: [
        /// -- Per Task (Green)
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Per task',
                  style: getTextStyle(
                    fontSize: 11,
                    color: const Color(0xFF065F46),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '৳${job.perUserPrice.toStringAsFixed(0)}',
                  style: getBoldTextStyle(
                    fontSize: 20,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),

        /// -- Remaining (Orange)
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining',
                  style: getTextStyle(
                    fontSize: 11,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${job.remainingSlots}/${job.limit}',
                  style: getBoldTextStyle(
                    fontSize: 20,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),

        /// -- Approved (Blue)
        Expanded(
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                  : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approved',
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${job.approvedCount}',
                  style: getBoldTextStyle(
                    fontSize: 20,
                    color: isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Progress Bar ====================

  Widget _buildProgressBar(MicroJobModel job, bool isDark) {
    final progress = job.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion Progress',
              style: getTextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: getBoldTextStyle(
                fontSize: 12,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }

  // ==================== Task Link Button ====================

  Widget _buildTaskLinkButton(MicroJobModel job, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: () async {
          final uri = Uri.tryParse(job.jobLink);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.link_21, size: 18.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  'Open Task Link',
                  style: getBoldTextStyle(fontSize: 15, color: Colors.white),
                ),
                SizedBox(width: 8.w),
                Icon(Iconsax.export_1, size: 16.sp, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Section Header ====================

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: getBoldTextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF1E2939),
          ),
        ),
      ],
    );
  }

  // ==================== Instructions Card ====================

  Widget _buildInstructionsCard(MicroJobModel job, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        job.details,
        style: getTextStyle(
          fontSize: 14,
          lineHeight: 1.6,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    );
  }

  // ==================== Info Card ====================

  Widget _buildInfoCard(MicroJobModel job, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Total Budget',
            '৳${job.totalPrice.toStringAsFixed(0)}',
            isDark,
          ),
          _buildInfoDivider(isDark),
          _buildInfoRow('Worker Limit', '${job.limit} workers', isDark),
          _buildInfoDivider(isDark),
          _buildInfoRow('Submitted', '${job.submittedCount} proofs', isDark),
          _buildInfoDivider(isDark),
          _buildInfoRow(
            'Status',
            job.status.toUpperCase(),
            isDark,
            valueColor: _statusColor(job.status),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: getTextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: getBoldTextStyle(
              fontSize: 14,
              color:
                  valueColor ??
                  (isDark ? Colors.white : const Color(0xFF1E2939)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider(bool isDark) {
    return Container(
      height: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF3F4F6),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'paused':
        return const Color(0xFF6B7280);
      case 'completed':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ==================== Bottom Bar ====================

  Widget _buildBottomBar(
    MicroJobController controller,
    MicroJobModel job,
    bool isDark,
  ) {
    final hasSubmitted = controller.hasSubmitted.value;
    final isAccepting = job.isAcceptingSubmissions;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: hasSubmitted
          ? _buildSubmittedBanner(controller, isDark)
          : !isAccepting
          ? _buildFullBanner(isDark)
          : _buildSubmitProofButton(controller, isDark),
    );
  }

  Widget _buildSubmittedBanner(MicroJobController controller, bool isDark) {
    final submission = controller.userSubmission.value;
    final statusText = submission != null
        ? 'Status: ${submission.status.toUpperCase()}'
        : 'Proof already submitted';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1A) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF166534).withValues(alpha: 0.4)
              : const Color(0xFFDCFCE7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.tick_circle,
            size: 22.sp,
            color: const Color(0xFF10B981),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Proof Submitted',
                  style: getBoldTextStyle(
                    fontSize: 14,
                    color: const Color(0xFF10B981),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  statusText,
                  style: getTextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1F1F) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.close_circle,
            size: 22.sp,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'This job is no longer accepting submissions.',
              style: getTextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitProofButton(MicroJobController controller, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: () {
          Get.bottomSheet(
            JobProofBottomSheet(jobId: jobId),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.camera, size: 20.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  'Submit Proof & Earn',
                  style: getBoldTextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Loading & Error States ====================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: isDark ? Colors.white38 : const Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 48.sp,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
          SizedBox(height: 16.h),
          Text(
            'Job not found',
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Go Back',
              style: getBoldTextStyle(
                fontSize: 14,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
