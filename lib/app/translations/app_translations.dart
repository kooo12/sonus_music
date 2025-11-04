// import '../translations/en_US/en_us_translations.dart';

// abstract class AppTranslation {
//   static Map<String, Map<String, String>> translations = {
//     //'en_US': enUs,
//     'my_MM': enUs,
//   };
// }

import 'dart:ui';

import 'package:get/get.dart';

import 'en_US/en_us_translations.dart';
import 'my_MM/my_mm_translations.dart';

class AppTranslation extends Translations {
  // Default locale
  static const locale = Locale('en', 'US');

  // Fallback locale saves the day when the locale gets in trouble
  static const fallbackLocale = Locale('en', 'US');

  // Supported languages
  static final langs = [
    'English',
    'မြန်မာ',
  ];

  // Supported locales
  static final locales = [
    const Locale('en', 'US'),
    const Locale('my', 'MM'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUs,
        'my_MM': mmMm,
      };
}
