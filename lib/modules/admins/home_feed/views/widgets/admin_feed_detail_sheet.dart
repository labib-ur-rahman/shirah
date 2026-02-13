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

/// Admin Feed Detail Sheet - Full-detail bottom sheet for a feed item
///
/// Shows comprehensive information:
///   - Feed ID with copy action
///   - Type, Status, Priority, Visibility
///   - Reference ID
///   - Author ID
///   - Meta fields (pinned, boosted, emergency pause)
///   - Rules (minGap, maxPerSession) for ads
///   - Created date
class AdminFeedDetailSheet extends StatelessWidget {
  final FeedItemModel feedItem;
  final AdminFeedController controller;

  const AdminFeedDetailSheet({
    super.key,
    required this.feedItem,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkGrey : AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                AppStrings.adminFeedDetailTitle,
                style: getBoldTextStyle(
                  fontSize: 18,
                  color: isDark ? AppColors.white : AppColors.dark,
                ),
              ),
              SizedBox(height: 20.h),

              // Feed ID (copyable)
              _buildDetailRow(
                icon: Iconsax.hashtag,
                label: 'Feed ID',
                value: feedItem.feedId,
                isDark: isDark,
                copyable: true,
              ),
              _buildDivider(isDark),

              // Type
              _buildDetailRow(
                icon: controller.getTypeIcon(feedItem.type),
                label: AppStrings.adminFeedType,
                value: controller.getTypeLabel(feedItem.type),
                isDark: isDark,
                valueColor: controller.getTypeColor(feedItem.type),
              ),
              _buildDivider(isDark),

              // Status
              _buildDetailRow(
                icon: Iconsax.status,
                label: AppStrings.adminFeedStatus,
                value: feedItem.status,
                isDark: isDark,
                valueColor: controller.getStatusColor(feedItem.status),
              ),
              _buildDivider(isDark),

              // Priority
              _buildDetailRow(
                icon: Iconsax.arrow_up_3,
                label: AppStrings.adminFeedPriority,
                value:
                    '${controller.getPriorityLabel(feedItem.priority)} (${feedItem.priority})',
                isDark: isDark,
                valueColor: controller.getPriorityColor(feedItem.priority),
              ),
              _buildDivider(isDark),

              // Visibility
              _buildDetailRow(
                icon: Iconsax.eye,
                label: AppStrings.adminFeedVisibility,
                value: feedItem.visibility,
                isDark: isDark,
              ),
              _buildDivider(isDark),

              // Reference ID
              _buildDetailRow(
                icon: Iconsax.link,
                label: AppStrings.adminFeedRefId,
                value: feedItem.refId ?? AppStrings.adminFeedNoRef,
                isDark: isDark,
                copyable: feedItem.refId != null,
              ),
              _buildDivider(isDark),

              // Author ID
              _buildDetailRow(
                icon: Iconsax.user,
                label: AppStrings.adminFeedAuthorId,
                value: feedItem.meta.authorId ?? '—',
                isDark: isDark,
                copyable: feedItem.meta.authorId != null,
              ),
              _buildDivider(isDark),

              // Created At
              _buildDetailRow(
                icon: Iconsax.calendar,
                label: AppStrings.adminFeedCreatedAt,
                value: _formatFullDate(feedItem.createdAt),
                isDark: isDark,
              ),
              _buildDivider(isDark),

              // Meta: Pinned
              _buildBoolRow(
                icon: Iconsax.attach_square,
                label: AppStrings.adminFeedPinned,
                value: feedItem.meta.adminPinned,
                isDark: isDark,
              ),
              _buildDivider(isDark),

              // Meta: Boosted
              _buildBoolRow(
                icon: Iconsax.flash,
                label: AppStrings.adminFeedBoosted,
                value: feedItem.meta.boosted,
                isDark: isDark,
              ),

              // Native Ad specific fields
              if (feedItem.isNativeAd) ...[
                _buildDivider(isDark),
                SizedBox(height: 12.h),
                Text(
                  AppStrings.adminNativeAdRules,
                  style: getBoldTextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.dark,
                  ),
                ),
                SizedBox(height: 12.h),

                // Ad Unit ID
                if (feedItem.meta.adUnitId != null)
                  _buildDetailRow(
                    icon: Iconsax.code,
                    label: AppStrings.adminNativeAdUnitId,
                    value: feedItem.meta.adUnitId!,
                    isDark: isDark,
                    copyable: true,
                  ),
                if (feedItem.meta.adUnitId != null) _buildDivider(isDark),

                // Platform
                if (feedItem.meta.platform != null)
                  _buildDetailRow(
                    icon: Iconsax.mobile,
                    label: AppStrings.adminNativeAdPlatform,
                    value: feedItem.meta.platform!,
                    isDark: isDark,
                  ),
                if (feedItem.meta.platform != null) _buildDivider(isDark),

                // Emergency Pause
                _buildBoolRow(
                  icon: Iconsax.warning_2,
                  label: AppStrings.adminNativeAdEmergencyPause,
                  value: feedItem.meta.emergencyPause,
                  isDark: isDark,
                  trueColor: AppColors.error,
                ),
                _buildDivider(isDark),

                // Rules
                if (feedItem.rules != null) ...[
                  _buildDetailRow(
                    icon: Iconsax.ruler,
                    label: AppStrings.adminNativeAdMinGap,
                    value: '${feedItem.rules!.minGap} posts',
                    isDark: isDark,
                  ),
                  _buildDivider(isDark),
                  _buildDetailRow(
                    icon: Iconsax.maximize_4,
                    label: AppStrings.adminNativeAdMaxPerSession,
                    value: '${feedItem.rules!.maxPerSession} ads',
                    isDark: isDark,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ==================== Detail Rows ====================

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
    bool copyable = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: getTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          valueColor ??
                          (isDark ? AppColors.white : AppColors.dark),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                if (copyable) ...[
                  SizedBox(width: 6.w),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      Get.snackbar(
                        'Copied',
                        '$label copied',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 1),
                      );
                    },
                    child: Icon(
                      Iconsax.copy,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoolRow({
    required IconData icon,
    required String label,
    required bool value,
    required bool isDark,
    Color? trueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: value
                  ? (trueColor ?? AppColors.success).withValues(alpha: 0.12)
                  : AppColors.darkGrey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: getBoldTextStyle(
                fontSize: 11,
                color: value
                    ? (trueColor ?? AppColors.success)
                    : AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? AppColors.white.withValues(alpha: 0.06)
          : AppColors.grey.withValues(alpha: 0.5),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $h:$m';
  }
}
