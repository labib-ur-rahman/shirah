import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/recharge/drive_offer_model.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/drive_offer_card.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/drive_offer_shimmer.dart';

/// Drive Offers Screen - Browse and purchase telecom offer packs
/// Features: Operator filter, type filter, offer list, purchase flow
class DriveOffersScreen extends StatelessWidget {
  const DriveOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = MobileRechargeController.instance;
    final appStyleColors = AppStyleColors.instance;

    // Load offers on screen open
    if (controller.driveOffers.isEmpty) {
      controller.fetchDriveOffers();
    }

    return Scaffold(
      backgroundColor:
          appStyleColors.background, // Use app style background color
      appBar: _buildAppBar(isDark, appStyleColors),
      body: Column(
        children: [
          /// -- Operator Filter
          _buildOperatorFilter(controller, isDark),
          SizedBox(height: 8.h),

          /// -- Offer Type Filter
          _buildOfferTypeFilter(controller, isDark),
          SizedBox(height: 8.h),

          /// -- Offers List
          Expanded(
            child: Obx(() {
              final isLoading = controller.isLoadingOffers.value;
              final offers = controller.driveOffers;

              if (isLoading && offers.isEmpty) {
                return const DriveOfferShimmer();
              }

              if (!isLoading && offers.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: controller.fetchDriveOffers,
                color: AppColors.primary,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return DriveOfferCard(
                      offer: offer,
                      onBuy: () => _showPurchaseSheet(
                        context,
                        controller,
                        offer,
                        isDark,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppStyleColors appStyleColors) {
    return AppBar(
      title: Text(
        AppStrings.telecomOffers,
        style: getBoldTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
      ),
      centerTitle: true,
      backgroundColor: appStyleColors.primary.withValues(
        alpha: 0.05,
      ), // Use app style color for better theming
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildOperatorFilter(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return SizedBox(
      height: 36.h,
      child: Obx(() {
        final selected = controller.selectedOfferOperator.value;
        return ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            _buildFilterChip(
              label: AppStrings.viewAll,
              isSelected: selected.isEmpty,
              isDark: isDark,
              onTap: () => controller.filterOffersByOperator(''),
            ),
            SizedBox(width: 8.w),
            ...MobileRechargeController.operators.map((op) {
              final letterCode =
                  MobileRechargeController.codeToLetterMap[op['code']!] ?? '';
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildFilterChip(
                  label: op['short']!,
                  isSelected: selected == letterCode,
                  isDark: isDark,
                  color: _operatorColor(op['short']!),
                  onTap: () => controller.filterOffersByOperator(letterCode),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildOfferTypeFilter(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return SizedBox(
      height: 34.h,
      child: Obx(() {
        final selected = controller.selectedOfferType.value;
        return ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: MobileRechargeController.offerTypes.map((type) {
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: _buildFilterChip(
                label: type['label']!,
                isSelected: selected == type['value'],
                isDark: isDark,
                onTap: () => controller.filterOffersByType(type['value']!),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppStyleColors.instance.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? chipColor
                : isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.grey,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: getBoldTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.white
                  : isDark
                  ? AppColors.white.withValues(alpha: 0.54)
                  : AppColors.darkerGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.simcard,
            size: 64.sp,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.16)
                : AppColors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            AppStrings.noOffersFound,
            style: getBoldTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.38)
                  : AppColors.darkGrey,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            AppStrings.tryAgain,
            style: getTextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.24)
                  : AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseSheet(
    BuildContext context,
    MobileRechargeController controller,
    DriveOfferModel offer,
    bool isDark,
  ) {
    final phoneCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dark : AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.16)
                      : AppColors.grey,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            Text(
              AppStrings.buyNow,
              style: getBoldTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.dark,
              ),
            ),
            SizedBox(height: 4.h),

            // Offer summary
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.05)
                    : AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  // Operator badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: _operatorColor(
                        offer.operator,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      offer.operatorName,
                      style: getBoldTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _operatorColor(offer.operator),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Description
                  Expanded(
                    child: Text(
                      offer.shortDescription,
                      style: getBoldTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.7)
                            : AppColors.dark,
                      ),
                    ),
                  ),
                  // Price
                  Text(
                    offer.formattedAmount,
                    style: getBoldTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Phone number input
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: getBoldTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.dark,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.enterNumber,
                hintStyle: getTextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.3)
                      : AppColors.darkGrey,
                ),
                counterText: '',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+88',
                        style: getBoldTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.white.withValues(alpha: 0.54)
                              : AppColors.darkerGrey,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 1,
                        height: 20.h,
                        color: isDark
                            ? AppColors.white.withValues(alpha: 0.12)
                            : AppColors.grey,
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 70.w),
                filled: true,
                fillColor: isDark ? AppColors.dark : AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Cashback info
            if (offer.commissionAmount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.money_recive,
                      size: 14.sp,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${AppStrings.cashback}: ${offer.formattedCashback}',
                      style: getBoldTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16.h),

            // Buy button
            Obx(() {
              final processing = controller.isProcessing.value;
              return SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: processing
                      ? null
                      : () {
                          controller.purchaseDriveOffer(
                            phone: phoneCtrl.text,
                            offer: offer,
                          );
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: processing
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.flash_1,
                              color: AppColors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${AppStrings.buyNow} • ${offer.formattedAmount}',
                              style: getBoldTextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Color _operatorColor(String op) {
    switch (op) {
      case 'GP':
        return const Color(0xFF1C6B20);
      case 'BL':
        return const Color(0xFFE87C03);
      case 'RB':
        return const Color(0xFFD41A29);
      case 'AR':
        return const Color(0xFFE11C1C);
      case 'TL':
        return const Color(0xFF0051A2);
      default:
        return AppColors.darkGrey;
    }
  }
}
