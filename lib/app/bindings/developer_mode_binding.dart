import 'package:get/get.dart';
import 'package:music_player/app/controllers/admin_dashboard_controller.dart';
import 'package:music_player/app/controllers/user_management_controller.dart';
import 'package:music_player/app/pages/admin/controllers/fcm_cleanup_controller.dart';
import 'package:music_player/app/pages/admin/controllers/developer_mode_controller.dart';

class DeveloperModeBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(FCMCleanupController());
    Get.put(UserManagementController());
    Get.put(AdminDashboardController());
    Get.put(DeveloperModeController());
    return [];
  }
}
