import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../data/services/fcm_service.dart';
import '../../../data/services/real_fcm_service.dart';
import '../../../data/models/fcm_cleanup_models.dart';
import '../../../helper_widgets/popups/loaders.dart';

/// Controller for managing FCM token cleanup operations
class FCMCleanupController extends GetxController {
  final FCMService _fcmService = Get.find<FCMService>();
  final RealFCMService _realFCMService = Get.find<RealFCMService>();

  final RxBool isLoading = false.obs;
  final RxBool isLoadingCleanUp = false.obs;
  final RxBool isLoadingInactive = false.obs;
  final Rx<FCMTokenStats?> tokenStats = Rx<FCMTokenStats?>(null);
  final Rx<FCMCleanupResult?> lastCleanupResult = Rx<FCMCleanupResult?>(null);

  @override
  void onInit() async {
    super.onInit();
    await loadTokenStats();
  }

  /// Load current token statistics
  Future<void> loadTokenStats({bool showLoading = true}) async {
    try {
      isLoading.value = showLoading ? true : false;
      final stats = await _fcmService.getTokenStats();
      tokenStats.value = stats;
      debugPrint('FCM Stats: $stats');
    } catch (e) {
      debugPrint('Error loading token stats: $e');
      TpsLoader.customToast(message: 'Error loading token statistics');
    } finally {
      isLoading.value = false;
    }
  }

  /// Perform cleanup of expired tokens
  Future<void> performCleanup() async {
    try {
      isLoading.value = true;
      TpsLoader.customToast(message: 'Starting FCM token cleanup...');

      final result = await _fcmService.cleanupExpiredTokens();
      lastCleanupResult.value = result;

      if (result.success) {
        final message =
            'Cleanup completed: ${result.totalCleaned} tokens cleaned (${result.expiredCount} expired, ${result.inactiveCount} inactive, ${result.invalidCount} invalid)';
        TpsLoader.customToast(message: message);
        debugPrint('FCM Cleanup Result: $result');

        // Reload stats after cleanup
        await loadTokenStats(showLoading: false);
      } else {
        TpsLoader.customToast(message: 'Cleanup failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
      TpsLoader.customToast(message: 'Cleanup failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Clean up tokens for a specific user
  Future<void> cleanupUserTokens(String userId) async {
    try {
      isLoadingCleanUp.value = true;
      await _fcmService.cleanupUserTokens(userId);
      TpsLoader.customToast(message: 'User tokens cleaned successfully');

      // Reload stats after cleanup
      await loadTokenStats(showLoading: false);
    } catch (e) {
      debugPrint('Error cleaning user tokens: $e');
      TpsLoader.customToast(message: 'Error cleaning user tokens: $e');
    } finally {
      isLoadingCleanUp.value = false;
    }
  }

  /// Clean up all inactive tokens (UNREGISTERED, etc.)
  Future<void> cleanupInactiveTokens() async {
    try {
      isLoadingInactive.value = true;
      TpsLoader.customToast(message: 'Cleaning up inactive tokens...');

      final cleanedCount = await _realFCMService.cleanupAllInactiveTokens();

      if (cleanedCount > 0) {
        TpsLoader.customToast(
            message: 'Cleaned up $cleanedCount inactive tokens');
      } else {
        TpsLoader.customToast(message: 'No inactive tokens found to clean up');
      }

      // Reload stats after cleanup
      await loadTokenStats(showLoading: false);
    } catch (e) {
      debugPrint('Error cleaning inactive tokens: $e');
      TpsLoader.customToast(message: 'Error cleaning inactive tokens: $e');
    } finally {
      isLoadingInactive.value = false;
    }
  }

  /// Get cleanup recommendations based on current stats
  String getCleanupRecommendation() {
    final stats = tokenStats.value;
    if (stats == null) return 'No data available';

    if (stats.inactiveTokens > 10) {
      return 'High number of inactive tokens (${stats.inactiveTokens}). Consider running cleanup.';
    } else if (stats.oldTokens > stats.recentTokens) {
      return 'Many old tokens detected. Cleanup recommended.';
    } else if (stats.totalTokens > 1000) {
      return 'Large number of total tokens (${stats.totalTokens}). Regular cleanup advised.';
    } else {
      return 'Token database looks healthy. No immediate cleanup needed.';
    }
  }

  /// Check if cleanup is recommended
  bool get isCleanupRecommended {
    final stats = tokenStats.value;
    if (stats == null) return false;

    return stats.inactiveTokens > 10 ||
        stats.oldTokens > stats.recentTokens ||
        stats.totalTokens > 1000;
  }
}
