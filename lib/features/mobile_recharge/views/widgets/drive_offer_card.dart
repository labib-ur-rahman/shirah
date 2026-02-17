import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/data/models/recharge/drive_offer_model.dart';

/// Drive offer card widget - Shows offer details in a compact card
class DriveOfferCard extends StatelessWidget {
  final DriveOfferModel offer;
  final VoidCallback onBuy;

  const DriveOfferCard({super.key, required this.offer, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppStyleColors.instance.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.grey.withValues(alpha: 0.5),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// -- Top row: Operator + Offer Type + Price
          Row(
            children: [
              _buildBadge(
                label: offer.operatorName,
                color: _operatorColor(offer.operator),
                isDark: isDark,
              ),
              SizedBox(width: 8.w),
              _buildBadge(
                label: offer.offerTypeName,
                color: _offerTypeColor(offer.offerType),
                isDark: isDark,
              ),
              const Spacer(),
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
          SizedBox(height: 10.h),

          /// -- Offer details chips
          _buildOfferDetailsRow(isDark),
          SizedBox(height: 10.h),

          /// -- Bottom row: Validity + Cashback + Buy button
          Row(
            children: [
              Icon(
                Iconsax.calendar_1,
                size: 13.sp,
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
              SizedBox(width: 12.w),
              if (offer.commissionAmount > 0) ...[
                Icon(
                  Iconsax.money_recive,
                  size: 13.sp,
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
              const Spacer(),
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    AppStrings.buyNow,
                    style: getBoldTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required bool isDark,
  }) {
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

  Widget _buildOfferDetailsRow(bool isDark) {
    final items = <Widget>[];

    if (offer.hasInternet) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.global,
          label: offer.internetPack,
          color: AppColors.info,
          isDark: isDark,
        ),
      );
    }
    if (offer.hasMinutes) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.call,
          label: offer.minutePack,
          color: AppColors.success,
          isDark: isDark,
        ),
      );
    }
    if (offer.hasSms) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.sms,
          label: offer.smsPack,
          color: AppColors.warning,
          isDark: isDark,
        ),
      );
    }
    if (offer.hasCallRate) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.call_calling,
          label: offer.callratePack,
          color: const Color(0xFF9333EA),
          isDark: isDark,
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
    required bool isDark,
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

  Color _offerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'internet':
        return AppColors.info;
      case 'minute':
        return AppColors.success;
      case 'combo':
        return const Color(0xFF9333EA);
      case 'bundle':
        return AppColors.warning;
      case 'sms':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.darkGrey;
    }
  }
}
