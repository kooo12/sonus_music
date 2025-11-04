import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationSettingsService extends GetxService {
  static const String _keyPushNotifications = 'push_notifications_enabled';
  static const String _keyInAppMessages = 'in_app_messages_enabled';
  static const String _keyNotificationSound = 'notification_sound_enabled';
  static const String _keyNotificationVibration =
      'notification_vibration_enabled';
  static const String _keyAutoShowMessages = 'auto_show_messages_enabled';
  static const String _keyMusicUpdates = 'music_updates_enabled';
  static const String _keyAppUpdates = 'app_updates_enabled';
  static const String _keyPromotional = 'promotional_enabled';
  static const String _keySystemAlerts = 'system_alerts_enabled';
  static const String _keySleepTimerNotifications =
      'sleep_timer_notifications_enabled';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';
  static const String _keyQuietStartHour = 'quiet_start_hour';
  static const String _keyQuietStartMinute = 'quiet_start_minute';
  static const String _keyQuietEndHour = 'quiet_end_hour';
  static const String _keyQuietEndMinute = 'quiet_end_minute';

  // Observable settings
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool inAppMessagesEnabled = true.obs;
  final RxBool notificationSound = true.obs;
  final RxBool notificationVibration = true.obs;
  final RxBool autoShowMessages = true.obs;
  final RxBool musicUpdates = true.obs;
  final RxBool appUpdates = true.obs;
  final RxBool promotional = false.obs;
  final RxBool systemAlerts = true.obs;
  final RxBool sleepTimerNotifications = true.obs;
  final RxBool quietHoursEnabled = false.obs;
  final RxInt quietStartHour = 22.obs;
  final RxInt quietStartMinute = 0.obs;
  final RxInt quietEndHour = 7.obs;
  final RxInt quietEndMinute = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      pushNotificationsEnabled.value =
          prefs.getBool(_keyPushNotifications) ?? true;
      inAppMessagesEnabled.value = prefs.getBool(_keyInAppMessages) ?? true;
      notificationSound.value = prefs.getBool(_keyNotificationSound) ?? true;
      notificationVibration.value =
          prefs.getBool(_keyNotificationVibration) ?? true;
      autoShowMessages.value = prefs.getBool(_keyAutoShowMessages) ?? true;
      musicUpdates.value = prefs.getBool(_keyMusicUpdates) ?? true;
      appUpdates.value = prefs.getBool(_keyAppUpdates) ?? true;
      promotional.value = prefs.getBool(_keyPromotional) ?? false;
      systemAlerts.value = prefs.getBool(_keySystemAlerts) ?? true;
      sleepTimerNotifications.value =
          prefs.getBool(_keySleepTimerNotifications) ?? true;
      quietHoursEnabled.value = prefs.getBool(_keyQuietHoursEnabled) ?? false;
      quietStartHour.value = prefs.getInt(_keyQuietStartHour) ?? 22;
      quietStartMinute.value = prefs.getInt(_keyQuietStartMinute) ?? 0;
      quietEndHour.value = prefs.getInt(_keyQuietEndHour) ?? 7;
      quietEndMinute.value = prefs.getInt(_keyQuietEndMinute) ?? 0;

      debugPrint('Notification settings loaded successfully');
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
          _keyPushNotifications, pushNotificationsEnabled.value);
      await prefs.setBool(_keyInAppMessages, inAppMessagesEnabled.value);
      await prefs.setBool(_keyNotificationSound, notificationSound.value);
      await prefs.setBool(
          _keyNotificationVibration, notificationVibration.value);
      await prefs.setBool(_keyAutoShowMessages, autoShowMessages.value);
      await prefs.setBool(_keyMusicUpdates, musicUpdates.value);
      await prefs.setBool(_keyAppUpdates, appUpdates.value);
      await prefs.setBool(_keyPromotional, promotional.value);
      await prefs.setBool(_keySystemAlerts, systemAlerts.value);
      await prefs.setBool(
          _keySleepTimerNotifications, sleepTimerNotifications.value);
      await prefs.setBool(_keyQuietHoursEnabled, quietHoursEnabled.value);
      await prefs.setInt(_keyQuietStartHour, quietStartHour.value);
      await prefs.setInt(_keyQuietStartMinute, quietStartMinute.value);
      await prefs.setInt(_keyQuietEndHour, quietEndHour.value);
      await prefs.setInt(_keyQuietEndMinute, quietEndMinute.value);

      debugPrint('Notification settings saved successfully');
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Check if notifications are allowed based on all settings
  bool get areNotificationsAllowed {
    // Check if push notifications are enabled
    if (!pushNotificationsEnabled.value) return false;

    // Check quiet hours
    if (quietHoursEnabled.value && _isInQuietHours()) return false;

    return true;
  }

  /// Check if in-app messages are allowed
  bool get areInAppMessagesAllowed {
    return inAppMessagesEnabled.value && areNotificationsAllowed;
  }

  /// Check if a specific notification category is allowed
  bool isCategoryAllowed(String category) {
    if (!areNotificationsAllowed) return false;

    switch (category.toLowerCase()) {
      case 'music_updates':
        return musicUpdates.value;
      case 'app_updates':
        return appUpdates.value;
      case 'promotional':
        return promotional.value;
      case 'system_alerts':
        return systemAlerts.value;
      case 'sleep_timer':
        return sleepTimerNotifications.value;
      default:
        return true; // Allow unknown categories by default
    }
  }

  /// Check if we're currently in quiet hours
  bool _isInQuietHours() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    final startTime = quietStartHour.value * 60 + quietStartMinute.value;
    final endTime = quietEndHour.value * 60 + quietEndMinute.value;

    // Handle quiet hours that cross midnight
    if (startTime > endTime) {
      return currentTime >= startTime || currentTime < endTime;
    } else {
      return currentTime >= startTime && currentTime < endTime;
    }
  }

  /// Get quiet hours status text
  String get quietHoursStatus {
    if (!quietHoursEnabled.value) return 'Disabled';

    final startTime =
        '${quietStartHour.value.toString().padLeft(2, '0')}:${quietStartMinute.value.toString().padLeft(2, '0')}';
    final endTime =
        '${quietEndHour.value.toString().padLeft(2, '0')}:${quietEndMinute.value.toString().padLeft(2, '0')}';

    return 'Enabled ($startTime - $endTime)';
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    pushNotificationsEnabled.value = true;
    inAppMessagesEnabled.value = true;
    notificationSound.value = true;
    notificationVibration.value = true;
    autoShowMessages.value = true;
    musicUpdates.value = true;
    appUpdates.value = true;
    promotional.value = false;
    systemAlerts.value = true;
    sleepTimerNotifications.value = true;
    quietHoursEnabled.value = false;
    quietStartHour.value = 22;
    quietStartMinute.value = 0;
    quietEndHour.value = 7;
    quietEndMinute.value = 0;

    await saveSettings();
    debugPrint('Notification settings reset to defaults');
  }

  /// Update quiet hours
  void updateQuietHours({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    quietStartHour.value = startHour;
    quietStartMinute.value = startMinute;
    quietEndHour.value = endHour;
    quietEndMinute.value = endMinute;
  }

  /// Debug method to print current settings
  void debugSettings() {
    debugPrint('Notification Settings Debug:');
    debugPrint('Push Notifications: ${pushNotificationsEnabled.value}');
    debugPrint('In-App Messages: ${inAppMessagesEnabled.value}');
    debugPrint('Notification Sound: ${notificationSound.value}');
    debugPrint('Notification Vibration: ${notificationVibration.value}');
    debugPrint('Auto Show Messages: ${autoShowMessages.value}');
    debugPrint('Music Updates: ${musicUpdates.value}');
    debugPrint('App Updates: ${appUpdates.value}');
    debugPrint('Promotional: ${promotional.value}');
    debugPrint('System Alerts: ${systemAlerts.value}');
    debugPrint('Sleep Timer: ${sleepTimerNotifications.value}');
    debugPrint('Quiet Hours: $quietHoursStatus');
    debugPrint('Notifications Allowed: $areNotificationsAllowed');
    debugPrint('In-App Messages Allowed: $areInAppMessagesAllowed');
  }
}
