import 'package:get/get.dart';
import 'package:music_player/app/controllers/home_controller.dart';

class HomeBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(HomeController(), permanent: true);
    return [];
  }
}
