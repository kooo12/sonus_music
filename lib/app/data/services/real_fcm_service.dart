import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

/// Real FCM service for production push notifications
class RealFCMService {
  // For HTTP v1 API (recommended)
  static const String _fcmV1Url =
      'https://fcm.googleapis.com/v1/projects/music-player-a4a63/messages:send';

  // For Legacy API (deprecated but still works)
  // static const String _fcmLegacyUrl = 'https://fcm.googleapis.com/fcm/send';

  // For HTTP v1 API, we use service account authentication via JSON file
  // The service account key file should be placed in assets/music-player-service-key.json

//   Future<String> _getAccessToken() async {
//   final accountCredentials = ServiceAccountCredentials.fromJson({
//     "type": "service_account",
//     // ... your service account JSON key content
//   });

//   final client = await clientViaServiceAccount(
//     accountCredentials,
//     ['https://www.googleapis.com/auth/firebase.messaging'],
//   );
//   return client.credentials.accessToken.data;
// }

  Future<String> _getAccessToken() async {
    // Load the JSON file from assets
    final String jsonString =
        await rootBundle.loadString('assets/music-player-service-key.json');
    final Map<String, dynamic> serviceAccount = json.decode(jsonString);
    final accountCredentials =
        ServiceAccountCredentials.fromJson(serviceAccount);
    final client = await clientViaServiceAccount(
      accountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  /// Send push notification to a single FCM token
  Future<FCMResult> sendToToken({
    required String token,
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
      debugPrint(
          'Sending FCM notification to token: ${token.substring(0, 20)}...');

      var accessToken = await _getAccessToken();

      final payload = _buildFCMPayload(
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

      final requestBody = {
        'message': {
          'token': token,
          ...payload,
        },
      };

      debugPrint('FCM Request payload: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_fcmV1Url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final messageId = responseData['name'];

        if (messageId != null && messageId.isNotEmpty) {
          debugPrint('FCM notification sent successfully');
          return FCMResult(
            success: true,
            messageId: messageId,
            error: null,
          );
        } else {
          debugPrint('FCM notification failed: No message ID returned');
          return FCMResult(
            success: false,
            messageId: null,
            error: 'No message ID returned',
          );
        }
      } else {
        debugPrint('FCM HTTP error: ${response.statusCode} - ${response.body}');
        return FCMResult(
          success: false,
          messageId: null,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('FCM error: $e');
      return FCMResult(
        success: false,
        messageId: null,
        error: e.toString(),
      );
    }
  }

  /// Send push notification to multiple FCM tokens
  Future<FCMBatchResult> sendToMultipleTokens({
    required List<String> tokens,
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
      debugPrint('Sending FCM notification to ${tokens.length} tokens');

      int successCount = 0;
      int failureCount = 0;
      List<String> errors = [];

      // Send to each token individually using HTTP v1 API
      for (final token in tokens) {
        try {
          final result = await sendToToken(
            token: token,
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

          if (result.success) {
            successCount++;
          } else {
            failureCount++;
            errors.add('Token ${token.substring(0, 20)}...: ${result.error}');

            // Auto-cleanup invalid tokens for various error codes
            if (result.error != null && _shouldCleanupToken(result.error!)) {
              await _cleanupInvalidToken(token);
            }
          }
        } catch (e) {
          failureCount++;
          errors.add('Token ${token.substring(0, 20)}...: $e');
        }
      }

      debugPrint(
          'FCM batch result: $successCount successful, $failureCount failed');
      return FCMBatchResult(
        success: successCount > 0,
        successCount: successCount,
        failureCount: failureCount,
        errors: errors.isNotEmpty ? errors : null,
      );
    } catch (e) {
      debugPrint('FCM batch error: $e');
      return FCMBatchResult(
        success: false,
        successCount: 0,
        failureCount: tokens.length,
        errors: [e.toString()],
      );
    }
  }

  /// Build FCM payload
  static Map<String, dynamic> _buildFCMPayload({
    required String title,
    required String body,
    String? imageUrl,
    String? actionTitle,
    String? actionUrl,
    String sound = 'default',
    String priority = 'high',
    int ttl = 86400,
    Map<String, String>? customData,
  }) {
    // Ensure priority is never empty
    final cleanPriority = priority.trim().isEmpty ? 'high' : priority;
    final Map<String, dynamic> notification = {
      'title': title,
      'body': body,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      notification['image'] = imageUrl;
    }

    final Map<String, dynamic> data = {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    };

    if (actionTitle != null && actionTitle.isNotEmpty) {
      data['action_title'] = actionTitle;
    }
    if (actionUrl != null && actionUrl.isNotEmpty) {
      data['action_url'] = actionUrl;
    }
    if (customData != null) {
      data.addAll(customData);
    }

    // HTTP v1 API requires specific enum values for Android priority
    String androidPriority;
    switch (cleanPriority.toLowerCase()) {
      case 'high':
        androidPriority = 'HIGH';
        break;
      case 'normal':
        androidPriority = 'NORMAL';
        break;
      default:
        androidPriority = 'HIGH'; // Default to HIGH for better delivery
    }

    // HTTP v1 API expects TTL in format "3600s" or as duration
    final Map<String, dynamic> android = {
      'priority': androidPriority,
      'ttl': '${ttl}s',
    };

    final Map<String, dynamic> apns = {
      'payload': {
        'aps': {
          'alert': notification,
          'sound': sound,
        },
      },
    };

    return {
      'notification': notification,
      'data': data,
      'android': android,
      'apns': apns,
    };
  }

  /// Check if a token should be cleaned up based on error message
  bool _shouldCleanupToken(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('unregistered') ||
        errorLower.contains('invalid_registration') ||
        errorLower.contains('mismatch_sender_id') ||
        errorLower.contains('not_registered');
  }

  /// Cleanup invalid FCM token from database
  Future<void> _cleanupInvalidToken(String token) async {
    try {
      debugPrint('Cleaning up invalid FCM token: ${token.substring(0, 20)}...');

      final firestore = FirebaseFirestore.instance;

      // First mark token as inactive for tracking, then delete it completely
      await firestore.collection('fcm_tokens').doc(token).update({
        'isActive': false,
        'cleanupReason': 'UNREGISTERED',
        'cleanedAt': FieldValue.serverTimestamp(),
        'lastError': 'UNREGISTERED - Token no longer valid',
      });

      debugPrint('Invalid token marked as inactive in fcm_tokens collection');

      // Now delete the token document completely since it's no longer valid
      await firestore.collection('fcm_tokens').doc(token).delete();
      debugPrint('Invalid token completely removed from fcm_tokens collection');

      // Also remove from user documents if it exists
      final userDocsWithToken = await firestore
          .collection('users')
          .where('fcmToken', isEqualTo: token)
          .get();

      for (final userDoc in userDocsWithToken.docs) {
        await userDoc.reference.update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
          'fcmTokenCleanupReason': 'UNREGISTERED',
          'fcmTokenCleanedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Removed invalid token from user document: ${userDoc.id}');
      }
    } catch (e) {
      debugPrint('Error cleaning up invalid token: $e');
    }
  }

  /// Manually clean up all inactive tokens from database
  Future<int> cleanupAllInactiveTokens() async {
    try {
      debugPrint('🧹 Starting cleanup of all inactive tokens...');

      final firestore = FirebaseFirestore.instance;
      final inactiveTokensSnapshot = await firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: false)
          .get();

      int cleanedCount = 0;
      for (final doc in inactiveTokensSnapshot.docs) {
        await doc.reference.delete();
        cleanedCount++;
      }

      debugPrint('Cleaned up $cleanedCount inactive tokens');
      return cleanedCount;
    } catch (e) {
      debugPrint('Error cleaning up inactive tokens: $e');
      return 0;
    }
  }
}

/// Result of single FCM notification
class FCMResult {
  final bool success;
  final String? messageId;
  final String? error;

  FCMResult({
    required this.success,
    this.messageId,
    this.error,
  });

  @override
  String toString() {
    return 'FCMResult{success: $success, messageId: $messageId, error: $error}';
  }
}

/// Result of batch FCM notifications
class FCMBatchResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final List<String>? errors;

  FCMBatchResult({
    required this.success,
    required this.successCount,
    required this.failureCount,
    this.errors,
  });

  @override
  String toString() {
    return 'FCMBatchResult{success: $success, successCount: $successCount, failureCount: $failureCount, errors: $errors}';
  }
}
