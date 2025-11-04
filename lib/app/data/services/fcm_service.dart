import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/fcm_cleanup_models.dart';

/// FCM Service for managing Firebase Cloud Messaging tokens
///
/// This service handles:
/// - FCM token generation and refresh
/// - Saving tokens to Firestore in two places:
///   1. Separate 'fcm_tokens' collection for all tokens
///   2. User's document in 'users' collection when signed in
/// - Token cleanup when users sign out
/// - Notification sending capabilities
class FCMService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentToken;
  final RxString fcmToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeFCM();
  }

  Future<void> initializeFCM() async {
    try {
      // Check internet connectivity first
      if (!await _hasInternetConnection()) {
        debugPrint('FCM: No internet connection - skipping initialization');
        return;
      }

      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted permission');
        await _getAndSaveToken();
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    } catch (e) {
      debugPrint('FCM: Error initializing: $e');
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('FCM: Internet check failed: $e');
      return false;
    }
  }

  Future<void> _getAndSaveToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        fcmToken.value = token;
        debugPrint('FCM: Token obtained: $token');

        // Save token to both FCM collection and user document
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      debugPrint('FCM: Token refreshed: $newToken');
      _currentToken = newToken;
      fcmToken.value = newToken;

      // Update token in database
      await _saveTokenToDatabase(newToken);
    } catch (e) {
      debugPrint('FCM: Error handling token refresh: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final user = _auth.currentUser;
      final timestamp = FieldValue.serverTimestamp();

      // Always save to FCM tokens collection (works for both authenticated and unauthenticated users)
      await _firestore.collection('fcm_tokens').doc(token).set({
        'token': token,
        'userId': user?.uid,
        'userEmail': user?.email,
        'deviceType': defaultTargetPlatform.name,
        'createdAt': timestamp,
        'lastUsed': timestamp,
        'isActive': true,
      }, SetOptions(merge: true));

      debugPrint('FCM: Token saved to fcm_tokens collection');

      // If user is signed in, also save to user's document
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': timestamp,
            'deviceType': defaultTargetPlatform.name,
          });
          debugPrint('FCM: Token saved to user document for ${user.uid}');
        } catch (userDocError) {
          debugPrint('FCM: Error saving to user document: $userDocError');
          // Continue execution even if user document update fails
        }
      } else {
        debugPrint(
            'FCM: No authenticated user, token saved to fcm_tokens only');
      }

      debugPrint('FCM: Token saved to database successfully');
    } catch (e) {
      debugPrint('FCM: Error saving token to database: $e');
    }
  }

  Future<void> updateTokenForUser(String userId) async {
    try {
      if (_currentToken != null) {
        final timestamp = FieldValue.serverTimestamp();

        // Update user's document with current token
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _currentToken,
          'fcmTokenUpdatedAt': timestamp,
          'deviceType': defaultTargetPlatform.name,
        });

        debugPrint('FCM: Token updated for user $userId');
      }
    } catch (e) {
      debugPrint('FCM: Error updating token for user: $e');
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      // Remove token from user's document
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      // Mark token as inactive in FCM collection
      if (_currentToken != null) {
        await _firestore.collection('fcm_tokens').doc(_currentToken).update({
          'isActive': false,
          'lastUsed': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('FCM: Token removed for user $userId');
    } catch (e) {
      debugPrint('FCM: Error removing token for user: $e');
    }
  }

  Future<void> sendNotificationToUser(
    String userId, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token from their document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userToken = userDoc.data()?['fcmToken'] as String?;

      if (userToken != null) {
        // Here you would typically use a server-side service to send the notification
        // For now, we'll just log the notification details
        debugPrint('FCM: Would send notification to user $userId');
        debugPrint('FCM: Title: $title');
        debugPrint('FCM: Body: $body');
        debugPrint('FCM: Data: $data');
        debugPrint('FCM: Token: $userToken');
      } else {
        debugPrint('FCM: No token found for user $userId');
      }
    } catch (e) {
      debugPrint('FCM: Error sending notification: $e');
    }
  }

  String? get currentToken => _currentToken;

  /// Test method to verify Firestore connection and permissions
  Future<bool> testDatabaseConnection() async {
    try {
      // Try to write a test document to fcm_tokens collection
      await _firestore.collection('fcm_tokens').doc('test_connection').set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clean up test document
      await _firestore.collection('fcm_tokens').doc('test_connection').delete();

      debugPrint('FCM: Database connection test successful');
      return true;
    } catch (e) {
      debugPrint('FCM: Database connection test failed: $e');
      return false;
    }
  }

  /// Clean up expired or invalid FCM tokens
  Future<FCMCleanupResult> cleanupExpiredTokens() async {
    try {
      debugPrint('FCM: Starting token cleanup...');

      final now = DateTime.now();
      final expiredThreshold =
          now.subtract(const Duration(days: 30)); // Tokens older than 30 days
      final inactiveThreshold =
          now.subtract(const Duration(days: 21)); // Tokens inactive for 21 days

      int expiredCount = 0;
      int inactiveCount = 0;
      int invalidCount = 0;
      int totalProcessed = 0;

      // Get all FCM tokens
      final tokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint(
          'FCM: Found ${tokensSnapshot.docs.length} active tokens to check');

      for (final doc in tokensSnapshot.docs) {
        final data = doc.data();
        final token = data['token'] as String?;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final lastUsed = (data['lastUsed'] as Timestamp?)?.toDate();

        totalProcessed++;
        bool shouldDelete = false;
        String reason = '';

        // Check if token is expired (older than 30 days)
        if (createdAt != null && createdAt.isBefore(expiredThreshold)) {
          shouldDelete = true;
          reason = 'expired (older than 30 days)';
          expiredCount++;
        }
        // Check if token is inactive (not used for 21 days)
        else if (lastUsed != null && lastUsed.isBefore(inactiveThreshold)) {
          shouldDelete = true;
          reason = 'inactive (not used for 21 days)';
          inactiveCount++;
        }
        // Check if token is invalid (empty or malformed)
        else if (token == null || token.isEmpty || token.length < 10) {
          shouldDelete = true;
          reason = 'invalid token format';
          invalidCount++;
        }

        if (shouldDelete) {
          try {
            // Mark as inactive first
            await doc.reference.update({
              'isActive': false,
              'cleanupReason': reason,
              'cleanedAt': FieldValue.serverTimestamp(),
            });

            debugPrint('FCM: Marked token for cleanup: $reason');

            // Optionally delete the document completely
            // await doc.reference.delete();
          } catch (e) {
            debugPrint('FCM: Error cleaning token ${doc.id}: $e');
          }
        }
      }

      final result = FCMCleanupResult(
        totalProcessed: totalProcessed,
        expiredCount: expiredCount,
        inactiveCount: inactiveCount,
        invalidCount: invalidCount,
        success: true,
      );

      debugPrint(
          'FCM: Cleanup completed - Processed: $totalProcessed, Expired: $expiredCount, Inactive: $inactiveCount, Invalid: $invalidCount');
      return result;
    } catch (e) {
      debugPrint('FCM: Error during token cleanup: $e');
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

  /// Clean up tokens for a specific user (when they sign out or delete account)
  Future<void> cleanupUserTokens(String userId) async {
    try {
      debugPrint('FCM: Cleaning up tokens for user $userId');

      // Find all tokens for this user
      final userTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userTokensSnapshot.docs) {
        await doc.reference.update({
          'isActive': false,
          'cleanupReason': 'user_signout',
          'cleanedAt': FieldValue.serverTimestamp(),
        });
      }

      // Remove FCM token from user's document
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      debugPrint(
          'FCM: Cleaned up ${userTokensSnapshot.docs.length} tokens for user $userId');
    } catch (e) {
      debugPrint('FCM: Error cleaning up user tokens: $e');
    }
  }

  /// Get statistics about FCM tokens in the database
  Future<FCMTokenStats> getTokenStats() async {
    try {
      // Check internet connectivity first
      if (!await _hasInternetConnection()) {
        debugPrint('FCM: No internet connection - returning empty stats');
        return FCMTokenStats(
          totalTokens: 0,
          activeTokens: 0,
          inactiveTokens: 0,
          recentTokens: 0,
          oldTokens: 0,
        );
      }

      final allTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .get()
          .timeout(const Duration(seconds: 10));
      final activeTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final now = DateTime.now();
      final recentThreshold = now.subtract(const Duration(days: 21));

      int recentTokens = 0;
      int oldTokens = 0;

      for (final doc in activeTokensSnapshot.docs) {
        final data = doc.data();
        final lastUsed = (data['lastUsed'] as Timestamp?)?.toDate();

        if (lastUsed != null && lastUsed.isAfter(recentThreshold)) {
          recentTokens++;
        } else {
          oldTokens++;
        }
      }

      return FCMTokenStats(
        totalTokens: allTokensSnapshot.docs.length,
        activeTokens: activeTokensSnapshot.docs.length,
        inactiveTokens:
            allTokensSnapshot.docs.length - activeTokensSnapshot.docs.length,
        recentTokens: recentTokens,
        oldTokens: oldTokens,
      );
    } catch (e) {
      debugPrint('FCM: Error getting token stats: $e');
      return FCMTokenStats(
        totalTokens: 0,
        activeTokens: 0,
        inactiveTokens: 0,
        recentTokens: 0,
        oldTokens: 0,
      );
    }
  }
}
