import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/home/controllers/home_feed_controller.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_empty_state.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_error_state.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_item_builder.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_shimmer_card.dart';

/// Home Feed List - The unified infinite scroll feed
/// Renders a heterogeneous list of feed items using the unified feed system
///
/// Features:
/// - Pull-to-refresh
/// - Infinite scroll pagination
/// - Progressive content loading (shimmer → content)
/// - Ad gap algorithm applied transparently
class HomeFeedList extends StatelessWidget {
  const HomeFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeFeedController>(
      init: HomeFeedController.instance,
      builder: (controller) {
        return Obx(() {
          // Error state
          if (controller.hasError.value && controller.feedItems.isEmpty) {
            return FeedErrorState(onRetry: () => controller.loadFeed());
          }

          // Loading state (initial)
          if (controller.isLoading.value && controller.feedItems.isEmpty) {
            return const FeedShimmerList(count: 4);
          }

          // Empty state
          if (!controller.isLoading.value && controller.feedItems.isEmpty) {
            return FeedEmptyState(onRefresh: () => controller.refreshFeed());
          }

          // Feed list
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Trigger load more when near bottom
              if (notification is ScrollEndNotification) {
                final metrics = notification.metrics;
                if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                  controller.loadMore();
                }
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount:
                  controller.feedItems.length +
                  (controller.isLoadingMore.value ? 1 : 0) +
                  (controller.hasMore.value ? 0 : 1),
              itemBuilder: (context, index) {
                // Loading more indicator at the bottom
                if (index == controller.feedItems.length) {
                  if (controller.isLoadingMore.value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const FeedShimmerCard(),
                    );
                  }
                  // No more items indicator
                  return _buildEndOfFeed();
                }

                final feedItem = controller.feedItems[index];

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: FeedItemBuilder(feedItem: feedItem),
                );
              },
            ),
          );
        });
      },
    );
  }

  /// End of feed indicator
  Widget _buildEndOfFeed() {
    final colors = AppStyleColors.instance;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          '• • •',
          style: TextStyle(
            fontSize: 16.sp,
            color: colors.isDarkMode ? Colors.white24 : Colors.grey.shade400,
            letterSpacing: 8,
          ),
        ),
      ),
    );
  }
}
