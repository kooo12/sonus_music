import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player/app/data/services/audio_service.dart';
import 'package:music_player/app/data/services/notification_handler_service.dart';
import 'package:music_player/app/data/services/notification_settings_service.dart';

class SleepTimerService extends GetxService {
  final audioService = Get.find<AudioPlayerService>();
  final notificationService = Get.find<NotificationHandlerService>();
  final settingsService = Get.find<NotificationSettingsService>();

  Timer? _timer;
  Timer? _notificationUpdateTimer;
  final RxBool _isActive = false.obs;
  final RxInt _remainingSeconds = 0.obs;
  final RxInt _totalSeconds = 0.obs;
  final RxInt _lastSelectedMinutes = 15.obs; // Default to 15 minutes
  static const int _sleepTimerNotificationId =
      9999; // Unique ID for sleep timer notification
  int?
      _lastNotificationMinutes; // Track last notification minutes to avoid unnecessary updates

  // Getters
  bool get isActive => _isActive.value;
  int get remainingSeconds => _remainingSeconds.value;
  int get totalSeconds => _totalSeconds.value;
  int get lastSelectedMinutes => _lastSelectedMinutes.value;

  // Observable getters for UI
  RxBool get isActiveObs => _isActive;
  RxInt get remainingSecondsObs => _remainingSeconds;
  RxInt get totalSecondsObs => _totalSeconds;
  RxInt get lastSelectedMinutesObs => _lastSelectedMinutes;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadLastSelectedDuration();
  }

  // Get formatted time string (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds.value ~/ 60;
    final seconds = _remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_totalSeconds.value == 0) return 0.0;
    return 1.0 - (_remainingSeconds.value / _totalSeconds.value);
  }

  // Start sleep timer with duration in minutes
  void startTimer(int minutes) {
    if (minutes <= 0) return;

    _stopTimer(); // Stop any existing timer

    _totalSeconds.value = minutes * 60;
    _remainingSeconds.value = _totalSeconds.value;
    _isActive.value = true;

    // Save the selected duration
    _saveLastSelectedDuration(minutes);

    // Show sleep timer countdown notification
    _showSleepTimerCountdownNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--;
      } else {
        _stopMusicAndTimer();
      }
    });

    // Update notification every 30 seconds for better performance
    // _notificationUpdateTimer =
    //     Timer.periodic(const Duration(seconds: 30), (timer) {
    //   _updateSleepTimerNotification();
    // });

    debugPrint('Sleep timer started for $minutes minutes');
  }

  // Stop the sleep timer
  void stopTimer() {
    _stopTimer();
    debugPrint('Sleep timer stopped');
  }

  // Private method to stop timer and reset values
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
    _isActive.value = false;
    _remainingSeconds.value = 0;
    _totalSeconds.value = 0;

    // Cancel sleep timer notification
    _cancelSleepTimerNotification();
  }

  // Stop music and timer when time is up
  void _stopMusicAndTimer() {
    try {
      // Get audio service and pause music
      audioService.audioPlayer.pause();
      debugPrint('Music stopped by sleep timer');

      // Show sleep timer notification if enabled
      if (settingsService.sleepTimerNotifications.value) {
        _showSleepTimerNotification();
      }
    } catch (e) {
      debugPrint('Error stopping music: $e');
    }

    _stopTimer();
  }

  // Show sleep timer push notification
  Future<void> _showSleepTimerNotification() async {
    try {
      // Check if sleep timer notifications are enabled
      if (!settingsService.sleepTimerNotifications.value) {
        debugPrint('Sleep timer notifications disabled, skipping notification');
        return;
      }

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'music_channel',
          title: 'Sleep Timer Complete'.tr,
          body: 'Your sleep timer has ended and music has been paused.'.tr,
          category: NotificationCategory.Reminder,
          payload: {
            'type': 'sleep_timer',
            'action': 'timer_complete',
          },
          notificationLayout: NotificationLayout.Default,
          autoDismissible: true,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'restart_timer',
            label: 'Restart Timer'.tr,
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'dismiss',
            label: 'Dismiss'.tr,
            autoDismissible: true,
          ),
        ],
      );

      debugPrint('Sleep timer push notification shown');
    } catch (e) {
      debugPrint('Error showing sleep timer push notification: $e');
    }
  }

  // Add time to existing timer (in minutes)
  void addTime(int minutes) {
    if (!_isActive.value) return;

    final additionalSeconds = minutes * 60;
    _remainingSeconds.value += additionalSeconds;
    _totalSeconds.value += additionalSeconds;

    // Update the persistent notification immediately when time is added
    // _updateSleepTimerNotification();

    debugPrint('Added $minutes minutes to sleep timer');
  }

  // Get remaining time in minutes
  int get remainingMinutes => (_remainingSeconds.value / 60).ceil();

  // Load last selected duration from SharedPreferences
  Future<void> _loadLastSelectedDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMinutes =
          prefs.getInt('sleep_timer_last_selected_minutes') ?? 15;
      _lastSelectedMinutes.value = lastMinutes;
      debugPrint(
          'Loaded last selected sleep timer duration: $lastMinutes minutes');
    } catch (e) {
      debugPrint('Error loading last selected duration: $e');
    }
  }

  // Save last selected duration to SharedPreferences
  Future<void> _saveLastSelectedDuration(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sleep_timer_last_selected_minutes', minutes);
      _lastSelectedMinutes.value = minutes;
      debugPrint('Saved last selected sleep timer duration: $minutes minutes');
    } catch (e) {
      debugPrint('Error saving last selected duration: $e');
    }
  }

  // Show sleep timer countdown notification
  Future<void> _showSleepTimerCountdownNotification() async {
    try {
      // Check if sleep timer notifications are enabled
      if (!settingsService.sleepTimerNotifications.value) {
        debugPrint(
            'Sleep timer notifications disabled, skipping countdown notification');
        return;
      }

      final minutes = _remainingSeconds.value ~/ 60;
      final seconds = _remainingSeconds.value % 60;
      final timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _sleepTimerNotificationId,
          channelKey: 'sleep_timer',
          title: 'Sleep Timer Active'.tr,
          body: '${"Set Time".tr}: $timeText ${"minutes".tr}',
          category: NotificationCategory.Reminder,
          payload: {
            'type': 'sleep_timer_countdown',
            'action': 'timer_running',
          },
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'stop_timer',
            label: 'Stop Timer'.tr,
            autoDismissible: false,
          ),
        ],
      );

      debugPrint('Sleep timer countdown notification shown');
    } catch (e) {
      debugPrint('Error showing sleep timer countdown notification: $e');
    }
  }

  // Update sleep timer countdown notification
  Future<void> _updateSleepTimerNotification() async {
    try {
      if (!_isActive.value) return;

      // Check if sleep timer notifications are enabled
      if (!settingsService.sleepTimerNotifications.value) {
        debugPrint('Sleep timer notifications disabled, skipping update');
        return;
      }

      final minutes = _remainingSeconds.value ~/ 60;
      final seconds = _remainingSeconds.value % 60;
      final timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      // Only update if minutes have changed (to avoid unnecessary updates)
      if (_lastNotificationMinutes == minutes) return;
      _lastNotificationMinutes = minutes;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _sleepTimerNotificationId,
          channelKey: 'sleep_timer',
          title: 'Sleep Timer Active',
          body: 'Set Time: $timeText',
          category: NotificationCategory.Reminder,
          payload: {
            'type': 'sleep_timer_countdown',
            'action': 'timer_running',
          },
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'stop_timer',
            label: 'Stop Timer',
            autoDismissible: false,
          ),
        ],
      );

      debugPrint('Sleep timer countdown notification updated: $timeText');
    } catch (e) {
      debugPrint('Error updating sleep timer countdown notification: $e');
    }
  }

  // Cancel sleep timer countdown notification
  Future<void> _cancelSleepTimerNotification() async {
    try {
      await AwesomeNotifications().cancel(_sleepTimerNotificationId);
      debugPrint('Sleep timer countdown notification cancelled');
    } catch (e) {
      debugPrint('Error cancelling sleep timer countdown notification: $e');
    }
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}
