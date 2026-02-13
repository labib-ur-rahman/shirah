import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/modules/admins/home_feed/controllers/admin_feed_controller.dart';
import 'package:shirah/modules/admins/home_feed/views/widgets/admin_feed_stats_card.dart';
import 'package:shirah/modules/admins/home_feed/views/widgets/admin_feed_item_card.dart';
import 'package:shirah/modules/admins/home_feed/views/widgets/admin_feed_empty_state.dart';
import 'package:shirah/modules/admins/home_feed/views/widgets/admin_feed_type_filter_chip.dart';

/// Admin Feed Management Screen
///
/// Enterprise-grade admin panel for managing home feed items.
/// Features:
///   - Dashboard stats (total, active, ads, disabled)
///   - Tab-based status filtering
///   - Type filter chips
///   - Feed item cards with quick actions
///   - Pull-to-refresh
class AdminFeedManagementScreen extends StatelessWidget {
  const AdminFeedManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminFeedController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.light,
      appBar: _buildAppBar(context, controller, isDark),
      floatingActionButton: _buildFab(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.allFeedItems.isEmpty) {
          return _buildLoadingState(isDark);
        }

        if (controller.hasError.value && controller.allFeedItems.isEmpty) {
          return _buildErrorState(controller, isDark);
        }

        return RefreshIndicator(
          onRefresh: controller.refreshFeedItems,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Stats Dashboard
              SliverToBoxAdapter(
                child: AdminFeedStatsCard(controller: controller),
              ),

              // Type Filter Chips
              SliverToBoxAdapter(
                child: AdminFeedTypeFilterChip(controller: controller),
              ),

              // Feed Items List
              _buildFeedItemsList(controller, isDark),
            ],
          ),
        );
      }),
    );
  }

  // ==================== App Bar ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AdminFeedController controller,
    bool isDark,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? AppColors.dark : AppColors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.adminFeedTitle,
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? AppColors.white : AppColors.dark,
            ),
          ),
          Text(
            AppStrings.adminFeedSubtitle,
            style: getTextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Iconsax.refresh,
            color: isDark ? AppColors.white : AppColors.dark,
            size: 20,
          ),
          onPressed: () => controller.refreshFeedItems(),
        ),
      ],
      bottom: TabBar(
        controller: controller.tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.darkGrey
            : AppColors.textSecondary,
        labelStyle: getBoldTextStyle(fontSize: 13),
        unselectedLabelStyle: getTextStyle(fontSize: 13),
        labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
        tabs: [
          Tab(text: AppStrings.adminFeedAll),
          Tab(text: AppStrings.adminFeedActive),
          Tab(text: AppStrings.adminFeedDisabled),
          Tab(text: AppStrings.adminFeedHidden),
          Tab(text: AppStrings.adminFeedRemoved),
        ],
      ),
    );
  }

  // ==================== FAB ====================

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed('/admin-create-native-ad'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      icon: const Icon(Iconsax.add_circle, size: 20),
      label: Text(
        AppStrings.adminNativeAdCreate,
        style: getBoldTextStyle(fontSize: 13, color: AppColors.white),
      ),
    );
  }

  // ==================== Feed Items List ====================

  Widget _buildFeedItemsList(AdminFeedController controller, bool isDark) {
    return Obx(() {
      if (controller.displayedFeedItems.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AdminFeedEmptyState(isDark: isDark),
        );
      }

      return SliverPadding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 100.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = controller.displayedFeedItems[index];
            return AdminFeedItemCard(feedItem: item, controller: controller);
          }, childCount: controller.displayedFeedItems.length),
        ),
      );
    });
  }

  // ==================== Loading State ====================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          SizedBox(height: 16.h),
          Text(
            AppStrings.loading,
            style: getTextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Error State ====================

  Widget _buildErrorState(AdminFeedController controller, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(
              AppStrings.error,
              style: getBoldTextStyle(
                fontSize: 18,
                color: isDark ? AppColors.white : AppColors.dark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => controller.refreshFeedItems(),
              icon: const Icon(Iconsax.refresh, size: 18),
              label: Text(AppStrings.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
