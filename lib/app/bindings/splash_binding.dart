import 'package:get/get.dart';
import 'package:music_player/app/controllers/splash_controller.dart';

class SplashBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.lazyPut(() => SplashController());

    return [];
  }
}
