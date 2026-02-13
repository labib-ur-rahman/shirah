import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/feed/feed_item_model.dart';
import 'package:shirah/modules/admins/home_feed/controllers/admin_feed_controller.dart';
import 'package:shirah/modules/admins/home_feed/views/widgets/admin_feed_detail_sheet.dart';

/// Admin Feed Item Card - Material 3 card for individual feed items
///
/// Displays:
///   - Feed type badge with icon
///   - Status indicator
///   - Priority level chip
///   - Reference ID (truncated)
///   - Created date
///   - Quick action buttons (status change, priority, details)
class AdminFeedItemCard extends StatelessWidget {
  final FeedItemModel feedItem;
  final AdminFeedController controller;

  const AdminFeedItemCard({
    super.key,
    required this.feedItem,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = controller.getTypeColor(feedItem.type);
    final statusColor = controller.getStatusColor(feedItem.status);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.grey.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type Badge + Status + Priority
                _buildTopRow(isDark, typeColor, statusColor),
                SizedBox(height: 12.h),

                // Middle: Reference & Author
                _buildMiddleRow(isDark),
                SizedBox(height: 12.h),

                // Bottom: Meta info + Actions
                _buildBottomRow(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Top Row ====================

  Widget _buildTopRow(bool isDark, Color typeColor, Color statusColor) {
    return Row(
      children: [
        // Feed Type Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                controller.getTypeIcon(feedItem.type),
                size: 14,
                color: typeColor,
              ),
              SizedBox(width: 5.w),
              Text(
                controller.getTypeLabel(feedItem.type),
                style: getBoldTextStyle(fontSize: 11, color: typeColor),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Status Chip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                feedItem.status,
                style: getBoldTextStyle(fontSize: 10, color: statusColor),
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),

        // Priority Chip
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: controller
                .getPriorityColor(feedItem.priority)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            controller.getPriorityLabel(feedItem.priority),
            style: getBoldTextStyle(
              fontSize: 10,
              color: controller.getPriorityColor(feedItem.priority),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Middle Row ====================

  Widget _buildMiddleRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Feed ID
        Row(
          children: [
            Icon(
              Iconsax.hashtag,
              size: 13,
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: feedItem.feedId));
                  Get.snackbar(
                    'Copied',
                    'Feed ID copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                  );
                },
                child: Text(
                  feedItem.feedId,
                  style: getTextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),

        // Reference ID
        if (feedItem.refId != null && feedItem.refId!.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Iconsax.link,
                size: 13,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
              SizedBox(width: 4.w),
              Text(
                '${AppStrings.adminFeedRefId}: ',
                style: getTextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  feedItem.refId!,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.white : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Native Ad: show adUnitId
        if (feedItem.isNativeAd && feedItem.meta.adUnitId != null) ...[
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Iconsax.code, size: 13, color: AppColors.warning),
              SizedBox(width: 4.w),
              Text(
                'Ad Unit: ',
                style: getTextStyle(fontSize: 11, color: AppColors.warning),
              ),
              Expanded(
                child: Text(
                  feedItem.meta.adUnitId!,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.white : AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ==================== Bottom Row ====================

  Widget _buildBottomRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Created Date
        Icon(
          Iconsax.calendar,
          size: 13,
          color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Text(
          _formatDate(feedItem.createdAt),
          style: getTextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
        ),

        // Meta Info
        if (feedItem.meta.adminPinned) ...[
          SizedBox(width: 10.w),
          Icon(Iconsax.attach_square, size: 13, color: AppColors.primary),
          SizedBox(width: 2.w),
          Text(
            AppStrings.adminFeedPinned,
            style: getTextStyle(fontSize: 10, color: AppColors.primary),
          ),
        ],

        if (feedItem.meta.boosted) ...[
          SizedBox(width: 10.w),
          Icon(Iconsax.flash, size: 13, color: AppColors.warning),
          SizedBox(width: 2.w),
          Text(
            AppStrings.adminFeedBoosted,
            style: getTextStyle(fontSize: 10, color: AppColors.warning),
          ),
        ],

        const Spacer(),

        // Quick Actions
        _buildActionButton(
          icon: Iconsax.more,
          color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
          onTap: () => _showActionMenu(context, isDark),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ==================== Action Menu ====================

  void _showActionMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGrey : AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                AppStrings.adminFeedActions,
                style: getBoldTextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.dark,
                ),
              ),
              SizedBox(height: 16.h),

              // Status Actions
              if (feedItem.status != FeedStatus.active)
                _buildActionTile(
                  icon: Iconsax.tick_circle,
                  label: AppStrings.adminFeedActive,
                  color: AppColors.success,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    _changeStatus(FeedStatus.active);
                  },
                ),
              if (feedItem.status != FeedStatus.disabled)
                _buildActionTile(
                  icon: Iconsax.close_circle,
                  label: AppStrings.adminFeedDisabled,
                  color: AppColors.warning,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    _changeStatus(FeedStatus.disabled);
                  },
                ),
              if (feedItem.status != FeedStatus.hidden)
                _buildActionTile(
                  icon: Iconsax.eye_slash,
                  label: AppStrings.adminFeedHidden,
                  color: AppColors.darkGrey,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    _changeStatus(FeedStatus.hidden);
                  },
                ),
              if (feedItem.status != FeedStatus.removed)
                _buildActionTile(
                  icon: Iconsax.trash,
                  label: AppStrings.adminFeedRemoved,
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    _confirmRemove();
                  },
                ),

              Divider(
                color: isDark
                    ? AppColors.darkGrey.withValues(alpha: 0.3)
                    : AppColors.grey,
              ),

              // Priority Action
              _buildActionTile(
                icon: Iconsax.arrow_up_3,
                label: AppStrings.adminFeedChangePriority,
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  _showPriorityPicker();
                },
              ),

              // Detail Sheet
              _buildActionTile(
                icon: Iconsax.info_circle,
                label: AppStrings.adminFeedDetailTitle,
                color: AppColors.info,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  _showDetailSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: getTextStyle(
          fontSize: 14,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 16,
        color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
      ),
    );
  }

  // ==================== Status Change ====================

  void _changeStatus(String newStatus) async {
    final success = await controller.updateStatus(
      feedId: feedItem.feedId,
      newStatus: newStatus,
    );

    if (success) {
      Get.snackbar(
        AppStrings.adminFeedStatusUpdated,
        '${controller.getTypeLabel(feedItem.type)} → $newStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _confirmRemove() {
    Get.defaultDialog(
      title: AppStrings.confirm,
      middleText: AppStrings.adminFeedConfirmRemove,
      textConfirm: AppStrings.confirm,
      textCancel: AppStrings.cancel,
      confirmTextColor: AppColors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back();
        _changeStatus(FeedStatus.removed);
      },
    );
  }

  // ==================== Priority Picker ====================

  void _showPriorityPicker() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final priorities = [
      (FeedPriority.low, AppStrings.adminFeedPriorityLow, AppColors.darkGrey),
      (
        FeedPriority.normal,
        AppStrings.adminFeedPriorityNormal,
        AppColors.primary,
      ),
      (
        FeedPriority.important,
        AppStrings.adminFeedPriorityImportant,
        AppColors.warning,
      ),
      (
        FeedPriority.critical,
        AppStrings.adminFeedPriorityCritical,
        AppColors.error,
      ),
    ];

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGrey : AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                AppStrings.adminFeedChangePriority,
                style: getBoldTextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.dark,
                ),
              ),
              SizedBox(height: 16.h),
              ...priorities.map(
                (p) => ListTile(
                  onTap: () async {
                    Get.back();
                    final success = await controller.updatePriority(
                      feedId: feedItem.feedId,
                      newPriority: p.$1,
                    );
                    if (success) {
                      Get.snackbar(
                        AppStrings.adminFeedPriorityUpdated,
                        '${controller.getTypeLabel(feedItem.type)} → ${p.$2}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.9,
                        ),
                        colorText: AppColors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: p.$3.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Iconsax.arrow_up_3, size: 18, color: p.$3),
                  ),
                  title: Text(
                    p.$2,
                    style: getTextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.white : AppColors.dark,
                    ),
                  ),
                  trailing: feedItem.priority == p.$1
                      ? Icon(
                          Iconsax.tick_circle5,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Detail Sheet ====================

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AdminFeedDetailSheet(feedItem: feedItem, controller: controller),
    );
  }

  // ==================== Helpers ====================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
