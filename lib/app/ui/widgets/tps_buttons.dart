import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import 'package:music_player/constants.dart';

class TpsButtons {
  // Adjust the button width with sizedBox
  static Widget confirm({
    required VoidCallback? onPressed,
    required String text,
    IconData icon = Icons.confirmation_num,
    Color color = TpsColors.white,
    Color backgroundColor = TpsColors.primary,
    double borderRadius = TpsSizes.borderRadiusSm,
    bool isLarge = false,
    // bool isTablet = false,
    int maxLines = 2,
    bool isLoading = false,
    bool isDisabled = false,
    bool hasIcon = false,
    double vertical = TpsSizes.md,
    double horizontal = TpsSizes.xl,
  }) {
    final themeCtrl = Get.find<ThemeController>();
    return SizedBox(
      width: isLarge
          ? isTablet
              ? Get.width * 0.4
              : double.infinity
          : isTablet
              ? Get.width * 0.4
              : null,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TpsSizes.xs),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              backgroundColor:
                  isDisabled ? TpsColors.darkerGrey : backgroundColor,
              padding: EdgeInsets.symmetric(
                  horizontal: horizontal, vertical: vertical),
            ),
            onPressed: isDisabled ? null : onPressed,
            child: hasIcon
                ? Row(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: color,
                      ),
                      const SizedBox(
                        width: TpsSizes.spaceBtwItems,
                      ),
                      Text(
                        text,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: themeCtrl.activeTheme.textTheme.titleLarge!
                            .copyWith(color: color),
                      )
                    ],
                  )
                : isLoading
                    ? CircularProgressIndicator(
                        color: color,
                      )
                    : Text(
                        text,
                        maxLines: maxLines,
                        overflow: TextOverflow.ellipsis,
                        style: themeCtrl.activeTheme.textTheme.titleLarge!
                            .copyWith(color: color),
                      ),
          )),
    );
  }

  static Widget delete({
    required VoidCallback onPressed,
    required String text,
    IconData icon = Icons.confirmation_num,
    Color backgroundColor = TpsColors.error,
    Color color = TpsColors.white,
    double borderRadius = TpsSizes.borderRadiusSm,
    bool isLarge = false,
    bool isDisabled = false,
    int maxLines = 2,
    bool hasIcon = false,
    double vertical = TpsSizes.md,
    double horizontal = TpsSizes.xl,
  }) {
    final themeCtrl = Get.find<ThemeController>();
    return SizedBox(
      width: isLarge ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            backgroundColor: backgroundColor,
            padding: EdgeInsets.symmetric(
                horizontal: horizontal, vertical: vertical)),
        onPressed: isDisabled ? null : onPressed,
        child: hasIcon
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                  ),
                  const SizedBox(
                    width: TpsSizes.spaceBtwItems,
                  ),
                  Text(
                    text,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: themeCtrl.activeTheme.textTheme.titleLarge!
                        .copyWith(color: color),
                  )
                ],
              )
            : Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: themeCtrl.activeTheme.textTheme.titleLarge!
                    .copyWith(color: color),
              ),
      ),
    );
  }

  static Widget cancel({
    required VoidCallback onPressed,
    required String text,
    int maxLines = 2,
    Color color = TpsColors.white,
    double borderRadius = TpsSizes.borderRadiusSm,
    bool isLarge = false,
    double vertical = TpsSizes.md,
    double horizontal = TpsSizes.xl,
  }) {
    final themeCtrl = Get.find<ThemeController>();
    return SizedBox(
      width: isLarge ? double.infinity : null,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            backgroundColor: TpsColors.black,
            padding: EdgeInsets.symmetric(
                horizontal: horizontal, vertical: vertical)),
        onPressed: onPressed,
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: themeCtrl.activeTheme.textTheme.titleLarge!
              .copyWith(color: color),
        ),
      ),
    );
  }

  static Widget text(
      {required VoidCallback onPressed,
      required String text,
      bool isDisabled = false,
      int maxLines = 2,
      Color disabledColor = TpsColors.darkGrey,
      Color? color,
      FontWeight fontweight = FontWeight.bold}) {
    final themeCtrl = Get.find<ThemeController>();
    return TextButton(
        onPressed: isDisabled ? null : onPressed,
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: themeCtrl.activeTheme.textTheme.titleLarge!
              .copyWith(color: isDisabled ? disabledColor : color),
        ));
  }

  static Widget iconButton(
      {required VoidCallback onPressed,
      required IconData icon,
      Color color = TpsColors.black,
      Color disabledColor = TpsColors.darkGrey,
      bool isDisable = false}) {
    return IconButton(
        onPressed: isDisable ? null : onPressed,
        icon: Icon(
          icon,
          color: isDisable ? disabledColor : color,
        ));
  }
}
