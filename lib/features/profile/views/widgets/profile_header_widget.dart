import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Facebook-style profile header:
/// ┌────────────────────────────────────┐  ← Cover (170.h)
/// │            cover image             │
/// │  ╔═══════╗                         │
/// │  ║       ║  ← avatar (50% inside)  │
/// │  ╚═══════╝                         │
/// └────────────────────────────────────┘
///    ║       ║  ← avatar (50% outside, overflows)
///    ╚═══════╝
///  Name + memberCount        [Edit Btn]
///  bio text…
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.coverUrl,
    required this.bio,
    required this.communityMembersCount,
    this.onEditProfile,
    this.onAvatarTap,
    this.onCoverTap,
    this.onBioTap,
    this.isUploadingAvatar = false,
    this.isUploadingCover = false,
  });

  final String name;
  final String avatarUrl;
  final String coverUrl;
  final String bio;
  final String communityMembersCount;
  final VoidCallback? onEditProfile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCoverTap;
  final VoidCallback? onBioTap;
  final bool isUploadingAvatar;
  final bool isUploadingCover;

  static const double _coverHeight = 180;
  static const double _avatarSize = 100;
  static const double _avatarBorder = 3.5;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;

    return Container(
      margin: EdgeInsets.only(top: 10.h, left: 10.w, right: 10.w),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover + Avatar (overlapping stack) ───────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover Image (tappable)
              GestureDetector(
                onTap: onCoverTap,
                child: Stack(
                  children: [
                    _CoverImage(coverUrl: coverUrl, height: _coverHeight),
                    if (isUploadingCover)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Avatar — bottom-left, 50% overflowing below the cover
              Positioned(
                left: 30.w,
                bottom: -(_avatarSize / 2),
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Stack(
                    children: [
                      _AvatarWidget(
                        avatarUrl: avatarUrl,
                        size: _avatarSize.w,
                        borderWidth: _avatarBorder.w,
                      ),
                      if (isUploadingAvatar)
                        Positioned.fill(
                          child: ClipOval(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Spacer = the bottom half of the avatar that overflows
          SizedBox(height: (_avatarSize / 2 + 12).h),

          // ── Name + Edit Button ────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + community members
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: getBoldTextStyle(
                          fontSize: 22,
                          color: appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            Iconsax.people,
                            size: 15.w,
                            color: appColors.textSecondary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '$communityMembersCount ${AppStrings.profileCommunityMembers}',
                            style: getBoldTextStyle(
                              fontSize: 12,
                              color: appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Edit Profile button
                _EditProfileButton(onTap: onEditProfile),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── Bio ───────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _BioSection(bio: bio, onTap: onBioTap, appColors: appColors),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover Image
// ─────────────────────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl, required this.height});
  final String coverUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: SizedBox(
        width: double.infinity,
        height: height.h,
        child: coverUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _CoverPlaceholder(),
                errorWidget: (_, __, ___) => _CoverPlaceholder(),
              )
            : _CoverPlaceholder(),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppStyleColors.instance.appBarGradient.withOpacity(0.4),
      ),
      child: Center(
        child: Icon(
          Iconsax.image,
          size: 36.w,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.avatarUrl,
    required this.size,
    required this.borderWidth,
  });

  final String avatarUrl;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White bordered circle avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: AppStyleColors.instance.textPrimary.withValues(
                  alpha: 0.18,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppStyleColors.instance.surface),
                    errorWidget: (_, __, ___) => _AvatarFallback(size: size),
                  )
                : _AvatarFallback(size: size),
          ),
        ),

        // Camera/Edit badge at bottom-right
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C950), Color(0xFF009966)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2.w),
            ),
            child: Icon(Iconsax.camera, size: 18.w, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;
    return Container(
      color: appColors.surface,
      child: Icon(
        Iconsax.user,
        size: size * 0.45,
        color: appColors.textSecondary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Button
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C950), Color(0xFF009966)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C950).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.edit_2, size: 14.w, color: AppColors.white),
            SizedBox(width: 6.w),
            Text(
              AppStrings.editProfile,
              style: getBoldTextStyle(fontSize: 13, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bio Section
// ─────────────────────────────────────────────────────────────────────────────

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio, this.onTap, required this.appColors});
  final String bio;
  final VoidCallback? onTap;
  final AppStyleColors appColors;

  @override
  Widget build(BuildContext context) {
    if (bio.isNotEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Text(
          bio,
          style: getTextStyle(
            fontSize: 13,
            color: appColors.textPrimary,
            lineHeight: 1.55,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Empty state — invite user to add bio
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: appColors.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: appColors.border,
            width: 1.w,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(Iconsax.edit, size: 15.w, color: appColors.textSecondary),
            SizedBox(width: 8.w),
            Text(
              AppStrings.profileBioEmpty,
              style: getTextStyle(fontSize: 13, color: appColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
