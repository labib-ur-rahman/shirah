import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shirah/core/common/styles/global_text_style.dart';
import 'package:shirah/core/localization/app_string_localizations.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/constants/colors.dart';
import 'package:shirah/features/profile/controllers/user_controller.dart';

const int _kBioMaxLength = 150;

/// Call via [BioDialogWidget.show(context)] to open the bio bottom-sheet.
class BioDialogWidget extends StatefulWidget {
  const BioDialogWidget({super.key, required this.initialBio});
  final String initialBio;

  /// Displays a modal bottom-sheet for adding / editing profile bio.
  static void show(BuildContext context) {
    final controller = UserController.instance;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BioDialogWidget(initialBio: controller.userBio),
    );
  }

  @override
  State<BioDialogWidget> createState() => _BioDialogWidgetState();
}

class _BioDialogWidgetState extends State<BioDialogWidget> {
  late final TextEditingController _textController;
  late int _charCount;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialBio);
    _charCount = widget.initialBio.length;
    _textController.addListener(_onTextChanged);

    // Autofocus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    setState(() => _charCount = _textController.text.length);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    await UserController.instance.updateBio(text);
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final appColors = AppStyleColors.instance;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        margin: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: appColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: appColors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: appColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Iconsax.edit_2,
                      size: 20.w,
                      color: appColors.success,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      AppStrings.profileBioDialogTitle,
                      style: getBoldTextStyle(
                        fontSize: 18,
                        color: appColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: appColors.surface,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Iconsax.close_circle,
                        size: 18.w,
                        color: appColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Text Field ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: appColors.border, width: 1.w),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 4,
                  maxLength: _kBioMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: getTextStyle(
                    fontSize: 14,
                    color: appColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.profileBioHint,
                    hintStyle: getTextStyle(
                      fontSize: 14,
                      color: appColors.textSecondary,
                    ),
                    contentPadding: EdgeInsets.all(14.w),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),

            // ── Char counter
            Padding(
              padding: EdgeInsets.only(right: 24.w, top: 6.h),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_charCount / $_kBioMaxLength',
                  style: getTextStyle(
                    fontSize: 12,
                    color: _charCount >= _kBioMaxLength
                        ? appColors.error
                        : appColors.textSecondary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Action buttons ───────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Obx(() {
                final saving = UserController.instance.isBioUpdating.value;
                return Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: saving ? null : () => Get.back(),
                        child: Container(
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: appColors.surface,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              AppStrings.cancel,
                              style: getBoldTextStyle(
                                fontSize: 14,
                                color: appColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Save
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: saving ? null : _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 50.h,
                          decoration: BoxDecoration(
                            gradient: saving
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF00C950),
                                      Color(0xFF009966),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: saving ? appColors.surface : null,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: saving
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00C950,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: saving
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: appColors.textSecondary,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.tick_circle,
                                        size: 17.w,
                                        color: AppColors.white,
                                      ),
                                      SizedBox(width: 7.w),
                                      Text(
                                        AppStrings.profileBioSave,
                                        style: getBoldTextStyle(
                                          fontSize: 14,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
