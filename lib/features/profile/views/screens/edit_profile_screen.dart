import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/common/widgets/popups/custom_snackbar.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(builder: (_) => _EditProfileView());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stateful inner view (manages text controllers + form key without setState)
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileView extends StatefulWidget {
  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final controller = UserController.instance;
    _firstNameCtrl = TextEditingController(text: controller.firstName);
    _lastNameCtrl = TextEditingController(text: controller.lastName);
    _phoneCtrl = TextEditingController(text: controller.phone);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = UserController.instance;
    final ok = await controller.updateProfileName(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
    );

    if (ok) {
      AppSnackBar.successSnackBar(title: AppStrings.editProfileSuccess);
      Get.back();
    } else {
      AppSnackBar.errorSnackBar(title: AppStrings.editProfileFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppStyleColors.instance;
    final controller = UserController.instance;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: _EditProfileAppBar(appColors: appColors),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar preview ─────────────────────────────────
              Center(
                child: _AvatarPreview(
                  avatarUrl: controller.avatarUrl,
                  appColors: appColors,
                ),
              ),

              SizedBox(height: 36.h),

              // ── First Name ────────────────────────────────────
              _SectionLabel(
                label: AppStrings.editFirstName,
                appColors: appColors,
              ),
              SizedBox(height: 8.h),
              _AppTextField(
                controller: _firstNameCtrl,
                hintText: AppStrings.editFirstName,
                prefixIcon: Iconsax.user,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.editNameRequired
                    : null,
                appColors: appColors,
              ),

              SizedBox(height: 20.h),

              // ── Last Name ─────────────────────────────────────
              _SectionLabel(
                label: AppStrings.editLastName,
                appColors: appColors,
              ),
              SizedBox(height: 8.h),
              _AppTextField(
                controller: _lastNameCtrl,
                hintText: AppStrings.editLastName,
                prefixIcon: Iconsax.user,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.editNameRequired
                    : null,
                appColors: appColors,
              ),

              SizedBox(height: 20.h),

              // ── Phone (Read-only) ─────────────────────────────
              _SectionLabel(label: AppStrings.editPhone, appColors: appColors),
              SizedBox(height: 8.h),
              _AppTextField(
                controller: _phoneCtrl,
                hintText: AppStrings.editPhoneHint,
                prefixIcon: Iconsax.call,
                readOnly: true,
                appColors: appColors,
              ),

              SizedBox(height: 40.h),

              // ── Save Button ───────────────────────────────────
              Obx(
                () => _SaveButton(
                  onTap: _onSave,
                  isLoading: controller.isUpdating.value,
                  appColors: appColors,
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _EditProfileAppBar({required this.appColors});
  final AppStyleColors appColors;

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Iconsax.arrow_left,
            size: 20.w,
            color: appColors.textPrimary,
          ),
        ),
      ),
      title: Text(
        AppStrings.editProfileTitle,
        style: getBoldTextStyle(fontSize: 17, color: appColors.textPrimary),
      ),
      centerTitle: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Preview
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.avatarUrl, required this.appColors});

  final String avatarUrl;
  final AppStyleColors appColors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96.w,
          height: 96.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: appColors.primary.withValues(alpha: 0.3),
              width: 3.w,
            ),
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _PlaceholderAvatar(appColors: appColors),
                  )
                : _PlaceholderAvatar(appColors: appColors),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appColors.primary,
              border: Border.all(color: appColors.background, width: 2.w),
            ),
            child: Icon(Iconsax.camera, size: 14.w, color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.appColors});
  final AppStyleColors appColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appColors.surface,
      child: Icon(Iconsax.user, size: 40.w, color: appColors.textSecondary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.appColors});
  final String label;
  final AppStyleColors appColors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: getBoldTextStyle(fontSize: 13, color: appColors.textSecondary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text Field
// ─────────────────────────────────────────────────────────────────────────────

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.appColors,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final AppStyleColors appColors;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      validator: validator,
      style: getTextStyle(fontSize: 15, color: appColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: getTextStyle(fontSize: 14, color: appColors.textSecondary),
        filled: true,
        fillColor: readOnly
            ? appColors.surface.withValues(alpha: 0.6)
            : appColors.surface,
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(
            prefixIcon,
            size: 20.w,
            color: readOnly ? appColors.textSecondary : appColors.primary,
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 52.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: appColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: appColors.border, width: 1.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: appColors.primary, width: 1.6.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: appColors.error, width: 1.5.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: appColors.error, width: 1.6.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save Button
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onTap,
    required this.isLoading,
    required this.appColors,
  });

  final VoidCallback onTap;
  final bool isLoading;
  final AppStyleColors appColors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          disabledBackgroundColor: appColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation(AppColors.white),
                ),
              )
            : Text(
                AppStrings.editSaveChanges,
                style: getBoldTextStyle(fontSize: 15, color: AppColors.white),
              ),
      ),
    );
  }
}
