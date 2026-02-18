import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shirah/core/common/widgets/shimmers/shimmer.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/core/utils/constants/sizes.dart';
import 'package:shirah/core/utils/helpers/helper_functions.dart';

class AppCircularImage extends StatelessWidget {
  const AppCircularImage({
    super.key,
    this.width = 56,
    this.height = 56,
    this.overlayColor,
    this.backgroundColor,
    required this.image,
    this.placeholder,
    this.fit = BoxFit.cover,
    this.padding = AppSizes.sm,
    this.isNetworkImage = false,
    this.onPressed,
  });

  final BoxFit? fit;
  final String image;
  final IconData? placeholder;
  final bool isNetworkImage;
  final Color? overlayColor;
  final Color? backgroundColor;
  final double width, height, padding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = SLHelper.isDarkMode;
    final size = math.min(width, height);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          // If image background color is null then switch it to light and dark mode color design.
          color: backgroundColor ?? (dark ? AppColors.black : AppColors.white),
          borderRadius: BorderRadius.circular(100),
        ),

        child: ClipOval(
          child: isNetworkImage
              ? CachedNetworkImage(
                  fit: fit,
                  color: overlayColor,
                  imageUrl: image,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      AppShimmerEffect(width: 55, height: 55, radius: 55),
                  errorWidget: (context, url, error) => placeholder != null
                      ? Icon(placeholder, color: overlayColor)
                      : const Icon(Icons.error),
                )
              : Image(fit: fit, image: AssetImage(image), color: overlayColor),
        ),
      ),
    );
  }
}
