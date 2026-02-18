import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:shirah/core/utils/constants/app_style_colors.dart';

class InAppBrowser {
  const InAppBrowser._();

  static Future<void> open(
    BuildContext context, {
    required String url,
    Color? toolbarColor,
    bool showTitle = true,
    bool urlBarHidingEnabled = true,
    CustomTabsShareState shareState = CustomTabsShareState.on,
  }) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return;
    final uri = parsed.hasScheme ? parsed : Uri.parse('https://$url');

    final colors = AppStyleColors.instance;
    final theme = Theme.of(context);
    final gradient = colors.appBarGradient;
    final barColor = toolbarColor ?? gradient.colors.first;

    try {
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: barColor,
          ),
          shareState: shareState,
          urlBarHidingEnabled: urlBarHidingEnabled,
          showTitle: showTitle,
          closeButton: CustomTabsCloseButton(
            icon: CustomTabsCloseButtonIcons.back,
          ),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: barColor,
          preferredControlTintColor: theme.colorScheme.onSurface,
          barCollapsingEnabled: urlBarHidingEnabled,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      debugPrint('InAppBrowser open failed: $e');
    }
  }
}
