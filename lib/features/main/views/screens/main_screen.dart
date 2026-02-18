import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/helpers/helper_functions.dart';
import 'package:shirah/features/home/views/screens/home_screen.dart';
import 'package:shirah/features/main/controllers/main_header_controller.dart';
import 'package:shirah/features/main/views/screens/main_tab_bar.dart';
import 'package:shirah/features/main/views/screens/projects_tab.dart';
import 'package:shirah/features/main/views/screens/shop_tab.dart';
import 'package:shirah/features/main/views/screens/activities_tab.dart';
import 'package:shirah/features/main/views/screens/profile_tab.dart';
import 'package:shirah/features/main/views/screens/wallet_tab.dart';
import 'package:shirah/features/main/views/widgets/app_drawer.dart';

/// Main container with TabBar and TabBarView for swipeable navigation
/// This is the primary screen after login with 5 tabs:
/// - Home, Projects, Shop, Activities, Profile
///
/// Enterprise-Level Theme Management:
/// ✅ Uses GetBuilder<ThemeService> for instant theme updates
/// ✅ Background color and status bar update instantly on theme change
/// ✅ No memory leaks, no heavy Obx usage
/// ✅ Single source of truth: SLHelper.isDarkMode
///
/// Obx Usage:
/// - Only for .obs variables (isWalletVisible, isDrawerOpen)
/// - NOT for theme (GetBuilder handles theme reactivity)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = MainHeaderController.instance;

    // Set initial tab if provided
    if (initialIndex != 0 && initialIndex <= 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.changeTab(initialIndex);
      });
    }

    // GetBuilder for theme reactivity - updates on ThemeService.changeTheme()
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        // Theme values - reactive via GetBuilder
        final colors = AppStyleColors.instance;
        final isDark = SLHelper.isDarkMode;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: colors.background,
            body: Stack(
              children: [
                /// -- Main Content (Tab Bar + Tab Views)
                Column(
                  children: [
                    /// -- Tab Bar Header (Collapsible)
                    const MainTabBar(),

                    /// -- Content Area (Tab View or Wallet)
                    /// Obx here: watches controller.isWalletVisible (.obs)
                    Expanded(
                      child: Obx(() {
                        if (controller.isWalletVisible) {
                          return NotificationListener<ScrollNotification>(
                            onNotification: controller.handleScroll,
                            child: const WalletTab(),
                          );
                        }

                        return NotificationListener<ScrollNotification>(
                          onNotification: controller.handleScroll,
                          child: TabBarView(
                            controller: controller.tabController,
                            children: const [
                              HomeScreen(),
                              ProjectsTab(),
                              ShopTab(),
                              ActivitiesTab(),
                              ProfileTab(),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                /// -- Custom Drawer Overlay
                /// Obx here: watches controller.isDrawerOpen (.obs)
                Obx(() {
                  if (controller.isDrawerOpen) {
                    return const AppDrawer();
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
