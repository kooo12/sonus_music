import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'fcm_service.dart';
import '../models/fcm_cleanup_models.dart';

/// Helper class for FCM token cleanup operations
/// Provides easy access to cleanup functions from anywhere in the app
class FCMCleanupHelper {
  /// Run automatic cleanup of expired tokens
  /// This can be called periodically or on app startup
  static Future<FCMCleanupResult> runAutomaticCleanup() async {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        final result = await fcmService.cleanupExpiredTokens();

        debugPrint('FCM Auto Cleanup: ${result.totalCleaned} tokens cleaned');
        return result;
      } else {
        debugPrint('FCM Service not registered');
        return FCMCleanupResult(
          totalProcessed: 0,
          expiredCount: 0,
          inactiveCount: 0,
          invalidCount: 0,
          success: false,
          error: 'FCM Service not registered',
        );
      }
    } catch (e) {
      debugPrint('FCM Auto Cleanup Error: $e');
      return FCMCleanupResult(
        totalProcessed: 0,
        expiredCount: 0,
        inactiveCount: 0,
        invalidCount: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get current token statistics
  static Future<FCMTokenStats> getTokenStatistics() async {
    try {
      if (Get.isRegistered<FCMService>()) {
        final fcmService = Get.find<FCMService>();
        return await fcmService.getTokenStats();
      } else {
        return FCMTokenStats(
          totalTokens: 0,
          activeTokens: 0,
          inactiveTokens: 0,
          recentTokens: 0,
          oldTokens: 0,
        );
      }
    } catch (e) {
      debugPrint('Error getting token statistics: $e');
      return FCMTokenStats(
        totalTokens: 0,
        activeTokens: 0,
        inactiveTokens: 0,
        recentTokens: 0,
        oldTokens: 0,
      );
    }
  }

  /// Check if cleanup is needed based on current statistics
  static Future<bool> isCleanupNeeded() async {
    try {
      final stats = await getTokenStatistics();

      // Cleanup is needed if:
      // - More than 10 inactive tokens
      // - More old tokens than recent tokens
      // - More than 1000 total tokens
      return stats.inactiveTokens > 10 ||
          stats.oldTokens > stats.recentTokens ||
          stats.totalTokens > 1000;
    } catch (e) {
      debugPrint('Error checking cleanup need: $e');
      return false;
    }
  }

  /// debugPrint current FCM token statistics to console
  static Future<void> debugPrintTokenStats() async {
    try {
      final stats = await getTokenStatistics();
      debugPrint('FCM Token Statistics:');
      debugPrint('Total Tokens: ${stats.totalTokens}');
      debugPrint('Active Tokens: ${stats.activeTokens}');
      debugPrint('Inactive Tokens: ${stats.inactiveTokens}');
      debugPrint('Recent Tokens: ${stats.recentTokens}');
      debugPrint('Old Tokens: ${stats.oldTokens}');
      debugPrint(
          'Active Percentage: ${stats.activePercentage.toStringAsFixed(1)}%');
      debugPrint(
          'Recent Percentage: ${stats.recentPercentage.toStringAsFixed(1)}%');
    } catch (e) {
      debugPrint('Error debugPrinting token stats: $e');
    }
  }

  /// Run cleanup if needed
  static Future<void> runCleanupIfNeeded() async {
    try {
      final needsCleanup = await isCleanupNeeded();
      if (needsCleanup) {
        debugPrint('FCM cleanup needed, running automatic cleanup...');
        final result = await runAutomaticCleanup();
        if (result.success) {
          debugPrint('FCM cleanup completed successfully');
        } else {
          debugPrint('FCM cleanup failed: ${result.error}');
        }
      } else {
        debugPrint('FCM tokens are healthy, no cleanup needed');
      }
    } catch (e) {
      debugPrint('Error in runCleanupIfNeeded: $e');
    }
  }
}
