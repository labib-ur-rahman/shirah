import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/helpers/helper_functions.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

/// Profile Tab - Modern social media style profile screen
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (_) {
        return Obx(() {
          final controller = UserController.instance;
          final colors = AppStyleColors.instance;
          final isDark = SLHelper.isDarkMode;
          final user = controller.user.value;

          final String fullName = controller.fullName.isNotEmpty
              ? controller.fullName
              : 'shirah User';
          final String phone = controller.phone.isNotEmpty
              ? controller.phone
              : '+880 1XXX-XXXXXX';
          final String inviteCode = controller.inviteCode;
          final String photoURL = controller.avatarUrl;
          final String coverURL = controller.coverUrl;
          final bool isVerified = controller.isVerified;
          final bool isSubscribed = controller.isSubscribed;
          final String accountState = user?.status.accountState ?? 'active';
          final double balance = controller.balance;
          final int rewardPoints = controller.rewardPoints;
          final String role = user?.role ?? 'user';

          return Scaffold(
            backgroundColor: colors.background,
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Cover + Avatar
                  _CoverSection(
                    coverURL: coverURL,
                    photoURL: photoURL,
                    isDark: isDark,
                    colors: colors,
                  ),

                  // ── Name + Badges (with top padding for avatar overlap)
                  _NameSection(
                    fullName: fullName,
                    phone: phone,
                    inviteCode: inviteCode,
                    isVerified: isVerified,
                    isSubscribed: isSubscribed,
                    accountState: accountState,
                    role: role,
                    colors: colors,
                  ),

                  SizedBox(height: 24.h),

                  // ── Stats Row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _StatsRow(
                      balance: balance,
                      rewardPoints: rewardPoints,
                      colors: colors,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ── Account Info Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _AccountInfoSection(
                      phone: phone,
                      email: controller.email,
                      accountState: accountState,
                      isVerified: isVerified,
                      inviteCode: inviteCode,
                      colors: colors,
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// ─────────────────────────────────────────────────
// COVER + AVATAR
// ─────────────────────────────────────────────────
class _CoverSection extends StatelessWidget {
  final String coverURL;
  final String photoURL;
  final bool isDark;
  final AppStyleColors colors;

  const _CoverSection({
    required this.coverURL,
    required this.photoURL,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image / gradient
        Container(
          width: double.infinity,
          height: 180.h,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppStyleColors.instance.appBarGradient,
          ),
          child: coverURL.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: coverURL,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(),
                  errorWidget: (_, __, ___) => const SizedBox(),
                )
              : _DefaultCoverDecoration(),
        ),

        // Bottom fade overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 70.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),

        // Avatar (overlaps cover bottom)
        Positioned(
          bottom: -46.h,
          left: 0,
          right: 0,
          child: Center(
            child: _AvatarRing(photoURL: photoURL, colors: colors),
          ),
        ),
      ],
    );
  }
}

class _DefaultCoverDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 160.w,
            height: 160.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: 100,
          child: Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: 20,
          child: Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final String photoURL;
  final AppStyleColors colors;

  const _AvatarRing({required this.photoURL, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92.w,
      height: 92.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.background, width: 4),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: photoURL.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoURL,
                fit: BoxFit.cover,
                placeholder: (_, __) => _AvatarPlaceholder(colors: colors),
                errorWidget: (_, __, ___) => _AvatarPlaceholder(colors: colors),
              )
            : _AvatarPlaceholder(colors: colors),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final AppStyleColors colors;
  const _AvatarPlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.primary.withValues(alpha: 0.15),
      child: Icon(Iconsax.user, color: colors.primary, size: 40.sp),
    );
  }
}

// ─────────────────────────────────────────────────
// NAME + BADGES
// ─────────────────────────────────────────────────
class _NameSection extends StatelessWidget {
  final String fullName;
  final String phone;
  final String inviteCode;
  final bool isVerified;
  final bool isSubscribed;
  final String accountState;
  final String role;
  final AppStyleColors colors;

  const _NameSection({
    required this.fullName,
    required this.phone,
    required this.inviteCode,
    required this.isVerified,
    required this.isSubscribed,
    required this.accountState,
    required this.role,
    required this.colors,
  });

