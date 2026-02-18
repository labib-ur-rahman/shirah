import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/helpers/helper_functions.dart';

/// Shop Tab - Marketplace and product listing (Coming Soon)
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final colors = AppStyleColors.instance;
        final isDark = SLHelper.isDarkMode;

        return Scaffold(
          backgroundColor: colors.background,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── Hero Banner
                _ShopHeroBanner(isDark: isDark, colors: colors),

                SizedBox(height: 32.h),

                // ── Coming Soon Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    children: [
                      // Status badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEA580C).withValues(alpha: 0.15),
                              const Color(0xFFF97316).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(
                              0xFFEA580C,
                            ).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7.w,
                              height: 7.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEA580C,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 7.w),
                            Text(
                              'Under Development',
                              style: getK2DTextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      Text(
                        'Marketplace',
                        style: getK2DTextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Text(
                        'Coming Soon',
                        style: getK2DTextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 14.h),

                      Text(
                        'Buy & sell products, explore reselling opportunities, and discover exclusive deals — all in one place.',
                        style: getTextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          lineHeight: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 36.h),

                // ── Feature Preview Cards
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s Coming',
                        style: getK2DTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _FeaturePreviewCard(
                        icon: Iconsax.shop,
                        title: 'Reselling Store',
                        description:
                            'Resell products without holding any inventory. Earn commission on every sale.',
                        accentColor: const Color(0xFF16A34A),
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _FeaturePreviewCard(
                        icon: Iconsax.shopping_bag,
                        title: 'Buy & Sell',
                        description:
                            'List your products or find great deals from other community members.',
                        accentColor: const Color(0xFFEA580C),
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _FeaturePreviewCard(
                        icon: Iconsax.tag,
                        title: 'Exclusive Deals',
                        description:
                            'Get access to members-only discounts and flash sales.',
                        accentColor: const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated hero banner with floating product icons
class _ShopHeroBanner extends StatelessWidget {
  final bool isDark;
  final AppStyleColors colors;

  const _ShopHeroBanner({required this.isDark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1025), const Color(0xFF2D1B4E)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEA580C).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16A34A).withValues(alpha: 0.07),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Layered icon stack
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 110.w,
                      height: 110.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                      ),
                    ),
                    // Main icon bg
                    Container(
                      width: 86.w,
                      height: 86.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEA580C,
                            ).withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Iconsax.shop,
                        color: Colors.white,
                        size: 38.sp,
                      ),
                    ),
                    // Floating badges
                    Positioned(
                      top: -4,
                      right: -16,
                      child: _FloatingBadge(
                        icon: Iconsax.tag,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      left: -18,
                      child: _FloatingBadge(
                        icon: Iconsax.shopping_cart,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Stat chips row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: '500+',
                      sublabel: 'Products',
                      isDark: isDark,
                    ),
                    SizedBox(width: 12.w),
                    _StatChip(
                      label: '50+',
                      sublabel: 'Sellers',
                      isDark: isDark,
                    ),
                    SizedBox(width: 12.w),
                    _StatChip(
                      label: '24/7',
                      sublabel: 'Support',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small floating badge icon
class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }
}

/// Stat chip
class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.sublabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFEA580C).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: getK2DTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFEA580C),
            ),
          ),
          Text(
            sublabel,
            style: getTextStyle(
              fontSize: 10,
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature preview card
class _FeaturePreviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final bool isDark;

  const _FeaturePreviewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: accentColor, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: getK2DTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Soon',
                        style: getTextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: getTextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    lineHeight: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            color: accentColor.withValues(alpha: 0.5),
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
