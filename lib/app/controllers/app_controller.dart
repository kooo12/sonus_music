import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/repository/appstate_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppController extends GetxController {
  //Static --------------------------------------------------------NONE

  //Initialised properties  --------------------------------------
  final AppStateRepository repository = AppStateRepository();
  AppController();
  final themeCtrl = Get.find<ThemeController>();
  //Public  -------------------------------------------------------NONE

  //Private -------------------------------------------------------
  RxString? version = "".obs;
  RxString? buildNumber = "".obs;

  @override
  onInit() async {
    debugPrint("App controller init...");
    await getVersion();
    super.onInit();
    setup();
  }

//Get version no.
  Future<void> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version!.value = packageInfo.version;
    buildNumber!.value = packageInfo.buildNumber;
  }

  //Getters
  get runtime => repository.getProperty(AppStateRepository.RuntimeKey) ?? 0;

  //Setters -------------------------------------------------------

  set runtime(value) => repository.runtime = value;
  //Public Methods ( Functions) -----------------------------------

  Future<void> setup() async {
    await repository.fetchProperty();
    await increaseRuntime();
  }

  Future<void> updateTheme() async {
    var darkMode = (repository.getProperty("darkmode") ?? false);
    if (darkMode) {
      themeCtrl.setDarkMode(true);
    }

    return;
  }

  Future<void> increaseRuntime() async {
    await repository.updateProperty(AppStateRepository.RuntimeKey, ++runtime);
    return;
  }
}
