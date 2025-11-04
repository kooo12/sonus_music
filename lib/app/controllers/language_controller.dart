import 'dart:ui';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/translations/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  //Initialised properties  --------------------------------------
  // final AppStateRepository?
  //     repository; //Repository may be controller or other class providing data
  // LanguageController(this.repository) : assert(repository != null);

  final ThemeController _themeCtrl = Get.find<ThemeController>();

  //Static --------------------------------------------------------NONE

  //Public  -------------------------------------------------------NONE
  late SharedPreferences _prefs;
  final RxString _appVersion = ''.obs;

  //Private -------------------------------------------------------
  final _isLoading = false.obs;
  final RxInt _currentLangIndex = 0.obs;

  //Getters
  get isLoading => _isLoading.value;

  Locale get currentLocale => AppTranslation.locales[_currentLangIndex.value];
  String get selectedLanguage => AppTranslation.langs[_currentLangIndex.value];
  RxInt get currentLangIndex => _currentLangIndex;
  String get appVersion => _appVersion.value;

  //Setters -------------------------------------------------------

  @override
  onInit() {
    _initializeSettings();
    super.onInit();
  }

  //Public Methods ( Functions) -----------------------------------

  Future<void> _initializeSettings() async {
    _isLoading.value = true;
    _prefs = await SharedPreferences.getInstance();

    await _loadLanguagePreference();
    await loadMode();
    _isLoading.value = false;
  }

  Future<void> _loadLanguagePreference() async {
    String? lang = _prefs.getString("language");
    if (lang != null && lang.isNotEmpty) {
      int index = AppTranslation.langs.indexOf(lang);
      if (index != -1) {
        _currentLangIndex.value = index;
        Get.updateLocale(AppTranslation.locales[index]);
      } else {
        _currentLangIndex.value = 0;
      }
    } else {
      _currentLangIndex.value = 0;
    }
  }

  Future<void> loadMode() async {
    _themeCtrl.setDarkMode(_prefs.getBool("greyMode") ?? false);
  }

  Future<void> changeLanguage(String language) async {
    int index = AppTranslation.langs.indexOf(language);
    if (index != -1 && index != _currentLangIndex.value) {
      _currentLangIndex.value = index;
      Locale locale = AppTranslation.locales[index];
      Get.updateLocale(locale);
      await _prefs.setString("language", language);
    }
  }

  Future<void> changeMode(bool value) async {
    _themeCtrl.setDarkMode(value);
    await _prefs.setBool("greyMode", value);
  }

  void previousLanguage() {
    if (_currentLangIndex.value > 0) {
      changeLanguage(AppTranslation.langs[_currentLangIndex.value - 1]);
    } else {
      changeLanguage(AppTranslation.langs.last);
    }
  }

  void nextLanguage() {
    if (_currentLangIndex.value < AppTranslation.langs.length - 1) {
      changeLanguage(AppTranslation.langs[_currentLangIndex.value + 1]);
    } else {
      changeLanguage(AppTranslation.langs.first);
    }
  }

  //Private Methods ( used internally ) ---------------------------

  //Public Methods  ( Routing : start with to) -------------------- NONE
}
