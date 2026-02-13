import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/features/micro_jobs/controllers/create_micro_job_controller.dart';
import 'package:shirah/routes/app_routes.dart';

/// Create Micro Job Screen - Modern enterprise-level job post creation
/// Features: Title, details, cover image, job link, limit, price, auto-calculation
class CreateMicroJobScreen extends StatelessWidget {
  const CreateMicroJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = colors.isDarkMode;
    final controller = Get.put(CreateMicroJobController());

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F1A)
          : const Color(0xFFF8F9FB),
      appBar: _buildAppBar(controller, isDark, colors),
      body: Form(
        key: controller.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    /// -- Section: Title
                    _buildSectionLabel('Job Title *', isDark),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.titleController,
                      hint: 'e.g., Facebook Page Like + Comment',
                      isDark: isDark,
                      maxLength: 200,
                      validator: (v) {
                        if (v == null || v.trim().length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    /// -- Section: Details
                    _buildSectionLabel('Job Instructions *', isDark),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.detailsController,
                      hint:
                          'Step-by-step instructions for workers.\n\n1. Open the link\n2. Like the page\n3. Comment "Nice"\n4. Take a screenshot',
                      isDark: isDark,
                      maxLines: 8,
                      minLines: 5,
                      keyboardType: TextInputType.multiline,
                      maxLength: 5000,
                      validator: (v) {
                        if (v == null || v.trim().length < 20) {
                          return 'Instructions must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    /// -- Section: Cover Image
                    _buildSectionLabel('Cover Image *', isDark),
                    SizedBox(height: 8.h),
                    _buildCoverImagePicker(controller, isDark),
                    SizedBox(height: 20.h),

                    /// -- Section: Job Link
                    _buildSectionLabel('Task Link *', isDark),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.jobLinkController,
                      hint: 'https://facebook.com/your-page',
                      isDark: isDark,
                      prefixIcon: Iconsax.link_21,
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Task link is required';
                        }
                        if (!v.startsWith('http://') &&
                            !v.startsWith('https://')) {
                          return 'Link must start with http:// or https://';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    /// -- Section: Limit & Price
                    _buildSectionLabel('Pricing & Limit *', isDark),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: controller.perUserPriceController,
                            hint: '৳ Per user',
                            isDark: isDark,
                            prefixIcon: Iconsax.money,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v);
                              if (n == null || n < 0.5 || n > 1000) {
                                return '৳0.5–৳1,000';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),

                        Expanded(
                          child: _buildTextField(
                            controller: controller.limitController,
                            hint: 'Workers',
                            isDark: isDark,
                            prefixIcon: Iconsax.people,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              final n = int.tryParse(v);
                              if (n == null || n < 1 || n > 10000) {
                                return '1–10,000';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    /// -- Price Summary Card
                    _buildPriceSummary(controller, isDark, colors),
                    SizedBox(height: 16.h),

                    /// -- Wallet Balance Info (Reactive)
                    Obx(() => _buildWalletInfo(controller, isDark)),
                    SizedBox(height: 16.h),

                    /// -- Verification Warning (Reactive)
                    Obx(() {
                      if (!controller.isUserVerified) {
                        return _buildVerificationWarning(isDark);
                      }
                      return const SizedBox.shrink();
                    }),

                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            /// -- Bottom Submit Button
            _buildSubmitButton(controller, isDark, colors),
          ],
        ),
      ),
    );
  }

  // ==================== AppBar ====================

  PreferredSizeWidget _buildAppBar(
    CreateMicroJobController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      title: Text(
        'Create Micro Job',
        style: getBoldTextStyle(
          fontSize: 20,
          color: isDark ? Colors.white : const Color(0xFF1E2939),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {
            Get.toNamed(AppRoutes.MY_CREATED_JOBS);
          },
          icon: Icon(
            Iconsax.document_text,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6),
        ),
      ),
    );
  }

  // ==================== Section Label ====================

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: getBoldTextStyle(
        fontSize: 14,
        color: isDark ? Colors.white70 : const Color(0xFF374151),
      ),
    );
  }

  // ==================== Text Field ====================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int minLines = 1,
    int? maxLength,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: getTextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF1E2939),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: getTextStyle(
          fontSize: 15,
          color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 20.sp,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        counterStyle: getTextStyle(
          fontSize: 11,
          color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // ==================== Cover Image Picker ====================

  Widget _buildCoverImagePicker(
    CreateMicroJobController controller,
    bool isDark,
  ) {
    return Obx(() {
      final image = controller.coverImage.value;

      if (image != null) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.file(
                image,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10.h,
              right: 10.w,
              child: GestureDetector(
                onTap: controller.removeCoverImage,
                child: Container(
                  width: 34.w,
                  height: 34.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.close_circle,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return GestureDetector(
        onTap: controller.pickCoverImage,
        child: Container(
          width: double.infinity,
          height: 160.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.image,
                  size: 28.sp,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Tap to add cover image',
                style: getBoldTextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Required • Max 1920x1920',
                style: getTextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white30 : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ==================== Price Summary Card ====================

  Widget _buildPriceSummary(
    CreateMicroJobController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Obx(() {
      final base = controller.basePrice.value;
      final fee = controller.serviceFee.value;
      final total = controller.totalPrice.value;

      if (total <= 0) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E2E), const Color(0xFF2A1F3D)]
                : [const Color(0xFFFAF5FF), const Color(0xFFF5F3FF)],
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            _buildPriceRow('Base Price', '৳${base.toStringAsFixed(0)}', isDark),
            SizedBox(height: 8.h),
            _buildPriceRow(
              'Service Fee (10%)',
              '৳${fee.toStringAsFixed(0)}',
              isDark,
              isHighlight: true,
            ),
            SizedBox(height: 8.h),
            Container(
              height: 1.h,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB),
            ),
            SizedBox(height: 8.h),
            _buildPriceRow(
              'Total Deduction',
              '৳${total.toStringAsFixed(0)}',
              isDark,
              isBold: true,
              valueColor: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getTextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isHighlight
                ? const Color(0xFFF59E0B)
                : isDark
                ? Colors.white60
                : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: getBoldTextStyle(
            fontSize: isBold ? 18 : 14,
            color:
                valueColor ?? (isDark ? Colors.white : const Color(0xFF1E2939)),
          ),
        ),
      ],
    );
  }

  // ==================== Wallet Info ====================

  Widget _buildWalletInfo(CreateMicroJobController controller, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFDCFCE7),
        ),
      ),
      child: Row(
        children: [
          Icon(Iconsax.wallet_2, size: 20.sp, color: const Color(0xFF10B981)),
          SizedBox(width: 10.w),
          Text(
            'Wallet Balance:',
            style: getTextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            '৳${controller.userBalance.toStringAsFixed(0)}',
            style: getBoldTextStyle(
              fontSize: 15,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Verification Warning ====================

  Widget _buildVerificationWarning(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1F1F) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, size: 22.sp, color: const Color(0xFFEF4444)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Profile verification required to create micro jobs.',
              style: getTextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Submit Button ====================

  Widget _buildSubmitButton(
    CreateMicroJobController controller,
    bool isDark,
    AppStyleColors colors,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final submitting = controller.isSubmitting.value;
        return SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: submitting ? null : () => controller.submitJob(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFE5E7EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: submitting
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: submitting
                    ? (isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFE5E7EB))
                    : null,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Container(
                alignment: Alignment.center,
                child: submitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.send_1,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'Create Job Post',
                            style: getBoldTextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
