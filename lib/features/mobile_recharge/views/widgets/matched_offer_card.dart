import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/recharge/drive_offer_model.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';

/// Matched Offer Card - Shows when user enters an amount matching a drive offer
/// Displayed below the amount input on the recharge screen
class MatchedOfferCard extends StatelessWidget {
  const MatchedOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = MobileRechargeController.instance;

    return Obx(() {
      final isSearching = controller.isSearchingOffers.value;
      final offers = controller.matchedOffers;
      final useOffer = controller.useOfferPack.value;

      /// -- Searching indicator (hidden)
      if (isSearching) return const SizedBox.shrink();

      /// -- No offers found
      if (offers.isEmpty) return const SizedBox.shrink();

      final offer = offers.first;
      final amount = double.tryParse(controller.amountController.text) ?? 0;
      final isNonRound = amount % 10 != 0;

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -- Header
            Row(
              children: [
                Icon(Iconsax.flash_1, size: 16.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.hotOffers,
                  style: getBoldTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                _buildBadge(
                  label: offer.operatorName,
                  color: _operatorColor(offer.operator),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            /// -- Offer details
            _buildOfferInfo(offer, isDark),
            SizedBox(height: 10.h),

            /// -- Validity & cashback
            Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 12.sp,
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.38)
                      : AppColors.darkGrey,
                ),
                SizedBox(width: 4.w),
                Text(
                  offer.validity,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.54)
                        : AppColors.darkerGrey,
                  ),
                ),
                if (offer.commissionAmount > 0) ...[
                  SizedBox(width: 12.w),
                  Icon(
                    Iconsax.money_recive,
                    size: 12.sp,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${AppStrings.cashback} ${offer.formattedCashback}',
                    style: getBoldTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),

            /// -- Action: Use Offer Pack toggle
            if (!isNonRound)
              GestureDetector(
                onTap: () => controller.toggleOfferPack(!useOffer),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: useOffer
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : isDark
                        ? AppColors.white.withValues(alpha: 0.04)
                        : AppColors.softGrey,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: useOffer
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : isDark
                          ? AppColors.white.withValues(alpha: 0.08)
                          : AppColors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        useOffer ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                        size: 18.sp,
                        color: useOffer
                            ? AppColors.primary
                            : isDark
                            ? AppColors.white.withValues(alpha: 0.38)
                            : AppColors.darkGrey,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppStrings.driveOffers,
                        style: getBoldTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: useOffer
                              ? AppColors.primary
                              : isDark
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              /// -- Non-round amount: forced to use offer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.flash_15,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        AppStrings.driveOffers,
                        style: getBoldTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            /// -- Show more offers if available
            if (offers.length > 1) ...[
              SizedBox(height: 8.h),
              Text(
                '+${offers.length - 1} ${AppStrings.offers}',
                style: getTextStyle(fontSize: 11, color: AppColors.primary),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildOfferInfo(DriveOfferModel offer, bool isDark) {
    final items = <Widget>[];

    if (offer.hasInternet) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.global,
          label: offer.internetPack,
          color: AppColors.info,
        ),
      );
    }
    if (offer.hasMinutes) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.call,
          label: '${offer.minutePack} Min',
          color: AppColors.success,
        ),
      );
    }
    if (offer.hasSms) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.sms,
          label: '${offer.smsPack} SMS',
          color: AppColors.warning,
        ),
      );
    }
    if (offer.hasCallRate) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.call_calling,
          label: offer.callratePack,
          color: const Color(0xFF9333EA),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8.w, runSpacing: 6.h, children: items);
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: getBoldTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: getBoldTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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

class _OfferSearchShimmer extends StatefulWidget {
  const _OfferSearchShimmer();

  @override
  State<_OfferSearchShimmer> createState() => _OfferSearchShimmerState();
}

class _OfferSearchShimmerState extends State<_OfferSearchShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = isDark
            ? Color.lerp(
                AppColors.dark,
                AppColors.darkerGrey,
                _animation.value,
              )!
            : Color.lerp(AppColors.softGrey, AppColors.grey, _animation.value)!;

        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 48.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 70.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 80.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 90.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
