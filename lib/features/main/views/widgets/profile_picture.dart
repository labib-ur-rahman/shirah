import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Profile picture widget with circular shape and cached image
/// Used in main tab bar for the Profile tab
class ProfilePicture extends StatelessWidget {
  const ProfilePicture({
    super.key,
    this.onTap,
    this.height,
    this.width,
    this.imageUrl,
    this.showBorder = true,
    this.isActive = false,
    this.fallbackIcon,
  });

  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final String? imageUrl;
  final bool showBorder;
  final bool isActive;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final size = height ?? 24.w;
    final isDark = AppStyleColors.instance.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isActive ? size + 2 : size,
        height: isActive ? size + 2 : size,
        decoration: BoxDecoration(
          color: isActive ? AppColors.white : Colors.transparent,
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(color: Colors.white, width: isActive ? 2 : 1)
              : null,
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    highlightColor: isDark
                        ? Colors.grey[500]!
                        : Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[400],
                    child: Icon(
                      fallbackIcon ?? Iconsax.user,
                      color: Colors.white,
                      size: size * 0.6,
                    ),
                  ),
                  fit: BoxFit.cover,
                )
              : Container(
                  color: Colors.grey[400],
                  child: Icon(
                    fallbackIcon ?? Iconsax.user,
                    color: Colors.white,
                    size: size * 0.6,
                  ),
                ),
        ),
      ),
    );
  }
}