  Color get _stateColor {
    switch (accountState) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'suspended':
        return const Color(0xFFEA580C);
      case 'banned':
        return const Color(0xFFDC2626);
      case 'under_review':
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _stateIcon {
    switch (accountState) {
      case 'active':
        return Iconsax.tick_circle;
      case 'suspended':
        return Iconsax.warning_2;
      case 'banned':
        return Iconsax.close_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  String get _stateLabel => accountState == 'active'
      ? 'Active'
      : accountState == 'under_review'
      ? 'Under Review'
      : (accountState.capitalizeFirst ?? accountState);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 54.h = avatar half (46) + 8 breathing room
      padding: EdgeInsets.only(top: 54.h, left: 20.w, right: 20.w),
      child: Column(
        children: [
          // Name row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  fullName,
                  style: getK2DTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isVerified) ...[
                SizedBox(width: 6.w),
                Icon(Iconsax.verify5, color: colors.primary, size: 20.sp),
              ],
            ],
          ),

          SizedBox(height: 4.h),

          Text(
            phone,
            style: getTextStyle(fontSize: 13, color: colors.textSecondary),
          ),

          SizedBox(height: 12.h),

          // Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _BadgeChip(
                icon: _stateIcon,
                label: _stateLabel,
                color: _stateColor,
              ),
              if (role != 'user')
                _BadgeChip(
                  icon: Iconsax.crown,
                  label: role == 'superAdmin'
                      ? 'Super Admin'
                      : (role.capitalizeFirst ?? role),
                  color: const Color(0xFF7C3AED),
                ),
              if (isSubscribed)
                _BadgeChip(
                  icon: Iconsax.star,
                  label: 'Subscribed',
                  color: const Color(0xFFEA580C),
                ),
            ],
          ),

          if (inviteCode.isNotEmpty) ...[
            SizedBox(height: 14.h),
            // Invite code pill (tap to copy)
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: inviteCode)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                decoration: BoxDecoration(
                  gradient: colors.appBarGradient,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.copy, color: Colors.white, size: 13.sp),
                    SizedBox(width: 7.w),
                    Text(
                      inviteCode,
                      style: getBebasNeueTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 1,
                      height: 14.h,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Invite Code',
                      style: getTextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: getTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final double balance;
  final int rewardPoints;
  final AppStyleColors colors;

  const _StatsRow({
    required this.balance,
    required this.rewardPoints,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.borderFocused.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '৳${balance.toStringAsFixed(2)}',
              label: 'Wallet',
              icon: Iconsax.wallet_3,
              iconColor: const Color(0xFF2563EB),
              colors: colors,
            ),
          ),
          _VertDivider(colors: colors),
          Expanded(
            child: _StatItem(
              value: '$rewardPoints',
              label: 'Points',
              icon: Iconsax.star,
              iconColor: const Color(0xFFEA580C),
              colors: colors,
            ),
          ),
          _VertDivider(colors: colors),
          Expanded(
            child: _StatItem(
              value: '৳${(rewardPoints / 100).toStringAsFixed(1)}',
              label: 'Pts Value',
              icon: Iconsax.convert,
              iconColor: const Color(0xFF16A34A),
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final AppStyleColors colors;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: iconColor, size: 18.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: getK2DTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: getTextStyle(fontSize: 10, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  final AppStyleColors colors;
  const _VertDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      width: 1,
      color: colors.borderFocused.withValues(alpha: 0.2),
    );
  }
}

// ─────────────────────────────────────────────────
// ACCOUNT INFO
// ─────────────────────────────────────────────────
class _AccountInfoSection extends StatelessWidget {
  final String phone;
  final String email;
  final String accountState;
  final bool isVerified;
  final String inviteCode;
  final AppStyleColors colors;

  const _AccountInfoSection({
    required this.phone,
    required this.email,
    required this.accountState,
    required this.isVerified,
    required this.inviteCode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.borderFocused.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 12.h),
            child: Row(
              children: [
                Icon(Iconsax.user_square, color: colors.primary, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Account Information',
                  style: getK2DTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colors.borderFocused.withValues(alpha: 0.15),
          ),
          if (phone.isNotEmpty)
            _InfoRow(
              icon: Iconsax.call,
              label: 'Phone',
              value: phone,
              iconColor: const Color(0xFF2563EB),
              colors: colors,
            ),
          if (email.isNotEmpty)
            _InfoRow(
              icon: Iconsax.sms,
              label: 'Email',
              value: email,
              iconColor: const Color(0xFF7C3AED),
              colors: colors,
            ),
          _InfoRow(
            icon: Iconsax.shield_tick,
            label: 'Verification',
            value: isVerified ? 'Verified' : 'Not Verified',
            iconColor: isVerified
                ? const Color(0xFF16A34A)
                : const Color(0xFFCA8A04),
            valueColor: isVerified
                ? const Color(0xFF16A34A)
                : const Color(0xFFCA8A04),
            colors: colors,
          ),
          if (inviteCode.isNotEmpty)
            _InfoRow(
              icon: Iconsax.link,
              label: 'Invite Code',
              value: inviteCode,
              iconColor: colors.primary,
              colors: colors,
              showCopy: true,
            ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;
  final bool showCopy;
  final AppStyleColors colors;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.colors,
    this.valueColor,
    this.showCopy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 16.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: getTextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: getTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Iconsax.copy, color: iconColor, size: 14.sp),
              ),
            ),
        ],
      ),
    );
  }
}
