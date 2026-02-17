import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/amount_selector.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/matched_offer_card.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/operator_selector.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/recharge_history_card.dart';

/// Mobile Recharge Screen - Enterprise-level recharge interface
/// Allows users to recharge any Bangladesh mobile number
/// Features: Auto operator detection, quick amounts, instant offer detection,
/// recharge history
class MobileRechargeScreen extends StatelessWidget {
  const MobileRechargeScreen({super.key});

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = MobileRechargeController.instance;
    final appStyleColors = AppStyleColors.instance;

    // Load history on screen open
    if (controller.rechargeHistory.isEmpty) {
      controller.fetchRechargeHistory();
    }

    return Scaffold(
      backgroundColor: appStyleColors.background,
      appBar: _buildAppBar(isDark, appStyleColors),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                /// -- Mobile Recharge Section
                _buildSectionHeader(
                  AppStrings.mobileRecharge,
                  Iconsax.flash_1,
                  isDark,
                ),
                SizedBox(height: 10.h),
                _buildSectionCard(
                  appStyleColors: appStyleColors,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(AppStrings.selectOperator, isDark),
                      SizedBox(height: 10.h),
                      const OperatorSelector(),
                      SizedBox(height: 16.h),

                      /// -- Number Type Toggle (Prepaid/Postpaid)
                      _buildNumberTypeToggle(controller, isDark),
                      SizedBox(height: 16.h),

                      /// -- Phone Number Input
                      _buildPhoneInput(controller, isDark),
                      SizedBox(height: 16.h),

                      /// -- Amount + Quick Select Row
                      _buildAmountRow(controller, isDark),
                      SizedBox(height: 12.h),

                      /// -- Instant Offer Detection Card
                      const MatchedOfferCard(),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                /// -- Recharge Button
                _buildRechargeButton(controller, isDark),
                SizedBox(height: 24.h),

                /// -- Recharge History
                _buildHistorySection(controller, isDark),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, AppStyleColors appStyleColors) {
    return AppBar(
      title: Text(
        AppStrings.mobileRecharge,
        style: getBoldTextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
      ),
      centerTitle: true,
      backgroundColor: appStyleColors.background,
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

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: getBoldTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white.withValues(alpha: 0.7) : AppColors.dark,
      ),
    );
  }

  Widget _buildSectionHeader(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.primary),
        ),
        SizedBox(width: 10.w),
        Text(
          text,
          style: getBoldTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required Widget child,
    required AppStyleColors appStyleColors,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: appStyleColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.grey.withValues(alpha: 0.4),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.grey.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildNumberTypeToggle(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return Obx(() {
      final selected = controller.selectedNumberType.value;
      return Row(
        children: [
          _buildTypeChip(
            label: AppStrings.prepaid,
            isSelected: selected == '1',
            isDark: isDark,
            onTap: () => controller.selectNumberType('1'),
          ),
          SizedBox(width: 10.w),
          _buildTypeChip(
            label: AppStrings.postpaid,
            isSelected: selected == '2',
            isDark: isDark,
            onTap: () => controller.selectNumberType('2'),
          ),
        ],
      );
    });
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppStyleColors.instance.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? AppColors.white.withValues(alpha: 0.08)
                : AppColors.grey,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
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
    );
  }

  Widget _buildPhoneInput(MobileRechargeController controller, bool isDark) {
    return Obx(() {
      controller.selectedOperator.value; // trigger rebuild on operator change
      return TextFormField(
        controller: controller.phoneController,
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
          suffixIcon: controller.phoneController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Iconsax.close_circle,
                    size: 20.sp,
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.38)
                        : AppColors.darkGrey,
                  ),
                  onPressed: () => controller.phoneController.clear(),
                )
              : controller.operatorShort.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _operatorColor(
                        controller.operatorShort,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      controller.operatorName,
                      style: getBoldTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _operatorColor(controller.operatorShort),
                      ),
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppStyleColors.instance.primary.withValues(alpha: 0.05),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (_) => controller.phoneError,
      );
    });
  }

  Widget _buildAmountInput(MobileRechargeController controller, bool isDark) {
    return Obx(() {
      controller.selectedAmount.value; // trigger rebuild
      return TextFormField(
        controller: controller.amountController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: getBoldTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.customAmount,
          hintStyle: getTextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.white.withValues(alpha: 0.3)
                : AppColors.darkGrey,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12.w),
            child: Text(
              '৳',
              style: getBoldTextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 44.w),
          filled: true,
          fillColor: AppStyleColors.instance.primary.withValues(alpha: 0.05),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (_) => controller.amountError,
      );
    });
  }

  Widget _buildAmountRow(MobileRechargeController controller, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(AppStrings.enterAmount, isDark),
              SizedBox(height: 8.h),
              _buildAmountInput(controller, isDark),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(flex: 6, child: const AmountSelector()),
      ],
    );
  }

  Widget _buildRechargeButton(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return Obx(() {
      final processing = controller.isProcessing.value;
      final useOffer = controller.useOfferPack.value;
      final hasOffer = controller.matchedOffers.isNotEmpty;
      final showBuy = useOffer && hasOffer;
      final buttonColor = showBuy ? AppColors.success : AppColors.primary;
      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: processing ? null : () => controller.initiateRecharge(),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: buttonColor.withValues(alpha: 0.5),
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
                      showBuy ? Iconsax.shopping_bag : Iconsax.flash_1,
                      color: AppColors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      showBuy ? AppStrings.buyNow : AppStrings.rechargeNow,
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
    });
  }

  Widget _buildHistorySection(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return Obx(() {
      final history = controller.rechargeHistory;
      final isLoading = controller.isLoadingHistory.value;

      if (isLoading && history.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              AppStrings.recentHistory,
              Iconsax.clock,
              isDark,
            ),
            SizedBox(height: 10.h),
            ...List.generate(
              3,
              (i) => Container(
                height: 72.h,
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.dark : AppColors.softGrey,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ],
        );
      }

      if (history.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(AppStrings.recentHistory, Iconsax.clock, isDark),
          SizedBox(height: 10.h),
          ...history.take(5).map((r) => RechargeHistoryCard(recharge: r)),
        ],
      );
    });
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
