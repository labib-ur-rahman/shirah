import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';
import 'package:shirah/features/home/controllers/home_feed_controller.dart';
import 'package:shirah/features/home/views/widgets/community_post/community_post_card.dart';
import 'package:shirah/features/home/views/widgets/feed/feed_shimmer_card.dart';
import 'package:shirah/features/home/views/widgets/feed/native_ad_placeholder.dart';
import 'package:shirah/features/home/views/widgets/micro_job/micro_job_card.dart';

/// Feed Item Builder - Renders the correct widget based on FeedItemModel type
/// This is the single switch statement from the documentation v3
///
/// Rendering flow:
/// 1. Check feed item type
/// 2. Resolve referenced content from controller cache
/// 3. Show shimmer if content not yet resolved
/// 4. Render appropriate card widget
class FeedItemBuilder extends StatelessWidget {
  const FeedItemBuilder({super.key, required this.feedItem});

  final FeedItemModel feedItem;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildByType());
  }

  Widget _buildByType() {
    switch (feedItem.type) {
      case FeedItemType.communityPost:
        return _buildCommunityPost();

      case FeedItemType.microJob:
        return _buildMicroJob();

      case FeedItemType.nativeAd:
        return NativeAdPlaceholder(adUnitId: feedItem.meta.adUnitId);

      // Future feed types - show placeholder for now
      case FeedItemType.reselling:
      case FeedItemType.driveOffer:
      case FeedItemType.suggestedFollowing:
      case FeedItemType.onDemandPost:
      case FeedItemType.buySellPost:
      case FeedItemType.sponsored:
      case FeedItemType.adsView:
      case FeedItemType.announcement:
        return _buildComingSoonPlaceholder();

      default:
        return const SizedBox.shrink();
    }
  }

  /// Build Community Post card from resolved content
  Widget _buildCommunityPost() {
    final controller = HomeFeedController.instance;
    final post = controller.getPost(feedItem.refId);

    // Show shimmer while content is loading
    if (post == null) {
      return const FeedShimmerCard();
    }

    return CommunityPostCard(post: post);
  }

  /// Build Micro Job card from resolved content
  Widget _buildMicroJob() {
    final controller = HomeFeedController.instance;
    final job = controller.getJob(feedItem.refId);

    // Show shimmer while content is loading
    if (job == null) {
      return const FeedShimmerCard();
    }

    return MicroJobCard(
      jobTitle: job.title,
      description: job.details,
      imageUrl: job.coverImage.isNotEmpty ? job.coverImage : null,
      taskLink: job.jobLink.isNotEmpty ? job.jobLink : null,
      perTaskAmount: '\$${job.perUserPrice.toStringAsFixed(0)}',
      completedTasks: job.submittedCount,
      totalTasks: job.limit,
    );
  }

  /// Placeholder for upcoming feed types
  Widget _buildComingSoonPlaceholder() {
    return const SizedBox.shrink();
  }
}
