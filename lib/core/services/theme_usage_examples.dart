import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shirah/core/services/theme_service.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';
import 'package:shirah/core/utils/helpers/helper_functions.dart';

/// ============================================================================
/// THEME USAGE EXAMPLES
/// ============================================================================
/// This file demonstrates correct usage patterns for the enterprise-level
/// theme management system in shirah app.
///
/// Quick Reference:
/// - Change theme: ThemeService.changeTheme(ThemeMode.dark)
/// - Check theme: SLHelper.isDarkMode
/// - Reactive screen: GetBuilder<ThemeService>
/// - Colors: AppStyleColors.instance.background
/// ============================================================================

/// Example 1: Simple Theme-Reactive Screen
/// ✅ Use this pattern for screens that need instant theme updates
class ThemeReactiveScreenExample extends StatelessWidget {
  const ThemeReactiveScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap entire screen in GetBuilder<ThemeService>
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        // Access theme-aware colors
        final colors = AppStyleColors.instance;
        final isDark = SLHelper.isDarkMode;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text('Theme Example'),
            backgroundColor: colors.primary,
            actions: [
              // Theme toggle button
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ThemeService.toggleTheme(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card example
                Card(
                  color: colors.surface,
                  elevation: isDark ? 0 : 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Theme',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Button examples
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ThemeService.changeTheme(ThemeMode.light);
                  },
                  child: Text('Switch to Light'),
                ),

                SizedBox(height: 8.h),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ThemeService.changeTheme(ThemeMode.dark);
                  },
                  child: Text('Switch to Dark'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Example 2: Widget with Conditional Theme Logic
/// ✅ Shows how to use theme checks for conditional rendering
class ConditionalThemeWidgetExample extends StatelessWidget {
  const ConditionalThemeWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final isDark = SLHelper.isDarkMode;
        final colors = AppStyleColors.instance;

        // Conditional rendering based on theme
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
            // Different shadows for different themes
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Different icons for different themes
              Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny,
                color: colors.primary,
                size: 32,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDark ? 'Dark Mode Active' : 'Light Mode Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isDark
                          ? 'Night-friendly colors'
                          : 'Bright and vibrant colors',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Example 3: List with Theme-Aware Items
/// ✅ Shows how to use theme in ListView
class ThemeAwareListExample extends StatelessWidget {
  const ThemeAwareListExample({super.key});

  final List<String> items = const [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        final colors = AppStyleColors.instance;
        final isDark = SLHelper.isDarkMode;

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              Divider(color: isDark ? Colors.white24 : Colors.black12),
          itemBuilder: (context, index) {
            return ListTile(
              tileColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: colors.primary,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                items[index],
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isDark ? 'Dark theme item' : 'Light theme item',
                style: TextStyle(color: colors.textSecondary),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: colors.textSecondary,
                size: 16,
              ),
            );
          },
        );
      },
    );
  }
}

/// Example 4: Dialog with Theme Support
/// ✅ Shows how to create theme-aware dialogs
class ThemeAwareDialogExample {
  static void show(BuildContext context) {
    final colors = AppStyleColors.instance;
    final isDark = SLHelper.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => GetBuilder<ThemeService>(
        builder: (themeService) {
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: colors.primary,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Theme Settings',
                  style: TextStyle(color: colors.textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your preferred theme',
                  style: TextStyle(color: colors.textSecondary),
                ),
                SizedBox(height: 16.h),
                _ThemeOption(
                  title: 'Light Mode',
                  icon: Icons.wb_sunny,
                  isSelected: !isDark,
                  onTap: () {
                    ThemeService.changeTheme(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 8.h),
                _ThemeOption(
                  title: 'Dark Mode',
                  icon: Icons.nightlight_round,
                  isSelected: isDark,
                  onTap: () {
                    ThemeService.changeTheme(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: colors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Helper widget for theme option
class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppStyleColors.instance;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? colors.primary : colors.textSecondary,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colors.primary.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

/// Example 5: Bottom Sheet with Theme Support
/// ✅ Shows how to create theme-aware bottom sheets
class ThemeAwareBottomSheetExample {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GetBuilder<ThemeService>(
        builder: (themeService) {
          final colors = AppStyleColors.instance;
          final isDark = SLHelper.isDarkMode;

          return Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Theme Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                ListTile(
                  leading: Icon(Icons.wb_sunny, color: colors.primary),
                  title: Text(
                    'Light Mode',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  trailing: Radio<bool>(
                    value: false,
                    groupValue: isDark,
                    activeColor: colors.primary,
                    onChanged: (value) {
                      ThemeService.changeTheme(ThemeMode.light);
                    },
                  ),
                  onTap: () {
                    ThemeService.changeTheme(ThemeMode.light);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.nightlight_round, color: colors.primary),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  trailing: Radio<bool>(
                    value: true,
                    groupValue: isDark,
                    activeColor: colors.primary,
                    onChanged: (value) {
                      ThemeService.changeTheme(ThemeMode.dark);
                    },
                  ),
                  onTap: () {
                    ThemeService.changeTheme(ThemeMode.dark);
                  },
                ),
                SizedBox(height: 16.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
