import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shirah/core/utils/helpers/app_helper.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/device/device_utility.dart';

class SLTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// If you want to add the background color to tabs you have to wrap them in Material widget.
  /// To do that we need [PreferredSized] Widget and that's why created custom class. [PreferredSizeWidget]

  const SLTabBar({super.key, required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Material(
        color: AppHelper.isDarkMode ? AppColors.black : AppColors.white,
        child: TabBar(
          tabs: tabs,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppHelper.isDarkMode
              ? AppColors.white
              : AppColors.primary,
          unselectedLabelColor: AppColors.darkGrey,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppDeviceUtils.appBarHeight);
}
