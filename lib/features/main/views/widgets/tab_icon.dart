import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shirah/core/utils/helpers/svg_icon_helper.dart';

/// Reusable tab icon widget with active/inactive states (SVG)
/// All icons are fixed at 24px size per design specification
class TabIcon extends StatelessWidget {
  const TabIcon({
    super.key,
    required this.iconPath,
    required this.isActive,
    this.showDot = false,
  });

  final String iconPath;
  final bool isActive;
  final bool showDot;

  /// Fixed icon size for all states (26px)
  static const double iconSize = 26;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SvgIconHelper.buildIcon(
            assetPath: iconPath,
            size: iconSize,
            color: Colors.white,
          ),
          // Red notification dot for Activities tab
          if (showDot)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10.w,
                height: 10.h,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
