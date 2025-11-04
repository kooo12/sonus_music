import 'package:flutter/material.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class TpsAppBarTheme {
  TpsAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TpsColors.black, size: TpsSizes.iconMd),
    actionsIconTheme:
        IconThemeData(color: TpsColors.black, size: TpsSizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: TpsColors.black),
  );

  static const greenAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Color.fromARGB(255, 0, 128, 4),
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TpsColors.white, size: TpsSizes.iconMd),
    actionsIconTheme:
        IconThemeData(color: TpsColors.white, size: TpsSizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: TpsColors.white),
  );

  static const primaryAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    backgroundColor: TpsColors.primary,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TpsColors.white, size: TpsSizes.iconMd),
    actionsIconTheme:
        IconThemeData(color: TpsColors.white, size: TpsSizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: TpsColors.white),
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TpsColors.light, size: TpsSizes.iconMd),
    actionsIconTheme:
        IconThemeData(color: TpsColors.white, size: TpsSizes.iconMd),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: TpsColors.white),
  );
}
