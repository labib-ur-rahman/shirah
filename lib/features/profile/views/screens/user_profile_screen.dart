import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';
import 'package:shirah/features/profile/views/widgets/bio_dialog_widget.dart';
import 'package:shirah/features/profile/views/widgets/image_picker_sheet_widget.dart';
import 'package:shirah/features/profile/views/widgets/profile_header_widget.dart';
import 'package:shirah/features/profile/views/widgets/profile_stats_widget.dart';
import 'package:shirah/features/profile/views/screens/edit_profile_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final colors = AppStyleColors.instance;
        final controller = UserController.instance;

        return _buildProfileContent(colors, controller);
      },
    );
  }

  Widget _buildProfileContent(
    AppStyleColors appColors,
    UserController controller,
  ) {
    return DefaultTabController(
      length: 4,
      initialIndex: 0, // default: Community
      child: Scaffold(
        backgroundColor: appColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Header ──────────────────────────
                    ProfileHeaderWidget(
                      name: controller.fullName.isNotEmpty
                          ? controller.fullName
                          : '—',
                      avatarUrl: controller.avatarUrl,
                      coverUrl: controller.coverUrl,
                      bio: controller.userBio,
                      communityMembersCount: controller
                          .communityMemberCount
                          .value
                          .toString(),
                      isUploadingAvatar: controller.isUploadingAvatar.value,
                      isUploadingCover: controller.isUploadingCover.value,
                      onEditProfile: () =>
                          Get.to(() => const EditProfileScreen()),
                      onAvatarTap: () => ImagePickerSheetWidget.show(
                        context,
                        title: AppStrings.pickerProfilePhoto,
                        onImageSelected: (file) async {
                          final ok = await controller.uploadProfilePicture(
                            file,
                          );
                          if (ok) {
                            AppSnackBar.successSnackBar(
                              title: AppStrings.pickerAvatarSuccess,
                            );
                          } else {
                            AppSnackBar.errorSnackBar(
                              title: AppStrings.pickerUploadFailed,
                            );
                          }
                        },
                      ),
                      onCoverTap: () => ImagePickerSheetWidget.show(
                        context,
                        title: AppStrings.pickerCoverPhoto,
                        onImageSelected: (file) async {
                          final ok = await controller.uploadCoverPicture(file);
                          if (ok) {
                            AppSnackBar.successSnackBar(
                              title: AppStrings.pickerCoverSuccess,
                            );
                          } else {
                            AppSnackBar.errorSnackBar(
                              title: AppStrings.pickerUploadFailed,
                            );
                          }
                        },
                      ),
                      onBioTap: () => BioDialogWidget.show(context),
                    ),

                    SizedBox(height: 16.h),

                    // ── Stats Row ───────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ProfileStatsWidget(
                        posts: '0',
                        followers: '0',
                        following: '0',
                      ),
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ],

          // ── Tab Bar + Tab Content ──────────────────────────
          body: Column(
            children: [
              // Pinned Material Tab Bar
              Material(
                color: appColors.background,
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                  child: _ProfileTabBar(),
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _EmptyTabContent(
                      icon: Iconsax.people,
                      label: AppStrings.profileTabCommunity,
                    ),
                    _EmptyTabContent(
                      icon: Iconsax.briefcase,
                      label: AppStrings.profileTabJobPost,
                    ),
                    _EmptyTabContent(
                      icon: Iconsax.shop,
                      label: AppStrings.profileTabBuySell,
                    ),
                    _ProductsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Material Tab Bar with Gradient Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: appColors.appBarGradient.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: TabBar(
          indicator: BoxDecoration(
            gradient: appColors.appBarGradient,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: [
              BoxShadow(
                color: appColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          labelColor: AppColors.white,
          unselectedLabelColor: appColors.textPrimary,
          labelStyle: getBoldTextStyle(
            fontSize: 12,
            lineHeight: 1,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: getTextStyle(
            lineHeight: 1,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: AppStrings.profileTabCommunity),
            Tab(text: AppStrings.profileTabJobPost),
            Tab(text: AppStrings.profileTabBuySell),
            Tab(text: AppStrings.profileTabProducts),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Products Tab Content
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      children: [SizedBox(height: 24.h)],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Tab Placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTabContent extends StatelessWidget {
  const _EmptyTabContent({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: appColors.surface,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(icon, size: 32.w, color: appColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          Text(
            label,
            style: getBoldTextStyle(fontSize: 15, color: appColors.textPrimary),
          ),
          SizedBox(height: 6.h),
          Text(
            'Nothing here yet',
            style: getTextStyle(fontSize: 13, color: appColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
