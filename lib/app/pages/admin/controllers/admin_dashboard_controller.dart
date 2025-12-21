import 'package:get/get.dart';
import 'package:music_player/app/data/services/admin_service.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import 'package:music_player/app/routes/app_routes.dart';

class AdminDashboardController extends GetxController {
  final AdminService _adminService = Get.find<AdminService>();

  final RxBool isLoading = true.obs;
  final Rx<AdminStats?> stats = Rx<AdminStats?>(null);

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;

    try {
      final adminStats = await _adminService.getAdminStats();
      stats.value = adminStats;
    } catch (e) {
      TpsLoader.customToast(message: 'Error loading admin stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createAdminAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final success = await _adminService.createAdminAccount(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (success) {
        TpsLoader.customToast(message: 'Admin account created successfully');
        loadStats(); // Refresh stats
      } else {
        TpsLoader.customToast(message: 'Failed to create admin account');
      }
    } catch (e) {
      TpsLoader.customToast(message: 'Error creating admin account: $e');
    }
  }

  void toFCMStatus() {
    Get.toNamed(Routes.FCMMANAGEMENTPAGE);
  }

  void toUserManagement() {
    Get.toNamed(Routes.USERMANAGEMENTPAGE);
  }

  void toSendNotification() {
    Get.toNamed(Routes.NOTIFICATIONSENDERPAGE);
  }
}
