import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

/// The result state of a payment transaction.
enum PaymentResultType { success, failed, cancelled, pending }

/// A premium Material 3 payment result dialog with user profile display,
/// status badges, transaction details, and contextual actions.
///
/// Usage:
/// ```dart
/// PaymentResultDialog.show(
///   type: PaymentResultType.success,
///   paymentType: 'verification',
///   title: 'Account Verified!',
///   message: 'Your account is now verified.',
///   transactionId: 'INV-123456',
///   amount: '250.00',
///   paymentMethod: 'bKash',
///   onRetry: () => controller.purchaseVerification(),
/// );
/// ```
class PaymentResultDialog extends StatelessWidget {
  const PaymentResultDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.paymentType,
    this.transactionId,
    this.amount,
    this.paymentMethod,
    this.onPrimaryAction,
    this.onRetry,
    this.primaryActionText,
  });

  final PaymentResultType type;
  final String title;
  final String message;

  /// 'verification' or 'subscription' — used to show relevant status badge
  final String? paymentType;

  final String? transactionId;
  final String? amount;
  final String? paymentMethod;
  final VoidCallback? onPrimaryAction;

  /// Retry callback for failed/cancelled states — re-invokes the payment flow.
  final VoidCallback? onRetry;

  final String? primaryActionText;

  // ───────────────────────── Factory Show ─────────────────────────

  /// Show the dialog using GetX overlay.
  static Future<void> show({
    required PaymentResultType type,
    required String title,
    required String message,
    String? paymentType,
    String? transactionId,
    String? amount,
    String? paymentMethod,
    VoidCallback? onPrimaryAction,
    VoidCallback? onRetry,
    String? primaryActionText,
  }) async {
    await Get.dialog(
      PaymentResultDialog(
        type: type,
        title: title,
        message: message,
        paymentType: paymentType,
        transactionId: transactionId,
        amount: amount,
        paymentMethod: paymentMethod,
        onPrimaryAction: onPrimaryAction,
        onRetry: onRetry,
        primaryActionText: primaryActionText,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  Color get _accentColor {
    switch (type) {
      case PaymentResultType.success:
        return AppColors.success;
      case PaymentResultType.failed:
        return AppColors.error;
      case PaymentResultType.cancelled:
        return AppColors.warning;
      case PaymentResultType.pending:
        return AppColors.info;
    }
  }

  Color get _accentBgColor {
    switch (type) {
      case PaymentResultType.success:
        return const Color(0xFFE8F5E9);
      case PaymentResultType.failed:
        return const Color(0xFFFFEBEE);
      case PaymentResultType.cancelled:
        return const Color(0xFFFFF3E0);
      case PaymentResultType.pending:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get _accentBgColorDark {
    switch (type) {
      case PaymentResultType.success:
        return const Color(0xFF1B5E20).withValues(alpha: 0.2);
      case PaymentResultType.failed:
        return const Color(0xFFB71C1C).withValues(alpha: 0.2);
      case PaymentResultType.cancelled:
        return const Color(0xFFE65100).withValues(alpha: 0.2);
      case PaymentResultType.pending:
        return const Color(0xFF0D47A1).withValues(alpha: 0.2);
    }
  }

  IconData get _icon {
    switch (type) {
      case PaymentResultType.success:
        return Iconsax.tick_circle5;
      case PaymentResultType.failed:
        return Iconsax.close_circle5;
      case PaymentResultType.cancelled:
        return Iconsax.warning_25;
      case PaymentResultType.pending:
        return Iconsax.clock5;
    }
  }

  String get _defaultPrimaryText {
    switch (type) {
      case PaymentResultType.success:
        return AppStrings.paymentResultDone;
      case PaymentResultType.failed:
        return AppStrings.paymentResultRetry;
      case PaymentResultType.cancelled:
        return AppStrings.paymentResultRetry;
      case PaymentResultType.pending:
        return AppStrings.paymentResultDone;
    }
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : AppColors.white;
    final surfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.softGrey;

    return Center(
      child: Container(
        width: 360.w,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.08),
              blurRadius: 60,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Colored Header Banner ───
              _buildHeaderBanner(isDark),

              // ─── Content ───
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ─── Title ───
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.white : AppColors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // ─── Message ───
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    // ─── User Profile (success only) ───
                    if (type == PaymentResultType.success) ...[
                      SizedBox(height: 20.h),
                      _buildUserProfileCard(isDark, surfaceColor),
                    ],

                    // ─── Transaction Details ───
                    if (_hasDetails) ...[
                      SizedBox(height: 16.h),
                      _buildDetailsCard(surfaceColor, isDark),
                    ],

                    SizedBox(height: 24.h),

                    // ─── Actions ───
                    _buildActions(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header Banner ─────────────────────────

  Widget _buildHeaderBanner(bool isDark) {
    final bannerBg = isDark ? _accentBgColorDark : _accentBgColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border(
          bottom: BorderSide(
            color: _accentColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(children: [_buildIconSection()]),
    );
  }

  // ───────────────────────── Icon Section ─────────────────────────

  Widget _buildIconSection() {
    if (type == PaymentResultType.success) {
      return SizedBox(
        width: 100.w,
        height: 100.w,
        child: Lottie.asset(
          'assets/lottie/lottie-successful.json',
          width: 100.w,
          height: 100.w,
          repeat: false,
          fit: BoxFit.contain,
        ),
      );
    }

    // Animated icon with double ring for non-success states
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentColor.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withValues(alpha: 0.12),
                ),
                child: Icon(_icon, size: 40.w, color: _accentColor),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── User Profile Card ─────────────────────────

  Widget _buildUserProfileCard(bool isDark, Color surfaceColor) {
    final userCtrl = UserController.instance;
    final name = userCtrl.fullName;
    final avatar = userCtrl.avatarUrl;
    final isVerified = userCtrl.isVerified;
    final isSubscribed = userCtrl.isSubscribed;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // ─── Avatar + Name Row ───
          Row(
            children: [
              // Avatar with success ring
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 2.w),
                ),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.softGrey,
                  child: avatar.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatar,
                            width: 48.w,
                            height: 48.w,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(
                              Iconsax.user,
                              size: 24.w,
                              color: AppColors.textSecondary,
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Iconsax.user,
                              size: 24.w,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Icon(
                          Iconsax.user,
                          size: 24.w,
                          color: AppColors.textSecondary,
                        ),
                ),
              ),
              SizedBox(width: 12.w),

              // Name + congratulations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'SHIRAH User',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      AppStrings.paymentResultCongrats,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // ─── Status Badges Row ───
          Row(
            children: [
              // Verified badge
              Expanded(
                child: _buildStatusBadge(
                  icon: Iconsax.verify5,
                  label: AppStrings.verified,
                  isActive: isVerified,
                  activeColor: AppColors.success,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 10.w),
              // Subscribed badge
              Expanded(
                child: _buildStatusBadge(
                  icon: Iconsax.crown5,
                  label: AppStrings.subscribed,
                  isActive: isSubscribed,
                  activeColor: AppColors.primary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required bool isDark,
  }) {
    final bgColor = isActive
        ? activeColor.withValues(alpha: isDark ? 0.15 : 0.1)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.softGrey);
    final textColor = isActive ? activeColor : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.borderSecondary),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: textColor),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Details Card ─────────────────────────

  bool get _hasDetails =>
      transactionId != null || amount != null || paymentMethod != null;

  Widget _buildDetailsCard(Color surfaceColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.borderSecondary,
        ),
      ),
      child: Column(
        children: [
          if (transactionId != null)
            _buildDetailRow(
              AppStrings.paymentResultTransactionId,
              transactionId!,
              isDark,
            ),
          if (amount != null) ...[
            if (transactionId != null) _buildDivider(isDark),
            _buildDetailRow(AppStrings.paymentResultAmount, '৳$amount', isDark),
          ],
          if (paymentMethod != null) ...[
            if (transactionId != null || amount != null) _buildDivider(isDark),
            _buildDetailRow(
              AppStrings.paymentResultMethod,
              paymentMethod!,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 12.h,
      thickness: 0.5,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : AppColors.borderSecondary,
    );
  }

  // ───────────────────────── Actions ─────────────────────────

  Widget _buildActions(bool isDark) {
    final bool showRetry =
        (type == PaymentResultType.failed ||
        type == PaymentResultType.cancelled);
    final bool showCheckStatus =
        type == PaymentResultType.pending && primaryActionText != null;

    return Column(
      children: [
        // Primary button — "Done" for success, "Check Status" for pending,
        // "Try Again" for fail/cancel
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: () {
              if (showRetry && onRetry != null) {
                // Close dialog first, then invoke retry
                Get.back();
                onRetry!();
              } else {
                (onPrimaryAction ?? () => Get.back())();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: showRetry
                  ? _accentColor
                  : showCheckStatus
                  ? AppColors.info
                  : AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showRetry) ...[
                  Icon(Iconsax.refresh, size: 18.w),
                  SizedBox(width: 8.w),
                ],
                if (showCheckStatus) ...[
                  Icon(Iconsax.refresh_circle, size: 18.w),
                  SizedBox(width: 8.w),
                ],
                Text(
                  primaryActionText ?? _defaultPrimaryText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Secondary close button for failed/cancelled and pending with check status
        if (showRetry || showCheckStatus) ...[
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                AppStrings.paymentResultClose,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
