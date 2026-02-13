import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/modules/admins/home_feed/controllers/admin_feed_controller.dart';

/// Create Native Ad Screen - Admin form for creating native ad feed items
///
/// Form Fields:
///   - Ad Unit ID (required)
///   - Platform (required: android / ios / both)
///   - Min Gap (optional, default 6)
///   - Max Per Session (optional, default 3)
///
/// Calls Cloud Function: createNativeAdFeed
class CreateNativeAdScreen extends StatefulWidget {
  const CreateNativeAdScreen({super.key});

  @override
  State<CreateNativeAdScreen> createState() => _CreateNativeAdScreenState();
}

class _CreateNativeAdScreenState extends State<CreateNativeAdScreen> {
  final AdminFeedController _controller = AdminFeedController.instance;
  final _formKey = GlobalKey<FormState>();

  final _adUnitIdController = TextEditingController();
  final _minGapController = TextEditingController(text: '6');
  final _maxPerSessionController = TextEditingController(text: '3');

  String _selectedPlatform = 'both';

  final List<_PlatformOption> _platforms = [
    _PlatformOption(
      value: 'android',
      icon: Icons.android,
      color: const Color(0xFF3DDC84),
    ),
    _PlatformOption(
      value: 'ios',
      icon: Icons.apple,
      color: const Color(0xFF007AFF),
    ),
    _PlatformOption(
      value: 'both',
      icon: Iconsax.mobile,
      color: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _adUnitIdController.dispose();
    _minGapController.dispose();
    _maxPerSessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.light,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(isDark),
              SizedBox(height: 24.h),

              // Ad Unit ID
              _buildSectionLabel(
                AppStrings.adminNativeAdUnitId,
                isDark,
                required: true,
              ),
              SizedBox(height: 8.h),
              _buildAdUnitIdField(isDark),
              SizedBox(height: 20.h),

              // Platform Selection
              _buildSectionLabel(
                AppStrings.adminNativeAdPlatform,
                isDark,
                required: true,
              ),
              SizedBox(height: 8.h),
              _buildPlatformSelector(isDark),
              SizedBox(height: 24.h),

              // Display Rules Section
              _buildRulesSection(isDark),
              SizedBox(height: 32.h),

              // Submit Button
              _buildSubmitButton(isDark),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== App Bar ====================

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? AppColors.dark : AppColors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.adminNativeAdCreate,
            style: getBoldTextStyle(
              fontSize: 18,
              color: isDark ? AppColors.white : AppColors.dark,
            ),
          ),
          Text(
            AppStrings.adminNativeAdCreateSubtitle,
            style: getTextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Header Card ====================

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.warning.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.chart, size: 24, color: AppColors.warning),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.adminNativeAdTitle,
                  style: getBoldTextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.dark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.adminNativeAdSubtitle,
                  style: getTextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Form Fields ====================

  Widget _buildSectionLabel(String text, bool isDark, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: getBoldTextStyle(
            fontSize: 13,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: getBoldTextStyle(fontSize: 13, color: AppColors.error),
          ),
      ],
    );
  }

  Widget _buildAdUnitIdField(bool isDark) {
    return TextFormField(
      controller: _adUnitIdController,
      style: getTextStyle(
        fontSize: 14,
        color: isDark ? AppColors.white : AppColors.dark,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.adminNativeAdUnitIdHint,
        hintStyle: getTextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          Iconsax.code,
          size: 18,
          color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ad Unit ID is required';
        }
        if (!value.contains('/')) {
          return 'Please enter a valid AdMob ad unit ID';
        }
        return null;
      },
    );
  }

  Widget _buildPlatformSelector(bool isDark) {
    return Row(
      children: _platforms.map((platform) {
        final isSelected = _selectedPlatform == platform.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: platform.value != 'both' ? 8.w : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedPlatform = platform.value),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? platform.color.withValues(alpha: 0.12)
                      : isDark
                      ? AppColors.white.withValues(alpha: 0.05)
                      : AppColors.softGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? platform.color
                        : isDark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.grey.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      platform.icon,
                      size: 22,
                      color: isSelected
                          ? platform.color
                          : isDark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _getPlatformLabel(platform.value),
                      style: getTextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? platform.color
                            : isDark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== Rules Section ====================

  Widget _buildRulesSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.03)
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.setting_2, size: 18, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                AppStrings.adminNativeAdRules,
                style: getBoldTextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.dark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Min Gap
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.adminNativeAdMinGap,
                      style: getTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    _buildNumberField(
                      controller: _minGapController,
                      hint: AppStrings.adminNativeAdMinGapHint,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),

              // Max Per Session
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.adminNativeAdMaxPerSession,
                      style: getTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    _buildNumberField(
                      controller: _maxPerSessionController,
                      hint: AppStrings.adminNativeAdMaxPerSessionHint,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: getTextStyle(
        fontSize: 14,
        color: isDark ? AppColors.white : AppColors.dark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: getTextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.white.withValues(alpha: 0.05)
            : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        isDense: true,
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final num = int.tryParse(value);
          if (num == null || num < 1) {
            return 'Must be ≥ 1';
          }
        }
        return null;
      },
    );
  }

  // ==================== Submit ====================

  Widget _buildSubmitButton(bool isDark) {
    return Obx(() {
      final isLoading = _controller.isActionLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.add_circle, size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      AppStrings.adminNativeAdCreate,
                      style: getBoldTextStyle(
                        fontSize: 15,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final adUnitId = _adUnitIdController.text.trim();
    final platform = _selectedPlatform;
    final minGap = int.tryParse(_minGapController.text.trim());
    final maxPerSession = int.tryParse(_maxPerSessionController.text.trim());

    final success = await _controller.createNativeAd(
      adUnitId: adUnitId,
      platform: platform,
      minGap: minGap,
      maxPerSession: maxPerSession,
    );

    if (success) {
      Get.back();
      Get.snackbar(
        AppStrings.adminNativeAdCreated,
        'Ad Unit: $adUnitId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        AppStrings.error,
        'Failed to create native ad. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: AppColors.white,
      );
    }
  }

  // ==================== Helpers ====================

  String _getPlatformLabel(String value) {
    switch (value) {
      case 'android':
        return AppStrings.adminNativeAdAndroid;
      case 'ios':
        return AppStrings.adminNativeAdIos;
      case 'both':
        return AppStrings.adminNativeAdBoth;
      default:
        return value;
    }
  }
}

class _PlatformOption {
  final String value;
  final IconData icon;
  final Color color;

  const _PlatformOption({
    required this.value,
    required this.icon,
    required this.color,
  });
}
