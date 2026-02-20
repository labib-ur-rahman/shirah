import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/helpers/app_helper.dart';
import 'package:shirah/features/authentication/controllers/auth_controller.dart';
import 'package:shirah/features/main/controllers/main_header_controller.dart';
import 'package:shirah/features/main/views/widgets/profile_picture.dart';
import 'package:shirah/features/personalization/onboarding/views/screens/theme_screen.dart';
import 'package:shirah/features/personalization/onboarding/views/screens/style_screen.dart';
import 'package:shirah/features/personalization/onboarding/views/screens/language_screen.dart';
import 'package:shirah/routes/app_routes.dart';

/// Custom App Drawer - Right-to-left sliding drawer with professional design
/// Theme changes propagate via widget tree rebuild — no Obx needed for theme
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MainHeaderController.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * 0.82;
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;

    return _buildDrawerWithAnimation(
      context,
      isDark,
      colors,
      controller,
      drawerWidth,
    );
  }

  Widget _buildDrawerWithAnimation(
    BuildContext context,
    bool isDark,
    AppStyleColors colors,
    MainHeaderController controller,
    double drawerWidth,
  ) {
    return AnimatedBuilder(
      animation: controller.drawerAnimationController,
      builder: (context, child) {
        // Calculate drawer position: starts off-screen (right), slides in
        final slideOffset =
            (1.0 - controller.drawerAnimationController.value) * drawerWidth;

        return Stack(
          children: [
            /// -- Dark Overlay (tap to close)
            if (controller.isDrawerOpen)
              GestureDetector(
                onTap: controller.closeDrawer,
                child: Container(
                  color: Colors.black.withValues(
                    alpha: controller.drawerOverlayAnimation.value,
                  ),
                ),
              ),

            /// -- Drawer Panel (slides from right edge)
            Positioned(
              right: -slideOffset,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: _buildDrawerContent(context, isDark, colors, controller),
            ),

            /// -- Close Button
            if (controller.isDrawerOpen)
              Positioned(
                top: AppHelper.statusBarHeight + 8.h,
                right: 20.w,
                child: GestureDetector(
                  onTap: MainHeaderController.instance.closeDrawer,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build the drawer content panel
  Widget _buildDrawerContent(
    BuildContext context,
    bool isDark,
    AppStyleColors colors,
    MainHeaderController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          /// -- Header with gradient and profile
          _buildHeader(isDark),

          /// -- Wallet & Reward Section
          _buildWalletRewardSection(isDark),

          SizedBox(height: 16.h),

          /// -- Divider
          Divider(
            height: 1,
            color: colors.border,
            indent: 20.w,
            endIndent: 20.w,
          ),

          SizedBox(height: 16.h),

          /// -- Menu Items
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// -- Appearance Section
                  _buildSectionTitle('Appearance', isDark),
                  SizedBox(height: 8.h),
                  _buildMenuItem(
                    icon: isDark ? Iconsax.sun_1 : Iconsax.moon,
                    title: 'Theme',
                    subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.to(() => const ThemeScreen(isFromSplash: false));
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.colorfilter,
                    title: 'App Style',
                    subtitle: 'Customize colors',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.to(() => const StyleScreen());
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.language_circle,
                    title: 'Language',
                    subtitle: AppHelper.isBangla ? 'বাংলা' : 'English',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.to(() => const LanguageScreen(isFromSplash: false));
                    },
                  ),

                  SizedBox(height: 20.h),

                  /// -- Quick Access Section
                  _buildSectionTitle('Quick Access', isDark),
                  SizedBox(height: 8.h),
                  _buildMenuItem(
                    icon: Iconsax.message_text_1,
                    title: 'Feeds',
                    subtitle: 'Community posts',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.toNamed(AppRoutes.COMMUNITY);
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.wallet_2,
                    title: 'Wallet',
                    subtitle: 'Manage your balance',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      // Navigate to wallet tab
                      controller.changeTab(4); // Profile tab for now
                      Get.snackbar(
                        'Wallet',
                        'Navigate to Wallet section',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.gift,
                    title: 'Rewards',
                    subtitle: 'View your points',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.snackbar(
                        'Rewards',
                        'Navigate to Rewards section',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.people,
                    title: 'Referrals',
                    subtitle: 'Invite friends & earn',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.snackbar(
                        'Referrals',
                        'Navigate to Referrals section',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  SizedBox(height: 20.h),

                  /// -- Support Section
                  _buildSectionTitle('Support', isDark),
                  SizedBox(height: 8.h),
                  _buildMenuItem(
                    icon: Iconsax.message_question,
                    title: 'Help & FAQ',
                    subtitle: 'Get support',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.snackbar(
                        'Help',
                        'Navigate to Help section',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Iconsax.info_circle,
                    title: 'About',
                    subtitle: 'App information',
                    isDark: isDark,
                    onTap: () {
                      controller.closeDrawer();
                      Get.snackbar(
                        'About',
                        'SHIRAH v1.0.0',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),

          /// -- Logout Button
          _buildLogoutButton(isDark, controller),
        ],
      ),
    );
  }

  /// Build header with gradient and profile
  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppStyleColors.instance.appBarGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppHelper.statusBarHeight - 12.h),

          /// -- Profile Picture
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.w),
                ),
                child: ProfilePicture(
                  width: 64.w,
                  height: 64.w,
                  imageUrl: 'https://avatars.githubusercontent.com/u/177158869',
                  showBorder: false,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labib Rahman',
                      style: getBoldTextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '+880 1700-000000',
                      style: getTextStyle(fontSize: 13, color: Colors.white70),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'SA7K9Q2L',
                        style: getBoldTextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build wallet and reward balance section
  Widget _buildWalletRewardSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          /// -- Wallet Balance
          Expanded(
            child: _buildBalanceCard(
              icon: Iconsax.wallet_2,
              title: 'Wallet',
              value: '৳ 2,500',
              isDark: isDark,
              gradientColors: [
                AppStyleColors.instance.primary,
                AppStyleColors.instance.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          /// -- Reward Points
          Expanded(
            child: _buildBalanceCard(
              icon: Iconsax.medal_star,
              title: 'Rewards',
              value: '1,250 pts',
              isDark: isDark,
              gradientColors: [
                const Color(0xFFFF9800),
                const Color(0xFFFF5722),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build balance card widget
  Widget _buildBalanceCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Text(
                title,
                style: getTextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: getBoldTextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(String title, bool isDark) {
    final colors = AppStyleColors.instance;
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title.toUpperCase(),
        style: getBoldTextStyle(fontSize: 11, color: colors.textSecondary),
      ),
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final colors = AppStyleColors.instance;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            /// -- Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.sp, color: colors.primary),
            ),
            SizedBox(width: 12.w),

            /// -- Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getBoldTextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: getTextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            /// -- Arrow
            Icon(
              Iconsax.arrow_right_3,
              size: 18.sp,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Build logout button
  Widget _buildLogoutButton(bool isDark, MainHeaderController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: GestureDetector(
        onTap: () {
          controller.closeDrawer();
          AuthController.instance.logout();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.logout, size: 20.sp, color: Colors.red),
              SizedBox(width: 8.w),
              Text(
                'Logout',
                style: getBoldTextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
