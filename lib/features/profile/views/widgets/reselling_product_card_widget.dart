import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';

class ResellingProductCardWidget extends StatelessWidget {
  const ResellingProductCardWidget({
    super.key,
    required this.productName,
    required this.description,
    required this.imageUrl,
    required this.wholesalePrice,
    required this.maxSellingPrice,
    required this.earningUpto,
    this.colors,
    this.sizes,
    this.onSellNow,
    this.imageCount = 1,
    this.activeImageIndex = 0,
  });

  final String productName;
  final String description;
  final String imageUrl;
  final String wholesalePrice;
  final String maxSellingPrice;
  final String earningUpto;
  final List<Color>? colors;
  final List<String>? sizes;
  final VoidCallback? onSellNow;
  final int imageCount;
  final int activeImageIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product Image ───────────────────────────────────
          _ProductImageSection(
            imageUrl: imageUrl,
            imageCount: imageCount,
            activeImageIndex: activeImageIndex,
          ),

          // ── Product Details ─────────────────────────────────
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  productName,
                  style: getBoldTextStyle(
                    fontSize: 16,
                    color: const Color(0xFF1E2939),
                  ),
                ),
                SizedBox(height: 6.h),

                // Description
                Text(
                  description,
                  style: getTextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6A7282),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.h),

                // Colors or Sizes
                if (colors != null && colors!.isNotEmpty)
                  _ColorsRow(colors: colors!),
                if (sizes != null && sizes!.isNotEmpty)
                  _SizesRow(sizes: sizes!),

                SizedBox(height: 10.h),

                // Wholesale / Max Selling price row
                _PriceRow(
                  wholesalePrice: wholesalePrice,
                  maxSellingPrice: maxSellingPrice,
                ),

                SizedBox(height: 10.h),

                // Earning card
                _EarningCard(earningUpto: earningUpto),

                SizedBox(height: 12.h),

                // Sell Now button
                _SellNowButton(onTap: onSellNow),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Image Section with badge + arrows + dots
// ─────────────────────────────────────────────────────────────────────────────

class _ProductImageSection extends StatelessWidget {
  const _ProductImageSection({
    required this.imageUrl,
    required this.imageCount,
    required this.activeImageIndex,
  });

  final String imageUrl;
  final int imageCount;
  final int activeImageIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image
        AspectRatio(
          aspectRatio: 1.0,
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFF3F4F6)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: Icon(
                      Iconsax.image,
                      size: 48.w,
                      color: AppColors.darkGrey,
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFFF3F4F6),
                  child: Icon(
                    Iconsax.image,
                    size: 48.w,
                    color: AppColors.darkGrey,
                  ),
                ),
        ),

        // RESELLING Badge (top right)
        Positioned(
          top: 8.h,
          right: 8.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C950), Color(0xFF009966)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.repeat, size: 13.w, color: AppColors.white),
                SizedBox(width: 5.w),
                Text(
                  AppStrings.reselling.toUpperCase(),
                  style: getBoldTextStyle(fontSize: 11, color: AppColors.white),
                ),
              ],
            ),
          ),
        ),

        // Right arrow button (middle right)
        Positioned(
          right: 8.w,
          top: 0,
          bottom: 20.h,
          child: Center(
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.arrow_right_3,
                size: 14.w,
                color: AppColors.white,
              ),
            ),
          ),
        ),

        // Dots indicator (bottom center)
        if (imageCount > 1)
          Positioned(
            bottom: 10.h,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(imageCount, (i) {
                  final isActive = i == activeImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: isActive ? 20.w : 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Colors Row
// ─────────────────────────────────────────────────────────────────────────────

class _ColorsRow extends StatelessWidget {
  const _ColorsRow({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppStrings.profileColors,
          style: getTextStyle(fontSize: 12, color: const Color(0xFF6A7282)),
        ),
        SizedBox(width: 8.w),
        ...colors.map(
          (c) => Container(
            margin: EdgeInsets.only(right: 6.w),
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2.w),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sizes Row
// ─────────────────────────────────────────────────────────────────────────────

class _SizesRow extends StatelessWidget {
  const _SizesRow({required this.sizes});
  final List<String> sizes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppStrings.profileSizes,
          style: getTextStyle(fontSize: 12, color: const Color(0xFF6A7282)),
        ),
        SizedBox(width: 8.w),
        ...sizes.map(
          (s) => Container(
            margin: EdgeInsets.only(right: 6.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              s,
              style: getTextStyle(fontSize: 12, color: const Color(0xFF4A5565)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Price Row
// ─────────────────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.wholesalePrice,
    required this.maxSellingPrice,
  });

  final String wholesalePrice;
  final String maxSellingPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.profileWholesale,
              style: getTextStyle(fontSize: 12, color: const Color(0xFF6A7282)),
            ),
            SizedBox(height: 2.h),
            Text(
              wholesalePrice,
              style: getBoldTextStyle(
                fontSize: 14,
                color: const Color(0xFF364153),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppStrings.profileMaxSelling,
              style: getTextStyle(fontSize: 12, color: const Color(0xFF6A7282)),
            ),
            SizedBox(height: 2.h),
            Text(
              maxSellingPrice,
              style: getBoldTextStyle(
                fontSize: 14,
                color: const Color(0xFF364153),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Earning Card
// ─────────────────────────────────────────────────────────────────────────────

class _EarningCard extends StatelessWidget {
  const _EarningCard({required this.earningUpto});
  final String earningUpto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5), Color(0xFFF0FDFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFB9F8CF), width: 1.2.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + earning amount
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C950), Color(0xFF009966)],
                    begin: Alignment(0, 0),
                    end: Alignment(1, 1),
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Iconsax.money_send,
                  size: 18.w,
                  color: AppColors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.profileYourEarningUpto,
                    style: getTextStyle(
                      fontSize: 12,
                      color: const Color(0xFF008236),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    earningUpto,
                    style: getBoldTextStyle(
                      fontSize: 20,
                      color: const Color(0xFF00A63E),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Per Sale badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00C950).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              AppStrings.profilePerSale,
              style: getBoldTextStyle(
                fontSize: 12,
                color: const Color(0xFF00A63E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sell Now Button
// ─────────────────────────────────────────────────────────────────────────────

class _SellNowButton extends StatelessWidget {
  const _SellNowButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C950), Color(0xFF009966)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            AppStrings.profileSellNow,
            style: getBoldTextStyle(fontSize: 16, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
