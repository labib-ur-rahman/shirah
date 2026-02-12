import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/data/models/community/post_reaction_model.dart';
import 'package:shirah/data/models/community/reaction_summary_model.dart';
import 'package:shirah/features/community/controllers/feed_controller.dart';

/// Reaction List Screen - Shows all users who reacted to a post
/// Filterable by reaction type (All, Like, Love, Insightful, Support, Inspiring)
class ReactionListScreen extends StatefulWidget {
  const ReactionListScreen({
    super.key,
    required this.postId,
    required this.reactionSummary,
  });

  final String postId;
  final ReactionSummaryModel reactionSummary;

  @override
  State<ReactionListScreen> createState() => _ReactionListScreenState();
}

class _ReactionListScreenState extends State<ReactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String?> _tabs = [null]; // null = All
  List<PostReactionModel> _reactions = [];
  bool _isLoading = true;
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _buildTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReactions();
  }

  void _buildTabs() {
    // Add tabs for reaction types that have counts > 0
    if (widget.reactionSummary.like > 0) _tabs.add(ReactionType.like);
    if (widget.reactionSummary.love > 0) _tabs.add(ReactionType.love);
    if (widget.reactionSummary.insightful > 0)
      _tabs.add(ReactionType.insightful);
    if (widget.reactionSummary.support > 0) _tabs.add(ReactionType.support);
    if (widget.reactionSummary.inspiring > 0) _tabs.add(ReactionType.inspiring);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _activeFilter = _tabs[_tabController.index];
      _loadReactions();
    }
  }

  Future<void> _loadReactions() async {
    setState(() => _isLoading = true);
    try {
      final result = await FeedController.instance.getPostReactions(
        postId: widget.postId,
        filterByType: _activeFilter,
      );
      setState(() {
        _reactions = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyleColors.instance.isDarkMode;
    final colors = AppStyleColors.instance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A14) : Colors.white,
      appBar: AppBar(
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
          'Reactions',
          style: getBoldTextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E2939),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colors.primary,
            unselectedLabelColor: isDark
                ? Colors.white38
                : const Color(0xFF9CA3AF),
            indicatorPadding: EdgeInsetsGeometry.zero,
            indicatorColor: colors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF3F4F6),
            tabs: _tabs.map((type) {
              if (type == null) {
                return Tab(
                  child: Text(
                    'All ${widget.reactionSummary.total}',
                    style: getBoldTextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1E2939),
                    ),
                  ),
                );
              }
              final count = _getCountForType(type);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 4.w),
                    Image.asset(
                      ReactionSummaryModel.emoji(type),
                      width: 18.w,
                      height: 18.h,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '$count',
                      style: getBoldTextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E2939),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            )
          : _reactions.isEmpty
          ? Center(
              child: Text(
                'No reactions',
                style: getTextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: _reactions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF9FAFB),
              ),
              itemBuilder: (_, index) {
                return _buildReactionItem(_reactions[index], isDark);
              },
            ),
    );
  }

  Widget _buildReactionItem(PostReactionModel reaction, bool isDark) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
            ),
            child: Icon(
              Iconsax.user,
              size: 22.sp,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
          ),
          Positioned(
            bottom: 2.h,
            right: 2.w,
            child: Center(
              child: Image.asset(
                ReactionSummaryModel.emoji(reaction.reaction),
                width: 16.w,
                height: 16.h,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        reaction.userName ?? 'User',
        style: getBoldTextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      subtitle: Text(
        ReactionType.displayName(reaction.reaction),
        style: getTextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  int _getCountForType(String type) {
    switch (type) {
      case ReactionType.like:
        return widget.reactionSummary.like;
      case ReactionType.love:
        return widget.reactionSummary.love;
      case ReactionType.insightful:
        return widget.reactionSummary.insightful;
      case ReactionType.support:
        return widget.reactionSummary.support;
      case ReactionType.inspiring:
        return widget.reactionSummary.inspiring;
      default:
        return 0;
    }
  }
}
