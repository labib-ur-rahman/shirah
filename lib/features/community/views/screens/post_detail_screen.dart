import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/community/comment_model.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/reaction_summary_model.dart';
import 'package:shirah/data/models/community/reply_model.dart';
import 'package:shirah/features/community/controllers/post_detail_controller.dart';
import 'package:shirah/features/community/views/screens/reaction_list_screen.dart';

/// Post Detail Screen - Full post view with comments and reply functionality
/// Shows: Full post text, image, reaction/comment counts, comment list with replies
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    final controller = Get.put(PostDetailController());
    controller.loadPost(postId);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(isDark, controller, colors),
      body: Column(
        children: [
          /// -- Scrollable content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingPost.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 2,
                  ),
                );
              }

              final post = controller.post.value;
              if (post == null) {
                return Center(
                  child: Text(
                    'Post not found',
                    style: getTextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadPost(postId),
                color: colors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(bottom: 16.h),
                  children: [
                    /// -- Post content
                    _buildPostContent(post, isDark, colors),

                    SizedBox(height: 8.h),

                    /// -- Comments section
                    _buildCommentsSection(controller, isDark, colors),
                  ],
                ),
              );
            }),
          ),

          /// -- Comment input bar
          Obx(() {
            final isReplying = controller.replyingToCommentId.value != null;
            return _buildCommentInput(controller, isDark, colors, isReplying);
          }),
        ],
      ),
    );
  }

  /// App bar
  PreferredSizeWidget _buildAppBar(
    bool isDark,
    PostDetailController controller,
    AppStyleColors colors,
  ) {
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
        'Post',
        style: getBoldTextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      actions: [
        Obx(() {
          final post = controller.post.value;
          if (post == null) return const SizedBox.shrink();
          return IconButton(
            onPressed: () => _showPostMenu(post, isDark),
            icon: Icon(
              Iconsax.more,
              size: 22.sp,
              color: isDark ? Colors.white54 : const Color(0xFF6A7282),
            ),
          );
        }),
      ],
    );
  }

  /// Three dot menu
  void _showPostMenu(CommunityPostModel post, bool isDark) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isAuthor = currentUid != null && post.author.uid == currentUid;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                if (isAuthor) ...[
                  ListTile(
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Edit Post',
                        'Edit post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    leading: Icon(
                      Iconsax.edit,
                      size: 22.sp,
                      color: isDark ? Colors.white : const Color(0xFF1E2939),
                    ),
                    title: Text(
                      'Edit Post',
                      style: getBoldTextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1E2939),
                      ),
                    ),
                  ),
                  ListTile(
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Delete Post',
                        'Delete post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    leading: Icon(
                      Iconsax.trash,
                      size: 22.sp,
                      color: Colors.red,
                    ),
                    title: Text(
                      'Delete Post',
                      style: getBoldTextStyle(fontSize: 15, color: Colors.red),
                    ),
                  ),
                ],
                if (!isAuthor)
                  ListTile(
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Report Post',
                        'Report post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    leading: Icon(
                      Iconsax.flag,
                      size: 22.sp,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Report Post',
                      style: getBoldTextStyle(
                        fontSize: 15,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full post content (author, full text, image, reactions)
  Widget _buildPostContent(
    CommunityPostModel post,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Container(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Author header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 12.w, 10.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFE5E7EB),
                    image: post.author.photo.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              post.author.photo,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: post.author.photo.isEmpty
                      ? Icon(Iconsax.user, size: 22.sp, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name.isNotEmpty ? post.author.name : 'User',
                        style: getBoldTextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E2939),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: getTextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '·',
                            style: getTextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            post.privacy == PostPrivacy.friends
                                ? Iconsax.people
                                : post.privacy == PostPrivacy.onlyMe
                                ? Iconsax.lock
                                : Iconsax.global,
                            size: 12.sp,
                            color: isDark
                                ? Colors.white38
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

          /// -- Full post text
          if (post.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                4.h,
                16.w,
                post.hasImage ? 12.h : 16.h,
              ),
              child: Text(
                post.text,
                style: getTextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF364153),
                ),
              ),
            ),

          /// -- Image
          if (post.hasImage)
            CachedNetworkImage(
              imageUrl: post.firstImage!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              placeholder: (_, __) => Container(
                width: double.infinity,
                height: 300.h,
                color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                  ),
                ),
              ),
            ),

          /// -- Reaction & comment counts
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                if (post.totalReactions > 0)
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ReactionListScreen(
                          postId: post.postId,
                          reactionSummary: post.reactionSummary,
                        ),
                        transition: Transition.rightToLeftWithFade,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...post.reactionSummary.topReactions
                            .take(3)
                            .map(
                              (t) => Image.asset(
                                ReactionSummaryModel.emoji(t),
                                width: 18.w,
                                height: 18.h,
                              ),

                              // Text(
                              //   ReactionSummaryModel.emoji(t),
                              //   style: TextStyle(fontSize: 16.sp),
                              // ),
                            ),
                        SizedBox(width: 6.w),
                        Text(
                          '${post.totalReactions}',
                          style: getTextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (post.commentCount > 0)
                  Text(
                    '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                    style: getTextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Comments section
  Widget _buildCommentsSection(
    PostDetailController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Obx(() {
      if (controller.isLoadingComments.value) {
        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        );
      }

      if (controller.comments.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(32.w),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Iconsax.message,
                  size: 40.sp,
                  color: isDark ? Colors.white : Colors.grey.shade300,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No comments yet',
                  style: getTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments',
              style: getBoldTextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1E2939),
              ),
            ),
            SizedBox(height: 12.h),
            ...controller.comments.map(
              (comment) =>
                  _buildCommentItem(comment, controller, isDark, colors),
            ),
          ],
        ),
      );
    });
  }

  /// Single comment item with replies
  Widget _buildCommentItem(
    CommentModel comment,
    PostDetailController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              Container(
                width: 34.w,
                height: 34.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFE5E7EB),
                  image: comment.author.photo.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            comment.author.photo,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: comment.author.photo.isEmpty
                    ? Icon(Iconsax.user, size: 16.sp, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 10.w),

              /// Comment bubble
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.author.name.isNotEmpty
                                ? comment.author.name
                                : 'User',
                            style: getBoldTextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E2939),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            comment.text,
                            style: getTextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF364153),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),

                    /// Actions: Time, Reply
                    Row(
                      children: [
                        Text(
                          comment.timeAgo,
                          style: getTextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white30
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        GestureDetector(
                          onTap: () => controller.startReply(
                            comment.commentId,
                            comment.author.name,
                          ),
                          child: Text(
                            'Reply',
                            style: getBoldTextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF6A7282),
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// View replies toggle + replies list (single Obx for reactivity)
                    if (comment.replyCount > 0) ...[
                      SizedBox(height: 8.h),
                      Obx(() {
                        final isExpanded = controller.expandedReplies.contains(
                          comment.commentId,
                        );
                        final replies =
                            controller.repliesCache[comment.commentId] ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Toggle button
                            GestureDetector(
                              onTap: () =>
                                  controller.toggleReplies(comment.commentId),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24.w,
                                    height: 1.h,
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFD1D5DB),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    isExpanded
                                        ? 'Hide replies'
                                        : 'View ${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                                    style: getBoldTextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF6A7282),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Replies list
                            if (isExpanded && replies.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h, left: 12.w),
                                child: Column(
                                  children: replies
                                      .map((r) => _buildReplyItem(r, isDark))
                                      .toList(),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Single reply item
  Widget _buildReplyItem(ReplyModel reply, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
              image: reply.author.photo.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(reply.author.photo),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: reply.author.photo.isEmpty
                ? Icon(Iconsax.user, size: 14.sp, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252538)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.name.isNotEmpty
                            ? reply.author.name
                            : 'User',
                        style: getBoldTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E2939),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        reply.text,
                        style: getTextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  reply.timeAgo,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Comment input bar at bottom
  Widget _buildCommentInput(
    PostDetailController controller,
    bool isDark,
    AppStyleColors colors,
    bool isReplying,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Reply indicator
            if (isReplying) ...[
              Row(
                children: [
                  Text(
                    'Replying to ',
                    style: getTextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                  ),
                  Obx(
                    () => Text(
                      controller.replyingToName.value ?? '',
                      style: getBoldTextStyle(
                        fontSize: 12,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.cancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16.sp,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
            ],

            /// Input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 100.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: TextField(
                      controller: isReplying
                          ? controller.replyController
                          : controller.commentController,
                      maxLines: null,
                      style: getTextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1E2939),
                      ),
                      decoration: InputDecoration(
                        hintText: isReplying
                            ? 'Write a reply...'
                            : 'Write a comment...',
                        hintStyle: getTextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white30
                              : const Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),

                /// Send button
                Obx(() {
                  final loading = isReplying
                      ? controller.isSubmittingReply.value
                      : controller.isSubmittingComment.value;
                  return GestureDetector(
                    onTap: loading
                        ? null
                        : isReplying
                        ? controller.submitReply
                        : controller.submitComment,
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: loading
                          ? Padding(
                              padding: EdgeInsets.all(10.w),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Iconsax.send_1,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
