import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import '../../data/services/auth_service.dart';
import '../../helper_widgets/popups/loaders.dart';
import '../../data/models/user_model.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/achievement_service.dart';
import '../../controllers/achievement_controller.dart';

class AuthController extends GetxController {
  AuthController(this._authService);

  final AuthService _authService;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString verificationId = ''.obs;
  final Rx<UserModel> currentUser = UserModel.guest().obs;

  void clearTextField() {
    emailCtrl.clear();
    passwordCtrl.clear();
    nameCtrl.clear();
    phoneCtrl.clear();
    codeCtrl.clear();
  }

  Future<void> login() async {
    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      TpsLoader.customToast(message: 'Please enter email and password');
      return;
    }
    isLoading.value = true;
    try {
      final user = await _authService.signIn(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      if (user != null) {
        currentUser.value = UserModel.authenticated(
          id: user.uid,
          name: user.displayName ?? emailCtrl.text.trim(),
          email: user.email ?? emailCtrl.text.trim(),
          profileImageUrl: user.photoURL,
          provider: 'password',
        );
        // Update FCM token for signed-in user
        _updateFCMTokenForUser(user.uid);

        // Sync achievements for logged-in user
        _syncAchievementsForUser(user.uid);
      }
      TpsLoader.customToast(message: 'Logged in successfully');
      Get.back();
    } catch (e) {
      TpsLoader.customToast(message: 'Login failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passwordCtrl.text.isEmpty) {
      TpsLoader.customToast(message: 'Please fill all fields');
      return;
    }
    isLoading.value = true;
    try {
      final user = await _authService.signUp(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        displayName: nameCtrl.text.trim(),
      );
      if (user != null) {
        currentUser.value = UserModel.authenticated(
          id: user.uid,
          name: user.displayName ?? nameCtrl.text.trim(),
          email: user.email ?? emailCtrl.text.trim(),
          profileImageUrl: user.photoURL,
          provider: 'password',
        );
        // Update FCM token for signed-in user
        _updateFCMTokenForUser(user.uid);

        // Sync achievements for signed-up user
        _syncAchievementsForUser(user.uid);
      }
      TpsLoader.customToast(message: 'Account created');
      Get.back();
      Get.back();
    } catch (e) {
      TpsLoader.customToast(message: 'Signup failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        currentUser.value = UserModel.authenticated(
          id: user.uid,
          name: user.displayName ?? (user.email ?? 'User'),
          email: user.email ?? '',
          profileImageUrl: user.photoURL,
          provider: 'google',
        );
        // Update FCM token for signed-in user
        _updateFCMTokenForUser(user.uid);

        // Sync achievements for Google signed-in user
        _syncAchievementsForUser(user.uid);
      }
      TpsLoader.customToast(message: 'Signed in with Google');
      Get.back();
    } catch (e) {
      debugPrint(e.toString());
      TpsLoader.customToast(message: 'Google sign-in failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestPhoneCode() async {
    if (phoneCtrl.text.isEmpty) {
      TpsLoader.customToast(message: 'Enter phone number');
      return;
    }
    isLoading.value = true;
    try {
      await _authService.requestPhoneCode(
        phoneNumber: phoneCtrl.text.trim().replaceAll('09', '+959'),
        onAutoVerified: (cred) async {
          await _authService.signInWithGoogle();
        },
        onCodeSent: (id) {
          verificationId.value = id;
          TpsLoader.customToast(message: 'Code sent to ${phoneCtrl.text}');
        },
        onError: (msg) => TpsLoader.customToast(message: msg),
      );
    } catch (e) {
      TpsLoader.customToast(message: 'Phone verify failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifySmsCode() async {
    if (verificationId.isEmpty || codeCtrl.text.isEmpty) {
      TpsLoader.customToast(message: 'Enter the SMS code');
      return;
    }
    isLoading.value = true;
    try {
      final user = await _authService.verifySmsCode(
        verificationId: verificationId.value,
        smsCode: codeCtrl.text.trim(),
      );
      if (user != null) {
        currentUser.value = UserModel.authenticated(
          id: user.uid,
          name: user.displayName ?? (user.phoneNumber ?? 'User'),
          email: user.email ?? '',
          profileImageUrl: user.photoURL,
          phone: user.phoneNumber,
          provider: 'phone',
        );
        // Update FCM token for signed-in user
        _updateFCMTokenForUser(user.uid);
      }
      TpsLoader.customToast(message: 'Phone verified');
      Get.back();
      Get.back();
    } catch (e) {
      TpsLoader.customToast(message: 'Invalid code: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      final userId = currentUser.value.id;
      await _authService.signOut();
      currentUser.value = UserModel.guest();

      // Remove FCM token for signed-out user
      if (userId != null && userId.isNotEmpty) {
        _removeFCMTokenForUser(userId);
      }

      TpsLoader.customToast(message: 'Signed out successfully');
    } catch (e) {
      TpsLoader.customToast(message: 'Error signing out: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateFCMTokenForUser(String userId) async {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        await fcmService.updateTokenForUser(userId);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> _removeFCMTokenForUser(String userId) async {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        await fcmService.cleanupUserTokens(userId);
      }
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  Future<void> _syncAchievementsForUser(String userId) async {
    try {
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();
        await achievementService.syncLocalToFirestore(userId);
        debugPrint('Achievement sync completed for user: $userId');

        // Refresh achievement controller UI
        if (Get.isRegistered<AchievementController>()) {
          final achievementController = Get.find<AchievementController>();
          await achievementController.refreshAchievements();
        }
      }

      // Sync listening stats
      // if (Get.isRegistered<ListeningStatsService>()) {
      //   final listeningStatsService = Get.find<ListeningStatsService>();
      //   await listeningStatsService.syncLocalToFirestore(userId);
      //   debugPrint('Listening stats sync completed for user: $userId');

      //   // Refresh listening stats controller UI
      //   if (Get.isRegistered<ListeningStatsController>()) {
      //     final listeningStatsController = Get.find<ListeningStatsController>();
      //     await listeningStatsController.refreshStats();
      //   }
      // }
    } catch (e) {
      debugPrint('Error syncing achievements: $e');
    }
  }

  /// Delete user account and all related data
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;

      // Show confirmation dialog
      final confirmed = await _showDeleteAccountConfirmation();
      if (!confirmed) {
        isLoading.value = false;
        return;
      }

      // Show loading dialog
      TpsLoader.openSavingLoading('Deleting account...');

      // Delete the account
      final success = await _authService.deleteAccount();

      if (success) {
        // Close loading dialog
        signOut();
        TpsLoader.stopLoading();

        // Show success message
        TpsLoader.customToast(message: 'Account deleted successfully');
        // Get.snackbar(
        //   'Success',
        //   'Account deleted successfully',
        //   snackPosition: SnackPosition.bottom,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        // );

        // Clear form fields
        clearTextField();
      } else {
        TpsLoader.stopLoading();

        TpsLoader.customToast(message: 'Failed to delete account');

        // Show error message
        Get.snackbar(
          'Error',
          'Failed to delete account. Please try again.',
          snackPosition: SnackPosition.bottom,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Error deleting account: ${e.toString()}',
        snackPosition: SnackPosition.bottom,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint('Error deleting account: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Show confirmation dialog for account deletion
  Future<bool> _showDeleteAccountConfirmation() async {
    return await Get.dialog<bool>(
          GlassAlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data including:\n\n'
              '• All achievements and progress\n'
              // '• Listening statistics and history\n'
              // '• Playlists and songs\n'
              '• Personal data\n'
              '• Account settings\n\n'
              'This action is irreversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(Get.context!, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(Get.context!, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }
}
