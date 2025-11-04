import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helper_widgets/popups/in_app_message_dialog.dart';
import 'notification_settings_service.dart';
import 'sleep_timer_service.dart';

/// Comprehensive notification handling service
/// Handles both FCM push notifications and in-app messages
class NotificationHandlerService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers for real-time updates
  final RxList<InAppMessage> inAppMessages = <InAppMessage>[].obs;
  final RxBool hasUnreadMessages = false.obs;

  // Settings service
  late final NotificationSettingsService _settingsService;

  @override
  void onInit() {
    super.onInit();
    _initializeSettingsService();
    _initializeNotificationHandling();
    _setupAuthStateListener();
  }

  /// Initialize settings service
  void _initializeSettingsService() {
    try {
      _settingsService = Get.find<NotificationSettingsService>();
      debugPrint('Notification settings service found');
    } catch (e) {
      _settingsService =
          Get.put(NotificationSettingsService(), permanent: true);
      debugPrint('Notification settings service created');
    }
  }

  /// Setup authentication state listener
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('User authenticated: ${user.uid}');
        // User is logged in, setup in-app message listeners
        _loadInAppMessages();
        _setupInAppMessageListener();
      } else {
        debugPrint('User logged out');
        // User logged out, clear messages
        inAppMessages.clear();
        hasUnreadMessages.value = false;
      }
    });
  }

  /// Initialize all notification handling
  Future<void> _initializeNotificationHandling() async {
    try {
      debugPrint('Initializing notification handling...');

      // 1. Setup FCM message handlers
      await _setupFCMHandlers();

      // 2. Setup Awesome Notifications
      await _setupAwesomeNotifications();

      // 3. Load existing in-app messages for current user (if authenticated)
      final user = _auth.currentUser;
      if (user != null) {
        await _loadInAppMessages();
        _setupInAppMessageListener();
      }

      debugPrint('Notification handling initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification handling: $e');
    }
  }

  /// Setup FCM message handlers
  Future<void> _setupFCMHandlers() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Handle initial message if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleMessageTap(initialMessage);
      }

      debugPrint('FCM handlers setup complete');
    } catch (e) {
      debugPrint('Error setting up FCM handlers: $e');
    }
  }

  /// Setup Awesome Notifications
  Future<void> _setupAwesomeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: 'push_notifications',
            channelName: 'Push Notifications',
            channelDescription: 'Channel for push notifications',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: _settingsService.notificationSound.value,
            enableVibration: _settingsService.notificationVibration.value,
          ),
          NotificationChannel(
            channelKey: 'in_app_messages',
            channelName: 'In-App Messages',
            channelDescription: 'Channel for in-app messages',
            defaultColor: const Color(0xFF2196F3),
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            playSound: _settingsService.notificationSound.value,
            enableVibration: _settingsService.notificationVibration.value,
          ),
        ],
        debug: kDebugMode,
      );

      // Listen for notification actions
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onNotificationActionReceived,
        onNotificationCreatedMethod: _onNotificationCreated,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
        onDismissActionReceivedMethod: _onNotificationDismissed,
      );

      debugPrint('Awesome Notifications setup complete');
    } catch (e) {
      debugPrint('Error setting up Awesome Notifications: $e');
    }
  }

  /// Handle foreground FCM messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Received foreground message: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Check if notifications are allowed
      if (!_settingsService.areNotificationsAllowed) {
        debugPrint('Notifications disabled, ignoring message');
        return;
      }

      // Check category filtering
      final category = message.data['category'] ?? 'general';
      if (!_settingsService.isCategoryAllowed(category)) {
        debugPrint('Category $category not allowed, ignoring message');
        return;
      }

      // Show notification using Awesome Notifications
      await _showPushNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        data: message.data,
        imageUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
      );
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handle message tap (when app is opened from notification)
  Future<void> _handleMessageTap(RemoteMessage message) async {
    try {
      debugPrint('Message tapped: ${message.messageId}');
      debugPrint('Data: ${message.data}');

      // Handle different types of notifications
      final data = message.data;
      final actionUrl = data['action_url'];
      final actionTitle = data['action_title'];

      if (actionUrl != null && actionUrl.isNotEmpty) {
        // Navigate to specific page or open URL
        await _handleNotificationAction(actionTitle, actionUrl);
      } else {
        // Default action - could navigate to a notifications page
        debugPrint('No specific action defined');
      }
    } catch (e) {
      debugPrint('Error handling message tap: $e');
    }
  }

  /// Show push notification using Awesome Notifications
  Future<void> _showPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'push_notifications',
          title: title,
          body: body,
          bigPicture: imageUrl,
          notificationLayout: imageUrl != null
              ? NotificationLayout.BigPicture
              : NotificationLayout.Default,
          payload: data != null
              ? Map<String, String?>.from(
                  data.map((k, v) => MapEntry(k, v?.toString())))
              : null,
          // Note: Sound and vibration are controlled by the notification channel
          // These settings are applied when creating the notification channel
        ),
      );
    } catch (e) {
      debugPrint('Error showing push notification: $e');
    }
  }

  /// Load in-app messages for current user
  Future<void> _loadInAppMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('in_app_messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final messages =
          snapshot.docs.map((doc) => InAppMessage.fromFirestore(doc)).toList();

      inAppMessages.value = messages;
      _updateUnreadStatus();

      debugPrint('Loaded ${messages.length} in-app messages');
    } catch (e) {
      debugPrint('Error loading in-app messages: $e');
    }
  }

  /// Setup real-time listener for in-app messages
  void _setupInAppMessageListener() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(
          'Cannot setup in-app message listener: User not authenticated');
      return;
    }

    debugPrint('Setting up in-app message listener for user: ${user.uid}');

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('in_app_messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final messages =
          snapshot.docs.map((doc) => InAppMessage.fromFirestore(doc)).toList();

      inAppMessages.value = messages;
      _updateUnreadStatus();

      // Show new messages as in-app notifications
      _showNewInAppMessages(snapshot.docChanges);
    });
  }

  /// Show new in-app messages as notifications
  void _showNewInAppMessages(List<DocumentChange> changes) {
    for (final change in changes) {
      if (change.type == DocumentChangeType.added) {
        final message = InAppMessage.fromFirestore(change.doc);
        debugPrint('New in-app message received: ${message.title}');

        // Check if in-app messages are allowed
        if (!_settingsService.areInAppMessagesAllowed) {
          debugPrint('In-app messages disabled, ignoring message');
          continue;
        }

        // Check if auto-show is enabled
        if (!_settingsService.autoShowMessages.value) {
          debugPrint('Auto-show disabled, not displaying message');
          continue;
        }

        // Check if message is new (created within last 5 seconds)
        if (!_isNewMessage(message)) {
          debugPrint('Message is too old, not displaying: ${message.title}');
          continue;
        }

        // Check category filtering
        final category = message.customData?['category'] ?? 'general';
        if (!_settingsService.isCategoryAllowed(category)) {
          debugPrint('Category $category not allowed, ignoring message');
          continue;
        }

        // Show as in-app notification using GlassAlertDialog
        _showInAppMessageDialog(message);
      }
    }
  }

  // Check if message is new (created within last 5 seconds)
  bool _isNewMessage(InAppMessage message) {
    final now = DateTime.now();
    final messageTime = message.createdAt;
    final timeDiff = now.difference(messageTime).inSeconds;
    return timeDiff <= 5;
  }

  // Track recently shown messages to prevent duplicates
  final Map<String, DateTime> _recentlyShownMessages = {};

  bool _wasMessageRecentlyShown(String messageId) {
    final now = DateTime.now();
    final shownTime = _recentlyShownMessages[messageId];

    if (shownTime == null) return false;

    final timeDiff = now.difference(shownTime).inSeconds;
    return timeDiff <= 5; // Consider shown if within last 5 seconds
  }

  // Mark message as shown
  void _markMessageAsShown(String messageId) {
    _recentlyShownMessages[messageId] = DateTime.now();

    // Clean up old entries (older than 1 minute)
    final now = DateTime.now();
    _recentlyShownMessages.removeWhere((key, value) {
      return now.difference(value).inMinutes > 1;
    });
  }

  void _showInAppMessageDialog(InAppMessage message) {
    try {
      if (!_settingsService.areInAppMessagesAllowed) {
        debugPrint('In-app messages disabled, skipping: ${message.title}');
        return;
      }

      if (Get.isDialogOpen == true) {
        debugPrint('Dialog already open, skipping: ${message.title}');
        return;
      }

      if (_wasMessageRecentlyShown(message.id)) {
        debugPrint(
            'Message already shown recently, skipping: ${message.title}');
        return;
      }

      debugPrint('Showing in-app message dialog: ${message.title}');

      // Get the current context
      final context = Get.context;
      if (context == null) {
        debugPrint('No context available to show dialog');
        return;
      }

      // Mark message as shown
      _markMessageAsShown(message.id);

      // Show the dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => InAppMessageDialog(
          message: message,
          onActionPressed: () {
            debugPrint('In-app message action pressed: ${message.actionTitle}');
          },
          onDismiss: () {
            debugPrint('In-app message dialog dismissed');
          },
        ),
      );

      debugPrint('In-app message dialog shown successfully');
    } catch (e) {
      debugPrint('Error showing in-app message dialog: $e');
    }
  }

  void _updateUnreadStatus() {
    final unreadCount =
        inAppMessages.where((message) => !message.isRead).length;
    hasUnreadMessages.value = unreadCount > 0;
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('in_app_messages')
          .doc(messageId)
          .update({'isRead': true});

      // Update local list
      final index = inAppMessages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        inAppMessages[index] = inAppMessages[index].copyWith(isRead: true);
        _updateUnreadStatus();
      }

      debugPrint('Message marked as read: $messageId');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final unreadMessages = inAppMessages.where((msg) => !msg.isRead).toList();

      for (final message in unreadMessages) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('in_app_messages')
            .doc(message.id)
            .update({'isRead': true});
      }

      // Update local list
      for (int i = 0; i < inAppMessages.length; i++) {
        inAppMessages[i] = inAppMessages[i].copyWith(isRead: true);
      }

      _updateUnreadStatus();
      debugPrint('All messages marked as read');
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('in_app_messages')
          .doc(messageId)
          .delete();

      // Update local state
      inAppMessages.removeWhere((m) => m.id == messageId);
      _updateUnreadStatus();

      debugPrint('Message deleted: $messageId');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> _handleNotificationAction(
      String? actionTitle, String actionUrl) async {
    try {
      debugPrint('Handling notification action: $actionTitle -> $actionUrl');

      if (actionUrl.startsWith('http')) {
        try {
          final uri = Uri.parse(actionUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            debugPrint('Opening external URL: $actionUrl');
          } else {
            debugPrint('Could not launch URL: $actionUrl');
          }
        } catch (e) {
          debugPrint('Error launching URL: $e');
        }
      } else {
        debugPrint('Navigating to: $actionUrl');
        Get.toNamed(actionUrl);
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  /// Awesome Notifications event handlers
  static Future<void> _onNotificationActionReceived(
      ReceivedAction action) async {
    try {
      debugPrint('Notification action received: ${action.id}');
      debugPrint('Action data: ${action.payload}');

      final payload = action.payload ?? {};
      final messageId = payload['messageId'];
      final type = payload['type'];
      final actionUrl = payload['actionUrl'];
      final actionTitle = payload['actionTitle'];
      final actionKey = action.buttonKeyPressed;

      if (type == 'sleep_timer' || type == 'sleep_timer_countdown') {
        final service = Get.find<NotificationHandlerService>();
        await service._handleSleepTimerAction(actionKey);
        return;
      }

      if (type == 'in_app_message' && messageId != null) {
        final service = Get.find<NotificationHandlerService>();
        await service.markMessageAsRead(messageId);
      }

      if (actionUrl != null && actionUrl.isNotEmpty) {
        final service = Get.find<NotificationHandlerService>();
        await service._handleNotificationAction(actionTitle, actionUrl);
      }
    } catch (e) {
      debugPrint('Error in notification action handler: $e');
    }
  }

  static Future<void> _onNotificationCreated(
      ReceivedNotification notification) async {
    debugPrint('Notification created: ${notification.id}');
  }

  static Future<void> _onNotificationDisplayed(
      ReceivedNotification notification) async {
    debugPrint('Notification displayed: ${notification.id}');
  }

  static Future<void> _onNotificationDismissed(ReceivedAction action) async {
    debugPrint('Notification dismissed: ${action.id}');
  }

  /// Get unread message count
  int get unreadCount => inAppMessages.where((msg) => !msg.isRead).length;

  /// Check if there are unread messages
  bool get hasUnread => hasUnreadMessages.value;

  void showInAppMessageDialog(InAppMessage message) {
    if (!_settingsService.areInAppMessagesAllowed) {
      debugPrint('In-app messages disabled, skipping: ${message.title}');
      return;
    }
    _showInAppMessageDialog(message);
  }

  /// Show all unread messages as dialogs
  void showUnreadMessages() {
    final unreadMessages = inAppMessages.where((msg) => !msg.isRead).toList();
    if (unreadMessages.isNotEmpty) {
      // Show the first unread message
      _showInAppMessageDialog(unreadMessages.first);
    }
  }

  void showLatestMessage() {
    if (inAppMessages.isNotEmpty) {
      _showInAppMessageDialog(inAppMessages.first);
    }
  }

  void debugCurrentState() {
    final user = _auth.currentUser;
    debugPrint('Notification Handler Debug State:');
    debugPrint('User authenticated: ${user != null}');
    debugPrint('User ID: ${user?.uid ?? 'null'}');
    debugPrint('Total messages: ${inAppMessages.length}');
    debugPrint('Unread messages: $unreadCount');
    debugPrint('Has unread: ${hasUnreadMessages.value}');
  }

  Future<void> _handleSleepTimerAction(String? actionKey) async {
    try {
      debugPrint('Sleep timer action received: $actionKey');

      if (actionKey == 'restart_timer') {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.restartSleepTimer();

        debugPrint('Sleep timer restarted');
      } else if (actionKey == 'stop_timer') {
        try {
          final sleepTimerService = Get.find<SleepTimerService>();
          sleepTimerService.stopTimer();
          debugPrint('Sleep timer stopped from notification');
        } catch (e) {
          debugPrint('Error stopping sleep timer: $e');
        }
      } else if (actionKey == 'dismiss') {
        debugPrint('Sleep timer notification dismissed');
      }
    } catch (e) {
      debugPrint('Error handling sleep timer action: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
