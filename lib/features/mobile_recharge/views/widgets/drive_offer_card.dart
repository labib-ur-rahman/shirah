import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
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
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row - Operator + Offer Type + Price
          Row(
            children: [
              // Operator badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _operatorColor(offer.operator).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  offer.operatorName,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _operatorColor(offer.operator),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Offer type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _offerTypeColor(
                    offer.offerType,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  offer.offerTypeName,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _offerTypeColor(offer.offerType),
                  ),
                ),
              ),
              const Spacer(),
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
          SizedBox(height: 10.h),

          // Offer details grid
          _buildOfferDetailsRow(isDark),
          SizedBox(height: 8.h),

          // Bottom row - Validity + Cashback + Buy button
          Row(
            children: [
              // Validity
              Icon(
                Iconsax.calendar_1,
                size: 13.sp,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              SizedBox(width: 4.w),
              Text(
                offer.validity,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 12.w),
              // Cashback
              if (offer.commissionAmount > 0) ...[
                Icon(
                  Iconsax.money_recive,
                  size: 13.sp,
                  color: const Color(0xFF16A34A),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Cashback ${offer.formattedCashback}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
              const Spacer(),
              // Buy button
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B68FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'Buy',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildOfferDetailsRow(bool isDark) {
    final items = <Widget>[];

    if (offer.hasInternet) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.global,
          label: offer.internetPack,
          color: const Color(0xFF2563EB),
          isDark: isDark,
        ),
      );
    }
    if (offer.hasMinutes) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.call,
          label: '${offer.minutePack} Min',
          color: const Color(0xFF16A34A),
          isDark: isDark,
        ),
      );
    }
    if (offer.hasSms) {
      items.add(
        _buildDetailChip(
          icon: Iconsax.sms,
          label: '${offer.smsPack} SMS',
          color: const Color(0xFFF59E0B),
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
            style: TextStyle(
              fontSize: 11.sp,
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
        return Colors.grey;
    }
  }

  Color _offerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'internet':
        return const Color(0xFF2563EB);
      case 'minute':
        return const Color(0xFF16A34A);
      case 'combo':
        return const Color(0xFF9333EA);
      case 'bundle':
        return const Color(0xFFE87C03);
      case 'sms':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }
}
