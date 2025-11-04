import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'admin_service.dart';
import 'real_fcm_service.dart';

/// Production-ready enhanced service for sending both in-app messaging and normal notifications
class ProductionNotificationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminService _adminService = Get.find<AdminService>();
  final realFCMService = Get.find<RealFCMService>();

  /// Send in-app messaging notification (appears within the app)
  Future<NotificationSendResult> sendInAppMessage({
    required String title,
    required String body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    Map<String, String>? customData,
    String? targetUserId, // Send to specific user
  }) async {
    try {
      // Check if current user is admin
      if (!await _adminService.isCurrentUserAdmin()) {
        return NotificationSendResult(
          success: false,
          message: 'Access denied: Only admin users can send in-app messages',
          tokensProcessed: 0,
          tokensSuccessful: 0,
          tokensFailed: 0,
        );
      }

      debugPrint('📱 Sending in-app message...');

      // Prepare in-app message data
      final messageData = {
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'actionTitle': actionTitle,
        'actionUrl': actionUrl,
        'customData': customData,
        'type': 'in_app_message',
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtFallback':
            DateTime.now().toIso8601String(), // Fallback timestamp
        'createdBy': _adminService.auth.currentUser?.uid,
        'isRead': false,
      };

      if (targetUserId != null) {
        // Send to specific user
        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('in_app_messages')
            .add(messageData);

        debugPrint('📱 In-app message sent to user $targetUserId');
        return NotificationSendResult(
          success: true,
          message: 'In-app message sent successfully to user',
          tokensProcessed: 1,
          tokensSuccessful: 1,
          tokensFailed: 0,
        );
      } else {
        // Send to all users
        final usersSnapshot = await _firestore.collection('users').get();

        int successful = 0;
        int failed = 0;

        for (final doc in usersSnapshot.docs) {
          try {
            await doc.reference.collection('in_app_messages').add(messageData);
            successful++;
          } catch (e) {
            failed++;
            debugPrint('Failed to send in-app message to user ${doc.id}: $e');
          }
        }

        return NotificationSendResult(
          success: successful > 0,
          message: 'In-app messages sent to $successful users',
          tokensProcessed: usersSnapshot.docs.length,
          tokensSuccessful: successful,
          tokensFailed: failed,
        );
      }
    } catch (e) {
      debugPrint('Error sending in-app message: $e');
      return NotificationSendResult(
        success: false,
        message: 'An unexpected error occurred: $e',
        tokensProcessed: 0,
        tokensSuccessful: 0,
        tokensFailed: 0,
        errors: [e.toString()],
      );
    }
  }

  /// Send normal push notification using real FCM API
  Future<NotificationSendResult> sendPushNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    String sound = 'default',
    String priority = 'high',
    int ttl = 86400,
    Map<String, String>? customData,
    String notificationType = 'all', // 'all' or 'logged_in_users'
  }) async {
    try {
      // Check if current user is admin
      if (!await _adminService.isCurrentUserAdmin()) {
        return NotificationSendResult(
          success: false,
          message:
              'Access denied: Only admin users can send push notifications',
          tokensProcessed: 0,
          tokensSuccessful: 0,
          tokensFailed: 0,
        );
      }

      // Check if FCM is configured
      // if (!RealFCMService.isServerKeyConfigured()) {
      //   return NotificationSendResult(
      //     success: false,
      //     message:
      //         'FCM Server Key not configured. Please set it in RealFCMService._serverKey',
      //     tokensProcessed: 0,
      //     tokensSuccessful: 0,
      //     tokensFailed: 0,
      //   );
      // }

      debugPrint('Sending push notification using real FCM API...');

      if (notificationType == 'all') {
        return await _sendToAllTokensRealFCM(
          title: title,
          body: body,
          imageUrl: imageUrl,
          actionTitle: actionTitle,
          actionUrl: actionUrl,
          sound: sound,
          priority: priority,
          ttl: ttl,
          customData: customData,
        );
      } else {
        return await _sendToLoggedInUsersRealFCM(
          title: title,
          body: body,
          imageUrl: imageUrl,
          actionTitle: actionTitle,
          actionUrl: actionUrl,
          sound: sound,
          priority: priority,
          ttl: ttl,
          customData: customData,
        );
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return NotificationSendResult(
        success: false,
        message: 'An unexpected error occurred: $e',
        tokensProcessed: 0,
        tokensSuccessful: 0,
        tokensFailed: 0,
        errors: [e.toString()],
      );
    }
  }

  Future<NotificationSendResult> _sendToAllTokensRealFCM({
    required String title,
    required String body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    String sound = 'default',
    String priority = 'high',
    int ttl = 86400,
    Map<String, String>? customData,
  }) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      if (tokensSnapshot.docs.isEmpty) {
        return NotificationSendResult(
          success: false,
          message: 'No active FCM tokens found',
          tokensProcessed: 0,
          tokensSuccessful: 0,
          tokensFailed: 0,
        );
      }

      debugPrint('Found ${tokensSnapshot.docs.length} active tokens');

      // Extract tokens
      final tokens = tokensSnapshot.docs.map((doc) => doc.id).toList();

      // Send using real FCM service

      final fcmResult = await realFCMService.sendToMultipleTokens(
        tokens: tokens,
        title: title,
        body: body,
        imageUrl: imageUrl,
        actionTitle: actionTitle,
        actionUrl: actionUrl,
        sound: sound,
        priority: priority,
        ttl: ttl,
        customData: customData,
      );

      return NotificationSendResult(
        success: fcmResult.success,
        message: fcmResult.success
            ? 'Push notifications sent successfully to ${fcmResult.successCount} tokens.'
            : 'Failed to send push notifications.',
        tokensProcessed: tokens.length,
        tokensSuccessful: fcmResult.successCount,
        tokensFailed: fcmResult.failureCount,
        errors: fcmResult.errors,
      );
    } catch (e) {
      debugPrint('Error sending to all tokens: $e');
      return NotificationSendResult(
        success: false,
        message: 'An unexpected error occurred: $e',
        tokensProcessed: 0,
        tokensSuccessful: 0,
        tokensFailed: 0,
        errors: [e.toString()],
      );
    }
  }

  Future<NotificationSendResult> _sendToLoggedInUsersRealFCM({
    required String title,
    required String body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    String sound = 'default',
    String priority = 'high',
    int ttl = 86400,
    Map<String, String>? customData,
  }) async {
    try {
      QuerySnapshot usersSnapshot;
      try {
        usersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isNotEqualTo: null)
            .get();
      } catch (e) {
        debugPrint('Permission denied accessing users collection: $e');
        return NotificationSendResult(
          success: false,
          message:
              'Permission denied: Cannot access users collection. Please check Firestore security rules.',
          tokensProcessed: 0,
          tokensSuccessful: 0,
          tokensFailed: 0,
        );
      }

      if (usersSnapshot.docs.isEmpty) {
        return NotificationSendResult(
          success: false,
          message: 'No logged-in users with FCM tokens found',
          tokensProcessed: 0,
          tokensSuccessful: 0,
          tokensFailed: 0,
        );
      }

      debugPrint(
          'Found ${usersSnapshot.docs.length} logged-in users with tokens');

      // Extract tokens
      final tokens = <String>[];
      final errors = <String>[];

      for (final doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>?;
        final fcmToken = userData?['fcmToken'] as String?;
        final userEmail = userData?['email'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          tokens.add(fcmToken);
        } else {
          errors.add('User ${userEmail ?? doc.id}: No valid FCM token found');
          debugPrint('User ${userEmail ?? doc.id}: No valid FCM token found');
        }
      }

      if (tokens.isEmpty) {
        return NotificationSendResult(
          success: false,
          message: 'No valid FCM tokens found among logged-in users',
          tokensProcessed: usersSnapshot.docs.length,
          tokensSuccessful: 0,
          tokensFailed: usersSnapshot.docs.length,
          errors: errors,
        );
      }

      // Send using real FCM service
      final fcmResult = await realFCMService.sendToMultipleTokens(
        tokens: tokens,
        title: title,
        body: body,
        imageUrl: imageUrl,
        actionTitle: actionTitle,
        actionUrl: actionUrl,
        sound: sound,
        priority: priority,
        ttl: ttl,
        customData: customData,
      );

      // Combine FCM errors with token extraction errors
      final allErrors = <String>[];
      allErrors.addAll(errors);
      if (fcmResult.errors != null) {
        allErrors.addAll(fcmResult.errors!);
      }

      return NotificationSendResult(
        success: fcmResult.success,
        message: fcmResult.success
            ? 'Push notifications sent successfully to ${fcmResult.successCount} logged-in users.'
            : 'Failed to send push notifications to logged-in users.',
        tokensProcessed: usersSnapshot.docs.length,
        tokensSuccessful: fcmResult.successCount,
        tokensFailed: fcmResult.failureCount + errors.length,
        errors: allErrors.isNotEmpty ? allErrors : null,
      );
    } catch (e) {
      debugPrint('Error sending to logged-in users: $e');
      return NotificationSendResult(
        success: false,
        message: 'An unexpected error occurred: $e',
        tokensProcessed: 0,
        tokensSuccessful: 0,
        tokensFailed: 0,
        errors: [e.toString()],
      );
    }
  }

  /// Get statistics about available tokens
  Future<NotificationStats> getNotificationStats() async {
    try {
      // Check if current user is admin
      if (!await _adminService.isCurrentUserAdmin()) {
        debugPrint(
            'Access denied: Only admin users can view notification statistics');
        return NotificationStats(
          totalTokens: 0,
          activeTokens: 0,
          loggedInUsers: 0,
          inactiveTokens: 0,
        );
      }

      final allTokensSnapshot = await _firestore.collection('fcm_tokens').get();
      final activeTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      int loggedInUsers = 0;
      try {
        final loggedInUsersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isNotEqualTo: null)
            .get();
        loggedInUsers = loggedInUsersSnapshot.docs.length;
      } catch (e) {
        debugPrint(
            'Permission denied accessing users collection for stats: $e');
      }

      return NotificationStats(
        totalTokens: allTokensSnapshot.docs.length,
        activeTokens: activeTokensSnapshot.docs.length,
        loggedInUsers: loggedInUsers,
        inactiveTokens:
            allTokensSnapshot.docs.length - activeTokensSnapshot.docs.length,
      );
    } catch (e) {
      debugPrint('Error getting notification stats: $e');
      return NotificationStats(
        totalTokens: 0,
        activeTokens: 0,
        loggedInUsers: 0,
        inactiveTokens: 0,
      );
    }
  }
}

/// Result of notification sending operation
class NotificationSendResult {
  final bool success;
  final String message;
  final int tokensProcessed;
  final int tokensSuccessful;
  final int tokensFailed;
  final List<String>? errors;

  NotificationSendResult({
    required this.success,
    required this.message,
    required this.tokensProcessed,
    required this.tokensSuccessful,
    required this.tokensFailed,
    this.errors,
  });

  @override
  String toString() {
    return 'NotificationSendResult{success: $success, message: $message, processed: $tokensProcessed, successful: $tokensSuccessful, failed: $tokensFailed}';
  }
}

/// Statistics about notification targets
class NotificationStats {
  final int totalTokens;
  final int activeTokens;
  final int loggedInUsers;
  final int inactiveTokens;

  NotificationStats({
    required this.totalTokens,
    required this.activeTokens,
    required this.loggedInUsers,
    required this.inactiveTokens,
  });

  @override
  String toString() {
    return 'NotificationStats{total: $totalTokens, active: $activeTokens, loggedIn: $loggedInUsers, inactive: $inactiveTokens}';
  }
}
