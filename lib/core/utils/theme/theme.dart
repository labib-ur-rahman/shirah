import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/theme/custom_themes/chip_theme.dart';
import 'package:shirah/core/utils/theme/custom_themes/text_theme.dart';

import 'custom_themes/appbar_theme.dart';
import 'custom_themes/bottom_sheet_theme.dart';
import 'custom_themes/checkbox_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/outlined_button_theme.dart';
import 'custom_themes/text_field_theme.dart';

class AppTheme {
  AppTheme._();

  static final AppStyleColors appStyleColors = AppStyleColors.instance;

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.hindSiliguri().fontFamily,
    brightness: Brightness.light,
    primaryColor: appStyleColors.primary,
    scaffoldBackgroundColor: appStyleColors.background,
    textTheme: AppTextTheme.lightTextTheme,
    chipTheme: AppChipTheme.lightChipTheme,
    appBarTheme: AppAppBarTheme.lightAppBarTheme,
    checkboxTheme: AppCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: AppTextFieldTheme.lightInputDecorationTheme,
  );

  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.hindSiliguri().fontFamily,
    brightness: Brightness.dark,
    primaryColor: appStyleColors.primary,
    scaffoldBackgroundColor: appStyleColors.background,
    textTheme: AppTextTheme.darkTextTheme,
    chipTheme: AppChipTheme.darkChipTheme,
    appBarTheme: AppAppBarTheme.darkAppBarTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: AppBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: AppTextFieldTheme.darkInputDecorationTheme,
  );
}
