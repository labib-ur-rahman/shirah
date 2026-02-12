import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/micro_job/micro_job_model.dart';
import 'package:shirah/features/micro_jobs/controllers/micro_job_controller.dart';
import 'package:shirah/features/micro_jobs/views/screens/micro_job_detail_screen.dart';
import 'package:shirah/features/micro_jobs/views/screens/worker_submissions_screen.dart';
import 'package:shirah/features/micro_jobs/views/widgets/micro_job_grid_card.dart';
import 'package:shirah/features/micro_jobs/views/widgets/micro_job_shimmer.dart';

/// Micro Job Screen - 2-column grid of available micro jobs
/// Pull-to-refresh, infinite scroll, modern enterprise design
class MicroJobScreen extends StatelessWidget {
  const MicroJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    // Ensure controller is registered
    final controller = Get.find<MicroJobController>();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(isDark),
      body: Obx(() {
        // Loading state - shimmer grid
        if (controller.isLoading.value && controller.availableJobs.isEmpty) {
          return const MicroJobShimmer();
        }

        // Empty state
        if (!controller.isLoading.value && controller.availableJobs.isEmpty) {
          return _buildEmptyState(isDark);
        }

        // Jobs grid
        return RefreshIndicator(
          onRefresh: controller.refreshJobs,
          color: const Color(0xFF8B5CF6),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                controller.loadMoreJobs();
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                /// -- Header stats
                SliverToBoxAdapter(
                  child: _buildHeaderStats(controller, isDark),
                ),

                /// -- Grid list
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final job = controller.availableJobs[index];
                      return MicroJobGridCard(
                        job: job,
                        onTap: () => _navigateToDetail(job),
                      );
                    }, childCount: controller.availableJobs.length),
                  ),
                ),

                /// -- Loading more indicator
                if (controller.isLoadingMore.value)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bottom spacing
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==================== AppBar ====================

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
        'Micro Jobs',
        style: getBoldTextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            Get.to(() => const WorkerSubmissionsScreen());
          },
          icon: Icon(
            Iconsax.document_text,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
          tooltip: 'My Submissions',
        ),
      ],
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

  // ==================== Header Stats ====================

  Widget _buildHeaderStats(MicroJobController controller, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.briefcase,
                  size: 14.sp,
                  color: const Color(0xFF10B981),
                ),
                SizedBox(width: 6.w),
                Obx(
                  () => Text(
                    '${controller.availableJobs.length} Jobs Available',
                    style: getBoldTextStyle(
                      fontSize: 12,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Earn by completing tasks',
            style: getTextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Empty State ====================

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.briefcase,
              size: 40.sp,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No jobs available',
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Check back later for new micro jobs',
            style: getTextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Navigation ====================

  void _navigateToDetail(MicroJobModel job) {
    Get.to(
      () => MicroJobDetailScreen(jobId: job.jobId),
      transition: Transition.rightToLeftWithFade,
    );
  }
}
