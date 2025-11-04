import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import '../data/services/notification_handler_service.dart';
import '../data/services/notification_settings_service.dart';

class NotificationSettingsController extends GetxController {
  final NotificationHandlerService _notificationService =
      Get.find<NotificationHandlerService>();
  final NotificationSettingsService _settingsService =
      Get.find<NotificationSettingsService>();

  // Local state for UI updates
  late RxBool pushNotificationsEnabled;
  late RxBool inAppMessagesEnabled;
  late RxBool notificationSound;
  late RxBool notificationVibration;
  late RxBool autoShowMessages;
  late RxBool sleepTimerNotifications;
  late RxBool quietHoursEnabled;
  late Rx<TimeOfDay> quietStartTime;
  late Rx<TimeOfDay> quietEndTime;

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  void _initializeSettings() {
    // Initialize reactive variables
    pushNotificationsEnabled = _settingsService.pushNotificationsEnabled;
    inAppMessagesEnabled = _settingsService.inAppMessagesEnabled;
    notificationSound = _settingsService.notificationSound;
    notificationVibration = _settingsService.notificationVibration;
    autoShowMessages = _settingsService.autoShowMessages;
    sleepTimerNotifications = _settingsService.sleepTimerNotifications;
    quietHoursEnabled = _settingsService.quietHoursEnabled;
    quietStartTime = Rx<TimeOfDay>(TimeOfDay(
      hour: _settingsService.quietStartHour.value,
      minute: _settingsService.quietStartMinute.value,
    ));
    quietEndTime = Rx<TimeOfDay>(TimeOfDay(
      hour: _settingsService.quietEndHour.value,
      minute: _settingsService.quietEndMinute.value,
    ));

    // Listen to settings changes and update local state
    _settingsService.quietStartHour.listen((hour) {
      quietStartTime.value = TimeOfDay(
        hour: hour,
        minute: _settingsService.quietStartMinute.value,
      );
    });

    _settingsService.quietStartMinute.listen((minute) {
      quietStartTime.value = TimeOfDay(
        hour: _settingsService.quietStartHour.value,
        minute: minute,
      );
    });

    _settingsService.quietEndHour.listen((hour) {
      quietEndTime.value = TimeOfDay(
        hour: hour,
        minute: _settingsService.quietEndMinute.value,
      );
    });

    _settingsService.quietEndMinute.listen((minute) {
      quietEndTime.value = TimeOfDay(
        hour: _settingsService.quietEndHour.value,
        minute: minute,
      );
    });
  }

  // Toggle methods that update both local state and settings service
  void togglePushNotifications(bool value) {
    pushNotificationsEnabled.value = value;
    _settingsService.pushNotificationsEnabled.value = value;
    _settingsService.saveSettings();
  }

  void toggleInAppMessages(bool value) {
    inAppMessagesEnabled.value = value;
    _settingsService.inAppMessagesEnabled.value = value;
    _settingsService.saveSettings();
  }

  void toggleNotificationSound(bool value) {
    notificationSound.value = value;
    _settingsService.notificationSound.value = value;
    _settingsService.saveSettings();
  }

  void toggleNotificationVibration(bool value) {
    notificationVibration.value = value;
    _settingsService.notificationVibration.value = value;
    _settingsService.saveSettings();
  }

  void toggleAutoShowMessages(bool value) {
    autoShowMessages.value = value;
    _settingsService.autoShowMessages.value = value;
    _settingsService.saveSettings();
  }

  void toggleSleepTimerNotifications(bool value) {
    sleepTimerNotifications.value = value;
    _settingsService.sleepTimerNotifications.value = value;
    _settingsService.saveSettings();
  }

  void toggleQuietHours(bool value) {
    quietHoursEnabled.value = value;
    _settingsService.quietHoursEnabled.value = value;
    _settingsService.saveSettings();
  }

  Future<void> selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? quietStartTime.value : quietEndTime.value,
    );

    if (picked != null) {
      if (isStartTime) {
        quietStartTime.value = picked;
        _settingsService.quietStartHour.value = picked.hour;
        _settingsService.quietStartMinute.value = picked.minute;
      } else {
        quietEndTime.value = picked;
        _settingsService.quietEndHour.value = picked.hour;
        _settingsService.quietEndMinute.value = picked.minute;
      }
      _settingsService.saveSettings();
    }
  }

  void showTestMessage() {
    // Check if in-app messages are actually enabled
    if (!_settingsService.areInAppMessagesAllowed) {
      Get.snackbar(
        'In-App Messages Disabled',
        'Please enable in-app messages to test notifications',
        snackPosition: SnackPosition.bottom,
      );
      return;
    }

    final message = InAppMessage(
      id: 'test_settings',
      title: 'Test Notification',
      body:
          'This is how your in-app messages will look with the current settings.',
      createdAt: DateTime.now(),
      isRead: false,
      customData: {'category': 'system_alerts'},
    );

    _notificationService.showInAppMessageDialog(message);
  }

  Future<void> saveSettings() async {
    await _settingsService.saveSettings();
    Get.snackbar(
      'Settings Saved',
      'Your notification preferences have been updated',
      snackPosition: SnackPosition.bottom,
    );
    Get.back();
  }

  // Getters for UI - return RxBool for reactive UI
  RxBool get isPushNotificationsEnabled => pushNotificationsEnabled;
  RxBool get isInAppMessagesEnabled => inAppMessagesEnabled;
  RxBool get isNotificationSoundEnabled => notificationSound;
  RxBool get isNotificationVibrationEnabled => notificationVibration;
  RxBool get isAutoShowMessagesEnabled => autoShowMessages;
  RxBool get isSleepTimerNotificationsEnabled => sleepTimerNotifications;
  RxBool get isQuietHoursEnabled => quietHoursEnabled;
  Rx<TimeOfDay> get quietStart => quietStartTime;
  Rx<TimeOfDay> get quietEnd => quietEndTime;
}
