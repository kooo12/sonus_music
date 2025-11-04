import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/app_text_theme.dart';
import 'package:music_player/app/ui/theme/appbar_theme.dart';
import 'package:music_player/app/ui/theme/chip_theme.dart';
import 'package:music_player/app/ui/theme/elevated_button_theme.dart';
import 'package:music_player/app/ui/theme/text_field_theme.dart';

import '../ui/theme/checkbox_theme.dart';

//Common Style
// const TextStyle _cardDescTextStyleDark = TextStyle(
//     fontFamily: "bb",
//     color: Colors.white,
//     fontSize: 16,
//     fontWeight: FontWeight.normal);

class ThemeController extends GetxController {
  final _activeThemeIndex = 0.obs;

  final ThemeData appThemeData = ThemeData(
    useMaterial3: true,
    primaryColor: TpsColors.musicPrimary,
    secondaryHeaderColor: TpsColors.darkGrey,

    // splashColor: Colors.blueAccent,
    highlightColor: TpsColors.white,
    // unselectedWidgetColor: TpsColors.lightGrey,
    iconTheme: const IconThemeData(color: Colors.white),
    //fontFamily: 'Georgia',
    textTheme: TpsTextTheme.darkTextTheme,
    appBarTheme: TpsAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: TpsElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: TpsTextFormFieldTheme.darkInputDecorationTheme,
    checkboxTheme: TpsCheckboxTheme.darkCheckboxTheme,
    chipTheme: TpsChipTheme.darkChipTheme,
    cardColor: Colors.black,
    cardTheme: const CardTheme(color: Colors.black),
    // scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.resolveWith(
    //   (state) => TpsColors.grey
    // )),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(TpsColors.dark),
      ),
      textStyle: TpsTextTheme.darkTextTheme.bodyLarge,
    ),

    scaffoldBackgroundColor: TpsColors.white,
    shadowColor: Colors.black,
    // sliderTheme: const SliderThemeData(
    //     thumbColor: TpsColors.secondary,
    //     activeTrackColor: TpsColors.secondary),
    // buttonTheme: const ButtonThemeData(splashColor: TpsColors.secondary),
    // colorScheme:
    //     ColorScheme.fromSwatch().copyWith(secondary: TpsColors.secondary)
  );

  final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    primaryColor: TpsColors.primary,
    secondaryHeaderColor: TpsColors.darkerGrey,
    // splashColor: TpsColors.black,
    highlightColor: TpsColors.black,
    shadowColor: Colors.white,
    // unselectedWidgetColor: TpsColors.darkGrey,
    // iconTheme: const IconThemeData(color: Color.fromARGB(255, 150, 150, 150)),
    //fontFamily: 'Georgia',
    textTheme: TpsTextTheme.darkTextTheme,
    appBarTheme: TpsAppBarTheme.darkAppBarTheme,
    elevatedButtonTheme: TpsElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: TpsTextFormFieldTheme.darkInputDecorationTheme,
    checkboxTheme: TpsCheckboxTheme.darkCheckboxTheme,
    chipTheme: TpsChipTheme.darkChipTheme,
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: Colors.black,
    cardTheme: const CardTheme(color: Colors.black),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(TpsColors.darkerGrey),
      ),
      textStyle: TpsTextTheme.darkTextTheme.bodyLarge,
    ),
    // sliderTheme: const SliderThemeData(
    //     thumbColor: Color.fromARGB(255, 100, 100, 105),
    //     inactiveTrackColor: Color.fromARGB(255, 210, 210, 215),
    //     activeTrackColor: Color.fromARGB(255, 110, 110, 115)),
    // buttonTheme: const ButtonThemeData(splashColor: Colors.grey),
    // colorScheme:
    //     ColorScheme.fromSwatch().copyWith(secondary: Colors.black26)
  );

  final ThemeData appThemeDataGreen = ThemeData(
    useMaterial3: true,
    primaryColor: TpsColors.primary,
    secondaryHeaderColor: TpsColors.darkGrey,

    // splashColor: Colors.blueAccent,
    highlightColor: TpsColors.white,
    // unselectedWidgetColor: TpsColors.lightGrey,
    iconTheme: const IconThemeData(color: Colors.black),
    //fontFamily: 'Georgia',
    textTheme: TpsTextTheme.lightTextTheme,
    appBarTheme: TpsAppBarTheme.greenAppBarTheme,
    elevatedButtonTheme: TpsElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: TpsTextFormFieldTheme.lightInputDecorationTheme,
    checkboxTheme: TpsCheckboxTheme.lightCheckboxTheme,
    chipTheme: TpsChipTheme.lightChipTheme,
    cardColor: Colors.white,
    cardTheme: const CardTheme(color: Colors.white),
    // scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.resolveWith(
    //   (state) => TpsColors.grey
    // )),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(TpsColors.white),
      ),
      textStyle: TpsTextTheme.lightTextTheme.bodyLarge,
    ),

    scaffoldBackgroundColor: TpsColors.white,
    shadowColor: Colors.black,
    // sliderTheme: const SliderThemeData(
    //     thumbColor: TpsColors.secondary,
    //     activeTrackColor: TpsColors.secondary),
    // buttonTheme: const ButtonThemeData(splashColor: TpsColors.secondary),
    // colorScheme:
    //     ColorScheme.fromSwatch().copyWith(secondary: TpsColors.secondary)
  );

  final ThemeData appThemeDataPrimary = ThemeData(
    useMaterial3: true,
    primaryColor: TpsColors.primary,
    secondaryHeaderColor: TpsColors.darkGrey,

    // splashColor: Colors.blueAccent,
    highlightColor: TpsColors.white,
    // unselectedWidgetColor: TpsColors.lightGrey,
    iconTheme: const IconThemeData(color: Colors.black),
    //fontFamily: 'Georgia',
    textTheme: TpsTextTheme.lightTextTheme,
    appBarTheme: TpsAppBarTheme.primaryAppBarTheme,
    elevatedButtonTheme: TpsElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: TpsTextFormFieldTheme.lightInputDecorationTheme,
    checkboxTheme: TpsCheckboxTheme.lightCheckboxTheme,
    chipTheme: TpsChipTheme.lightChipTheme,
    cardColor: Colors.white,
    cardTheme: const CardTheme(color: Colors.white),
    // scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStateProperty.resolveWith(
    //   (state) => TpsColors.grey
    // )),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.darkGrey),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderSide: BorderSide(color: TpsColors.error),
        ),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(TpsColors.white),
      ),
      textStyle: TpsTextTheme.lightTextTheme.bodyLarge,
    ),

    scaffoldBackgroundColor: TpsColors.white,
    shadowColor: Colors.black,
    // sliderTheme: const SliderThemeData(
    //     thumbColor: TpsColors.secondary,
    //     activeTrackColor: TpsColors.secondary),
    // buttonTheme: const ButtonThemeData(splashColor: TpsColors.secondary),
    // colorScheme:
    //     ColorScheme.fromSwatch().copyWith(secondary: TpsColors.secondary)
  );

  final ThemeData appThemeDataRed = ThemeData(
      useMaterial3: true,
      primaryColor: Colors.red,
      splashColor: Colors.redAccent,
      highlightColor: Colors.red,
      //fontFamily: 'Georgia',
      textTheme: TpsTextTheme.lightTextTheme,
      appBarTheme: TpsAppBarTheme.lightAppBarTheme,
      elevatedButtonTheme: TpsElevatedButtonTheme.lightElevatedButtonTheme,
      inputDecorationTheme: TpsTextFormFieldTheme.lightInputDecorationTheme,
      checkboxTheme: TpsCheckboxTheme.lightCheckboxTheme,
      chipTheme: TpsChipTheme.lightChipTheme,
      sliderTheme: const SliderThemeData(
          thumbColor: Color.fromARGB(255, 115, 0, 0),
          activeTrackColor: Color.fromARGB(255, 85, 0, 0)),
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 115, 0, 0)),
      buttonTheme: const ButtonThemeData(splashColor: Colors.redAccent),
      colorScheme:
          ColorScheme.fromSwatch().copyWith(secondary: Colors.redAccent));

  final ThemeData appThemeDataPurple = ThemeData(
      useMaterial3: true,
      primaryColor: Colors.purple,
      splashColor: Colors.purpleAccent,
      highlightColor: Colors.purple,
      //fontFamily: 'Georgia',
      textTheme: TpsTextTheme.lightTextTheme,
      appBarTheme: TpsAppBarTheme.lightAppBarTheme,
      elevatedButtonTheme: TpsElevatedButtonTheme.lightElevatedButtonTheme,
      inputDecorationTheme: TpsTextFormFieldTheme.lightInputDecorationTheme,
      checkboxTheme: TpsCheckboxTheme.lightCheckboxTheme,
      chipTheme: TpsChipTheme.lightChipTheme,
      sliderTheme: const SliderThemeData(
          thumbColor: Colors.deepPurple, activeTrackColor: Colors.purple),
      iconTheme: const IconThemeData(color: Colors.deepPurple),
      buttonTheme: const ButtonThemeData(splashColor: Colors.purpleAccent),
      colorScheme:
          ColorScheme.fromSwatch().copyWith(secondary: Colors.purpleAccent));

  var _themes = <ThemeData>[];
  final _isDarkMode = false.obs;

  ThemeData get activeTheme =>
      isDarkMode ? darkTheme : _themes[_activeThemeIndex.value];

  get menuBackgroundColor => activeTheme.primaryColor;
  get tpsmenuColor => activeTheme.primaryColor;

  get cardTitleTextStyle =>
      isDarkMode ? TpsTextTheme.darkTextTheme : TpsTextTheme.lightTextTheme;

  get menuTitleTextStyle =>
      isDarkMode ? TpsTextTheme.darkTextTheme : TpsTextTheme.lightTextTheme;
  get tpsTitleTextStyle =>
      isDarkMode ? TpsTextTheme.darkTextTheme : TpsTextTheme.lightTextTheme;

  // get cardDescTextStyle =>
  //     isDarkMode ? _cardDescTextStyleDark : TpsTextTheme.lightTextTheme;

  final Color menuColor = Colors.white;

  get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _themes = [appThemeData, appThemeDataGreen, appThemeDataPrimary];
  }

  applyNextTheme() {
    (_activeThemeIndex.value + 1) < _themes.length
        ? _activeThemeIndex.value++
        : _activeThemeIndex.value = 0;
    Get.changeTheme(activeTheme);
  }

  changeTheme(int index) {
    if (index < _themes.length) {
      _activeThemeIndex.value = index;
      Get.changeTheme(activeTheme);
    }
  }

  setDarkMode(bool status) {
    if (status) {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(ThemeMode.light);
      // Get.changeTheme(activeTheme);
    }
    _isDarkMode.value = status;
  }
}
