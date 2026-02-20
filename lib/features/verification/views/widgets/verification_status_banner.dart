import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/verification/controllers/verification_controller.dart';

/// Verification Status Banner
/// Shows current verification and subscription status
class VerificationStatusBanner extends StatelessWidget {
  const VerificationStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VerificationController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isVerified = controller.isVerified;
      final isSubscribed = controller.isSubscribed;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isVerified
                ? [
                    AppColors.success.withValues(alpha: 0.15),
                    AppColors.success.withValues(alpha: 0.05),
                  ]
                : [
                    AppColors.warning.withValues(alpha: 0.15),
                    AppColors.warning.withValues(alpha: 0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isVerified
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon + Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isVerified ? Iconsax.verify5 : Iconsax.shield_cross,
                    color: isVerified ? AppColors.success : AppColors.warning,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified
                            ? AppStrings.verified
                            : AppStrings.notVerified,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isVerified
                            ? AppStrings.verificationComplete
                            : AppStrings.verificationIncomplete,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Subscription badge if verified
            if (isVerified) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSubscribed
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSubscribed ? Iconsax.crown1 : Iconsax.crown,
                      size: 16.w,
                      color: isSubscribed
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isSubscribed
                          ? AppStrings.subscribed
                          : AppStrings.verificationNotSubscribed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSubscribed
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
