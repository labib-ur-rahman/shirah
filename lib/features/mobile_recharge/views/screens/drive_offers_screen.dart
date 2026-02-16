import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
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
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = Get.find<MobileRechargeController>();

    // Load offers on screen open
    if (controller.driveOffers.isEmpty) {
      controller.fetchDriveOffers();
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(isDark),
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
                color: const Color(0xFF4B68FF),
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

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(
        AppStrings.telecomOffers,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : Colors.black87,
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
              label: 'All',
              isSelected: selected.isEmpty,
              isDark: isDark,
              onTap: () => controller.filterOffersByOperator(''),
            ),
            SizedBox(width: 8.w),
            ...MobileRechargeController.operators.map((op) {
              // Map numeric code to letter code for API
              const codeToLetter = {
                '1': 'GP',
                '4': 'BL',
                '2': 'RB',
                '3': 'AR',
                '5': 'TL',
              };
              final letterCode = codeToLetter[op['code']!] ?? '';
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
    final chipColor = color ?? const Color(0xFF4B68FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? chipColor
                : isDark
                ? Colors.white12
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                ? Colors.white54
                : Colors.grey.shade700,
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
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No offers available',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Try changing the filter or check back later',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
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
    final phoneController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            Text(
              AppStrings.buyNow,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),

            // Offer summary
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF3F5FF),
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
                      style: TextStyle(
                        fontSize: 11.sp,
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
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  // Price
                  Text(
                    offer.formattedAmount,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4B68FF),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Phone number input
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.enterNumber,
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
                counterText: '',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Text(
                    '+88',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 50.w),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(
                    color: Color(0xFF4B68FF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Cashback info
            if (offer.commissionAmount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.money_recive,
                      size: 14.sp,
                      color: const Color(0xFF16A34A),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'You\'ll earn ${offer.formattedCashback} cashback',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
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
                            phone: phoneController.text,
                            offer: offer,
                          );
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B68FF),
                    disabledBackgroundColor: const Color(
                      0xFF4B68FF,
                    ).withValues(alpha: 0.5),
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
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.flash_1,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${AppStrings.buyNow} • ${offer.formattedAmount}',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
        return Colors.grey;
    }
  }
}
