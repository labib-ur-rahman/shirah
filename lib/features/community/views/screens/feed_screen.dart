import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/community/controllers/feed_controller.dart';
import 'package:shirah/features/home/views/widgets/community_post/community_post_card.dart';
import 'package:shirah/features/community/views/widgets/feed_create_post_bar.dart';

/// Feed Screen - Community post feed with create post bar + infinite scroll list
/// Displays approved posts, supports pull-to-refresh and pagination
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    final controller = Get.put(FeedController());

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(isDark, colors),
      body: Obx(() {
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return _buildLoadingState(isDark);
        }

        if (!controller.isLoading.value && controller.posts.isEmpty) {
          return _buildEmptyState(isDark, controller);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshFeed,
          color: colors.primary,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            itemCount: controller.posts.length + 2, // +1 create bar, +1 loading
            itemBuilder: (context, index) {
              // First item: Create post bar
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const FeedCreatePostBar(),
                );
              }

              // Last item: Loading more indicator
              if (index == controller.posts.length + 1) {
                return Obx(
                  () => controller.isLoadingMore.value
                      ? Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              }

              final post = controller.posts[index - 1];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: CommunityPostCard(post: post),
              );
            },
          ),
        );
      }),
    );
  }

  /// App Bar
  PreferredSizeWidget _buildAppBar(bool isDark, AppStyleColors colors) {
    return AppBar(
      backgroundColor: colors.background,
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
        'Community',
        style: getBoldTextStyle(
          fontSize: 22,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      centerTitle: false,
    );
  }

  /// Loading shimmer state
  Widget _buildLoadingState(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: 3,
      itemBuilder: (_, __) => _buildShimmerCard(isDark),
    );
  }

  /// Shimmer card placeholder
  Widget _buildShimmerCard(bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : Colors.grey.shade200,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 80.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            height: 14.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(7.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 200.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(7.r),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            height: 180.h,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(bool isDark, FeedController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_text,
            size: 64.sp,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No posts yet',
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Be the first to share something!',
            style: getTextStyle(
              fontSize: 14,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
            ),
          ),
          SizedBox(height: 24.h),
          TextButton.icon(
            onPressed: controller.refreshFeed,
            icon: const Icon(Iconsax.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
