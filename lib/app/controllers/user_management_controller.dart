import 'package:get/get.dart';
import 'package:music_player/app/data/models/user_model.dart';
import 'package:music_player/app/data/services/admin_service.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';

class UserManagementController extends GetxController {
  final AdminService _adminService = Get.find<AdminService>();

  final RxBool isLoading = true.obs;
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxString filterType = 'all'.obs;

  List<UserModel> get filteredUsers {
    switch (filterType.value) {
      case 'admins':
        return allUsers.where((user) => user.isAdmin).toList();
      case 'users':
        return allUsers.where((user) => !user.isAdmin).toList();
      default:
        return allUsers;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;

    try {
      final users = await _adminService.getAllUsers();
      allUsers.value = users;
    } catch (e) {
      TpsLoader.customToast(message: 'Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilterType(String type) {
    filterType.value = type;
  }

  Future<void> promoteToAdmin(String userId) async {
    try {
      final success = await _adminService.promoteToAdmin(userId);
      if (success) {
        TpsLoader.customToast(message: 'User promoted to admin successfully');
        loadUsers(); // Refresh the list
      } else {
        TpsLoader.customToast(message: 'Failed to promote user to admin');
      }
    } catch (e) {
      TpsLoader.customToast(message: 'Error promoting user: $e');
    }
  }

  Future<void> demoteFromAdmin(String userId) async {
    try {
      final success = await _adminService.demoteFromAdmin(userId);
      if (success) {
        TpsLoader.customToast(message: 'Admin privileges removed successfully');
        loadUsers(); // Refresh the list
      } else {
        TpsLoader.customToast(message: 'Failed to remove admin privileges');
      }
    } catch (e) {
      TpsLoader.customToast(message: 'Error removing admin privileges: $e');
    }
  }
}
