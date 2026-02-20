import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';

/// Verification Benefits List
/// Shows the benefits users get from verification and subscription
class VerificationBenefitsList extends StatelessWidget {
  const VerificationBenefitsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.verificationBenefitsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.borderSecondary,
            ),
          ),
          child: Column(
            children: [
              _BenefitItem(
                icon: Iconsax.wallet_3,
                title: AppStrings.verificationBenefit1,
                subtitle: AppStrings.verificationBenefit1Desc,
                isDark: isDark,
              ),
              _divider(isDark),
              _BenefitItem(
                icon: Iconsax.people,
                title: AppStrings.verificationBenefit2,
                subtitle: AppStrings.verificationBenefit2Desc,
                isDark: isDark,
              ),
              _divider(isDark),
              _BenefitItem(
                icon: Iconsax.gift,
                title: AppStrings.verificationBenefit3,
                subtitle: AppStrings.verificationBenefit3Desc,
                isDark: isDark,
              ),
              _divider(isDark),
              _BenefitItem(
                icon: Iconsax.shield_tick,
                title: AppStrings.verificationBenefit4,
                subtitle: AppStrings.verificationBenefit4Desc,
                isDark: isDark,
              ),
              _divider(isDark),
              _BenefitItem(
                icon: Iconsax.star,
                title: AppStrings.verificationBenefit5,
                subtitle: AppStrings.verificationBenefit5Desc,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white12 : AppColors.borderSecondary,
      height: 24.h,
    );
  }
}

/// Single benefit item row
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.white.withValues(alpha: 0.6)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
