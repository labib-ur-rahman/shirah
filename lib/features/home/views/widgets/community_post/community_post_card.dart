import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/image_path.dart';
import 'package:shirah/data/models/community/community_post_model.dart';
import 'package:shirah/data/models/community/reaction_summary_model.dart';
import 'package:shirah/features/community/controllers/feed_controller.dart';
import 'package:shirah/features/community/views/screens/post_detail_screen.dart';
import 'package:shirah/features/community/views/screens/reaction_list_screen.dart';

/// Community Post Card - Unified post card used in both HomeScreen and FeedScreen
/// Supports two modes:
///   1. Model-based: Pass [post] (CommunityPostModel) for full functionality
///   2. Param-based: Pass individual fields for dummy/preview data
class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    super.key,
    this.post,
    this.userName = '',
    this.userAvatar = '',
    this.timeAgo = '',
    this.content = '',
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.hasImage = false,
    this.onReactionSelected,
  });

  /// Full post model — when provided, overrides individual params
  final CommunityPostModel? post;

  /// Fallback individual params (for HomeScreen dummy data)
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final bool hasImage;
  final Function(String reactionType)? onReactionSelected;

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard>
    with SingleTickerProviderStateMixin {
  /// Overlay entry for reaction popup
  OverlayEntry? _overlayEntry;

  /// Key for the like button to get its position
  final GlobalKey _likeButtonKey = GlobalKey();

  /// Currently selected reaction (null = no reaction) — for param-based mode
  String? _localSelectedReaction;

  /// Animation controller for popup
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ==================== Computed Getters ====================

  bool get _isModelMode => widget.post != null;
  CommunityPostModel? get _post => widget.post;

  String get _userName => _isModelMode
      ? (_post!.author.name.isNotEmpty ? _post!.author.name : 'User')
      : widget.userName;
  String get _userAvatar =>
      _isModelMode ? _post!.author.photo : widget.userAvatar;
  String get _timeAgo => _isModelMode ? _post!.timeAgo : widget.timeAgo;
  String get _content => _isModelMode ? _post!.text : widget.content;
  String? get _imageUrl => _isModelMode ? _post!.firstImage : widget.imageUrl;
  bool get _hasImage => _isModelMode
      ? _post!.hasImage
      : (widget.hasImage && widget.imageUrl != null);
  int get _likes => _isModelMode ? _post!.totalReactions : widget.likes;
  int get _commentCount => _isModelMode ? _post!.commentCount : widget.comments;
  String get _privacy => _isModelMode ? _post!.privacy : PostPrivacy.public_;

  bool get _isAuthor {
    if (!_isModelMode) return false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return currentUid != null && _post!.author.uid == currentUid;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  // ==================== Overlay Popup ====================

  void _showReactionPopup() {
    _removeOverlay();

    final RenderBox? renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx - 4.w,
            top: position.dy - 60.h,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomLeft,
              child: _buildReactionPopup(),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController.reset();
  }

  Widget _buildReactionPopup() {
    final isDark = AppStyleColors.instance.isDarkMode;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        borderRadius: BorderRadius.circular(50.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReactionItem(
            emoji: AnimatedEmojis.thumbsUp,
            type: ReactionType.like,
            dx: 250,
          ),
          SizedBox(width: 12.w),
          _buildReactionItem(
            emoji: AnimatedEmojis.redHeart,
            type: ReactionType.love,
            dx: 200,
          ),
          SizedBox(width: 12.w),
          _buildReactionItem(
            emoji: AnimatedEmojis.lightBulb,
            type: ReactionType.insightful,
            dx: 150,
          ),
          SizedBox(width: 12.w),
          _buildReactionItem(
            emoji: AnimatedEmojis.handshake,
            type: ReactionType.support,
            dx: 100,
          ),
          SizedBox(width: 12.w),
          _buildReactionItem(
            emoji: AnimatedEmojis.fire,
            type: ReactionType.inspiring,
            dx: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildReactionItem({
    required AnimatedEmojiData emoji,
    required String type,
    required int dx,
  }) {
    return GestureDetector(
      onTap: () {
        _removeOverlay();
        _onReactionSelected(type);
      },
      onLongPress: () {
        // Optional: Show tooltip with reaction name
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final target = renderBox.localToGlobal(
          renderBox.size.center(Offset.zero),
        );

        final entry = OverlayEntry(
          builder: (context) => Positioned(
            left: target.dx - dx,
            top: target.dy + 76.h,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 180.w,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      // color: Colors.black.withValues(alpha: 0.8),
                      color: _getReactionColor(type).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      type,
                      style: getTextStyle(fontSize: 12, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 1), () => entry.remove());
      },
      child: AnimatedEmoji(emoji, size: 34.sp, repeat: true),
    );
  }

  // ==================== Reaction Handlers ====================

  void _onReactionSelected(String type) {
    if (_isModelMode) {
      FeedController.instance.toggleReaction(
        postId: _post!.postId,
        reactionType: type,
      );
    } else {
      setState(() {
        _localSelectedReaction = type;
      });
      widget.onReactionSelected?.call(type);
    }
  }

  void _onLikeTap() {
    if (_isModelMode) {
      FeedController.instance.toggleReaction(
        postId: _post!.postId,
        reactionType: ReactionType.like,
      );
    } else {
      setState(() {
        _localSelectedReaction = _localSelectedReaction == null ? 'Like' : null;
      });
      if (_localSelectedReaction != null) {
        widget.onReactionSelected?.call('Like');
      }
    }
  }

  // ==================== Navigation ====================

  void _navigateToDetail() {
    if (!_isModelMode) return;
    Get.to(
      () => PostDetailScreen(postId: _post!.postId),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _navigateToReactions() {
    if (!_isModelMode) return;
    Get.to(
      () => ReactionListScreen(
        postId: _post!.postId,
        reactionSummary: _post!.reactionSummary,
      ),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  // ==================== Three Dot Menu ====================

  void _showPostMenu(bool isDark) {
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
                /// Handle bar
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

                /// Edit Post (author only)
                if (_isAuthor)
                  _buildMenuOption(
                    icon: Iconsax.edit,
                    label: 'Edit Post',
                    isDark: isDark,
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Edit Post',
                        'Edit post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                /// Delete Post (author only)
                if (_isAuthor)
                  _buildMenuOption(
                    icon: Iconsax.trash,
                    label: 'Delete Post',
                    isDark: isDark,
                    color: Colors.red,
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Delete Post',
                        'Delete post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                /// Report Post (non-author only)
                if (!_isAuthor)
                  _buildMenuOption(
                    icon: Iconsax.flag,
                    label: 'Report Post',
                    isDark: isDark,
                    color: Colors.orange,
                    onTap: () {
                      Get.back();
                      Get.snackbar(
                        'Report Post',
                        'Report post is coming soon...',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? (isDark ? Colors.white : const Color(0xFF1E2939));
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22.sp, color: c),
      title: Text(label, style: getBoldTextStyle(fontSize: 15, color: c)),
    );
  }

  // ==================== Share ====================

  void _sharePost() {
    final text = _content.isNotEmpty
        ? _content
        : 'Check out this post on shirah!';
    Share.share(text);
  }

  // ==================== Reaction UI Helpers ====================

  /// Get the reaction icon widget based on current reaction state
  Widget _buildLikeButtonContent(bool isDark) {
    String? reaction;

    if (_isModelMode) {
      reaction = FeedController.instance.userReactions[_post!.postId];
    } else {
      reaction = _localSelectedReaction;
    }

    if (reaction == null) {
      return Icon(
        Iconsax.like_1,
        size: 22,
        color: isDark ? Colors.white54 : const Color(0xFF364153),
      );
    }

    // Map model reaction types or param-based labels to asset paths
    final assetPath = _getReactionAsset(reaction);
    if (assetPath != null) {
      return Image.asset(assetPath, width: 22, height: 22);
    }

    return Icon(
      Iconsax.like_1,
      size: 22,
      color: isDark ? Colors.white54 : const Color(0xFF364153),
    );
  }

  String? _getReactionAsset(String reaction) {
    switch (reaction) {
      case ReactionType.like:
      case 'Like':
        return ImagePath.reactionLike;
      case ReactionType.love:
      case 'Love':
        return ImagePath.reactionLove;
      case ReactionType.insightful:
      case 'Insightful':
        return ImagePath.reactionInsightful;
      case ReactionType.support:
      case 'Support':
        return ImagePath.reactionSupport;
      case ReactionType.inspiring:
      case 'Inspiring':
        return ImagePath.reactionInspiring;
      default:
        return ImagePath.reactionLike;
    }
  }

  Color _getLikeColor(bool isDark) {
    String? reaction;
    if (_isModelMode) {
      reaction = FeedController.instance.userReactions[_post!.postId];
    } else {
      reaction = _localSelectedReaction;
    }
    if (reaction == null) {
      return isDark ? Colors.white54 : const Color(0xFF364153);
    }
    return _getReactionColor(reaction);
  }

  Color _getReactionColor(String type) {
    switch (type) {
      case ReactionType.love:
      case 'Love':
        return const Color(0xFFE11D48);
      case ReactionType.insightful:
      case 'Insightful':
        return const Color.fromARGB(255, 245, 11, 11);
      case ReactionType.support:
      case 'Support':
        return const Color.fromARGB(255, 39, 15, 255);
      case ReactionType.inspiring:
      case 'Inspiring':
        return const Color.fromARGB(255, 16, 167, 255);
      default:
        return const Color.fromARGB(255, 4, 113, 255);
    }
  }

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case PostPrivacy.friends:
        return Iconsax.people;
      case PostPrivacy.onlyMe:
        return Iconsax.lock;
      default:
        return Iconsax.global;
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyleColors.instance.isDarkMode;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// -- Header: User info + Three Dot
          _buildHeader(isDark),

          /// -- Content Text
          if (_content.isNotEmpty) _buildContentText(isDark),

          if (_content.isNotEmpty && _hasImage) 12.verticalSpace,

          if (!_hasImage) 8.verticalSpace,

          /// -- Post Image
          if (_hasImage) _buildPostImage(isDark),

          /// -- Divider
          Container(
            height: 0.5.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
          ),

          /// -- Action Buttons Row (Like, Comment, Share)
          _buildActionRow(isDark),
        ],
      ),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          /// Avatar
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
              image: _userAvatar.isNotEmpty
                  ? DecorationImage(
                      image: _isModelMode
                          ? CachedNetworkImageProvider(_userAvatar)
                                as ImageProvider
                          : NetworkImage(_userAvatar),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _userAvatar.isEmpty
                ? Icon(Iconsax.user, size: 20.sp, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12.w),

          /// Name & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: getBoldTextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1E2939),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _timeAgo,
                      style: getTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6A7282),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '•',
                      style: getTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6A7282),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      _getPrivacyIcon(_privacy),
                      size: 16,
                      color: isDark ? Colors.white54 : const Color(0xFF6A7282),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Three Dot Menu
          GestureDetector(
            onTap: () {
              if (_isModelMode) {
                _showPostMenu(isDark);
              }
            },
            child: Container(
              width: 28.w,
              height: 28.h,
              alignment: Alignment.center,
              child: Icon(
                Iconsax.more,
                size: 22,
                color: isDark ? Colors.white54 : const Color(0xFF6A7282),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Content Text ====================

  Widget _buildContentText(bool isDark) {
    final maxLines = _hasImage ? 3 : 6;

    return GestureDetector(
      onTap: _navigateToDetail,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textSpan = TextSpan(
              text: _content,
              style: getTextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF364153),
              ),
            );
            final tp = TextPainter(
              text: textSpan,
              maxLines: maxLines,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final isOverflow = tp.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _content,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: getTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF364153),
                  ),
                ),
                if (isOverflow)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'See more',
                      style: getBoldTextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF6A7282),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== Post Image ====================

  Widget _buildPostImage(bool isDark) {
    return GestureDetector(
      onTap: _navigateToDetail,
      child: CachedNetworkImage(
        imageUrl: _imageUrl!,
        width: double.infinity,
        height: 263.h,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: double.infinity,
          height: 263.h,
          color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: double.infinity,
          height: 263.h,
          color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200,
          child: Icon(Iconsax.image, size: 40.sp, color: Colors.grey),
        ),
      ),
    );
  }

  /// Build stacked reaction icons (max 3, overlapping)
  Widget _buildStackedReactionIcons() {
    List<String> topTypes;

    if (_isModelMode) {
      topTypes = _post!.reactionSummary.topReactions.take(3).toList();
    } else {
      // For dummy data, show default emojis
      topTypes = [ReactionType.love, ReactionType.like, ReactionType.inspiring];
    }

    if (topTypes.isEmpty) return const SizedBox.shrink();

    // Stack icons overlapping: each icon shifted left by overlap amount
    const double iconSize = 22; // Base size for each icon
    const double overlap = 6;
    final double totalWidth =
        iconSize + (topTypes.length - 1) * (iconSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(topTypes.length, (index) {
          final reversedIndex = topTypes.length - 1 - index;
          return Positioned(
            left: (reversedIndex * (iconSize - overlap)),
            child: Center(
              child: Image.asset(
                ReactionSummaryModel.emoji(topTypes[reversedIndex]),
                width: iconSize,
                height: iconSize,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ==================== Action Row ====================

  Widget _buildActionRow(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: _isModelMode
          ? Obx(() {
              final userReaction =
                  FeedController.instance.userReactions[_post!.postId];
              return _buildActionButtons(isDark, userReaction);
            })
          : _buildActionButtons(isDark, _localSelectedReaction),
    );
  }

  Widget _buildActionButtons(bool isDark, String? currentReaction) {
    return Row(
      children: [
        /// Like button
        GestureDetector(
          key: _likeButtonKey,
          onTap: _onLikeTap,
          onLongPress: _showReactionPopup,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLikeButtonContent(isDark),
                SizedBox(width: 6.w),
                Text(
                  '$_likes',
                  style: getTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getLikeColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Comment button
        GestureDetector(
          onTap: _navigateToDetail,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.message,
                  size: 22,
                  color: isDark ? Colors.white54 : const Color(0xFF364153),
                ),
                SizedBox(width: 6.w),

                /// -- Right side: Comment count
                if (_commentCount > 0)
                  GestureDetector(
                    onTap: _navigateToDetail,
                    child: Text(
                      '$_commentCount',
                      style: getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white54
                            : const Color(0xFF364153),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        /// Share button
        GestureDetector(
          onTap: _sharePost,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
            child: Icon(
              Iconsax.share,
              size: 22,
              color: isDark ? Colors.white54 : const Color(0xFF364153),
            ),
          ),
        ),

        Spacer(),

        /// -- Left side: Stacked reaction icons + count
        if (_likes > 0)
          GestureDetector(
            onTap: _navigateToReactions,
            child: _buildStackedReactionIcons(),
          ),

        8.horizontalSpace,
      ],
    );
  }
}
