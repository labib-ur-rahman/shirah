import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/mobile_recharge/controllers/mobile_recharge_controller.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/amount_selector.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/operator_selector.dart';
import 'package:shirah/features/mobile_recharge/views/widgets/recharge_history_card.dart';

/// Mobile Recharge Screen - Enterprise-level recharge interface
/// Allows users to recharge any Bangladesh mobile number
/// Features: Auto operator detection, quick amounts, recharge history
class MobileRechargeScreen extends StatelessWidget {
  const MobileRechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = Get.find<MobileRechargeController>();

    // Load history on screen open
    if (controller.rechargeHistory.isEmpty) {
      controller.fetchRechargeHistory();
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              /// -- Operator Selector
              _buildSectionLabel(AppStrings.selectOperator, isDark),
              SizedBox(height: 10.h),
              const OperatorSelector(),
              SizedBox(height: 20.h),

              /// -- Number Type Toggle
              _buildNumberTypeToggle(controller, isDark),
              SizedBox(height: 16.h),

              /// -- Phone Number Input
              _buildPhoneInput(controller, isDark),
              SizedBox(height: 20.h),

              /// -- Amount Input
              _buildAmountInput(controller, isDark),
              SizedBox(height: 16.h),

              /// -- Quick Amounts
              const AmountSelector(),
              SizedBox(height: 24.h),

              /// -- Recharge Button
              _buildRechargeButton(controller, isDark),
              SizedBox(height: 28.h),

              /// -- Recharge History
              _buildHistorySection(controller, isDark),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(
        AppStrings.mobileRecharge,
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

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
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
            label: 'Prepaid',
            isSelected: selected == '1',
            isDark: isDark,
            onTap: () => controller.selectNumberType('1'),
          ),
          SizedBox(width: 10.w),
          _buildTypeChip(
            label: 'Postpaid',
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
              ? const Color(0xFF4B68FF)
              : isDark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4B68FF)
                : isDark
                ? Colors.white12
                : Colors.grey.shade300,
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

  Widget _buildPhoneInput(MobileRechargeController controller, bool isDark) {
    return Obx(() {
      // Just to trigger rebuild on operator change
      controller.selectedOperator.value;
      return TextField(
        controller: controller.phoneController,
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
          suffixIcon: controller.phoneController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Iconsax.close_circle,
                    size: 20.sp,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  onPressed: () => controller.phoneController.clear(),
                )
              : null,
          errorText: controller.phoneError,
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
            borderSide: const BorderSide(color: Color(0xFF4B68FF), width: 1.5),
          ),
        ),
      );
    });
  }

  Widget _buildAmountInput(MobileRechargeController controller, bool isDark) {
    return TextField(
      controller: controller.amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.customAmount,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.all(12.w),
          child: Text(
            '৳',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4B68FF),
            ),
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 44.w),
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
          borderSide: const BorderSide(color: Color(0xFF4B68FF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRechargeButton(
    MobileRechargeController controller,
    bool isDark,
  ) {
    return Obx(() {
      final processing = controller.isProcessing.value;
      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: processing ? null : () => controller.initiateRecharge(),
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
                    Icon(Iconsax.flash_1, color: Colors.white, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      AppStrings.rechargeNow,
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
            _buildSectionLabel('Recent History', isDark),
            SizedBox(height: 10.h),
            ...List.generate(
              3,
              (i) => Container(
                height: 72.h,
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E2E)
                      : Colors.grey.shade100,
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
          _buildSectionLabel('Recent History', isDark),
          SizedBox(height: 10.h),
          ...history
              .take(5)
              .map((r) => RechargeHistoryCard(recharge: r))
              .toList(),
        ],
      );
    });
  }
}
