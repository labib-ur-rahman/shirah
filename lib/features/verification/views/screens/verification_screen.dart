import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/verification/controllers/verification_controller.dart';
import 'package:shirah/features/verification/views/widgets/payment_history_list.dart';
import 'package:shirah/features/verification/views/widgets/subscription_plan_card.dart';
import 'package:shirah/features/verification/views/widgets/verification_benefits_list.dart';
import 'package:shirah/features/verification/views/widgets/verification_plan_card.dart';
import 'package:shirah/features/verification/views/widgets/verification_status_banner.dart';

/// Verification Screen - Premium Account Verification & Subscription
/// Framed as "Premium Account" for Google Play compliance
/// Users can purchase verification (one-time) and subscription (recurring)
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = VerificationController.instance;
    final appStyleColors = AppStyleColors.instance;

    // Load history on screen open
    if (controller.paymentHistory.isEmpty) {
      controller.loadPaymentHistory();
    }

    return Scaffold(
      backgroundColor: appStyleColors.background,
      appBar: _buildAppBar(isDark, appStyleColors),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadPaymentConfig();
          await controller.loadPaymentHistory(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One-time lifetime info banner
              _buildInfoBanner(context),
              SizedBox(height: 16.h),

              // Status Banner
              const VerificationStatusBanner(),
              SizedBox(height: 20.h),

              // Verification Plan Card
              const VerificationPlanCard(),
              SizedBox(height: 16.h),

              // Subscription Plan Card
              const SubscriptionPlanCard(),
              SizedBox(height: 24.h),

              // Benefits Section
              const VerificationBenefitsList(),
              SizedBox(height: 24.h),

              // Payment History Section
              Text(
                AppStrings.verificationPaymentHistory,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12.h),
              const PaymentHistoryList(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppStyleColors appStyleColors) {
    return AppBar(
      backgroundColor: appStyleColors.background,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      title: Text(
        AppStrings.verificationScreenTitle,
        style: TextStyle(
          color: isDark ? AppColors.white : AppColors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.unlimited, size: 18.w, color: AppColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              AppStrings.verificationLifetimeNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.85)
                    : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
