import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/home/controllers/home_feed_controller.dart';
import 'package:shirah/features/home/views/widgets/create_post/create_post_section.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_empty_state.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_error_state.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_item_builder.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_shimmer_card.dart';
import 'package:shirah/features/home/views/widgets/quick_actions/quick_actions_section.dart';

/// Home Screen - Unified infinite scroll feed
/// Uses the /home_feeds Firestore collection for feed ordering
/// Content is resolved progressively from referenced collections
///
/// Architecture:
/// HomeScreen (UI) → HomeFeedController (state) → HomeFeedRepository (Firebase)
///
/// Feed rendering: per documentation v3 section 15
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final colors = AppStyleColors.instance;

        return Container(
          color: colors.background,
          child: RefreshIndicator(
            color: colors.primary,
            onRefresh: () async {
              await HomeFeedController.instance.refreshFeed();
            },
            child: Obx(() => _buildFeedContent(colors)),
          ),
        );
      },
    );
  }

  Widget _buildFeedContent(AppStyleColors colors) {
    final controller = HomeFeedController.instance;

    // Error state
    if (controller.hasError.value && controller.feedItems.isEmpty) {
      return FeedErrorState(onRetry: () => controller.loadFeed());
    }

    // Initial loading
    if (controller.isLoading.value && controller.feedItems.isEmpty) {
      return ListView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        children: [
          const CreatePostSection(),
          SizedBox(height: 16.h),
          const QuickActionsSection(),
          SizedBox(height: 16.h),
          const FeedShimmerList(count: 3),
        ],
      );
    }

    // Empty feed
    if (!controller.isLoading.value && controller.feedItems.isEmpty) {
      return ListView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        children: [
          const CreatePostSection(),
          SizedBox(height: 16.h),
          const QuickActionsSection(),
          SizedBox(height: 16.h),
          FeedEmptyState(onRefresh: () => controller.refreshFeed()),
        ],
      );
    }

    // Feed with items
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 300) {
            controller.loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        // Static header sections + feed items + loading/end indicator
        itemCount: 2 + controller.feedItems.length + 1,
        itemBuilder: (context, index) {
          // Static: Create Post Section
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: const CreatePostSection(),
            );
          }

          // Static: Quick Actions Section
          if (index == 1) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: const QuickActionsSection(),
            );
          }

          // Feed items
          final feedIndex = index - 2;

          // End of list / Loading more
          if (feedIndex >= controller.feedItems.length) {
            if (controller.isLoadingMore.value) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const FeedShimmerCard(),
              );
            }
            if (!controller.hasMore.value) {
              return _buildEndOfFeed(colors);
            }
            return const SizedBox.shrink();
          }

          final feedItem = controller.feedItems[feedIndex];

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: FeedItemBuilder(feedItem: feedItem),
          );
        },
      ),
    );
  }

  /// End of feed indicator
  Widget _buildEndOfFeed(AppStyleColors colors) {
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
