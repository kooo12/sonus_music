import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:music_player/app/data/services/production_notification_service.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';

class EnhancedNotificationController extends GetxController {
  final ProductionNotificationService _notificationService =
      Get.find<ProductionNotificationService>();

  // Form controllers
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final imageUrlController = TextEditingController();
  final actionUrlController = TextEditingController();
  final actionTitleController = TextEditingController();
  final soundController = TextEditingController(text: 'default');
  final priorityController = TextEditingController(text: 'high');
  final ttlController = TextEditingController(text: '86400'); // 24 hours

  // Notification type
  final RxString notificationType = 'push'.obs; // 'push' or 'in_app'

  // Additional data fields
  final RxMap<String, String> customData = <String, String>{}.obs;
  final dataKeyController = TextEditingController();
  final dataValueController = TextEditingController();

  // UI state
  final RxBool isLoading = false.obs;
  final RxString lastResult = ''.obs;
  final Rx<NotificationStats?> stats = Rx<NotificationStats?>(null);

  @override
  void onInit() {
    super.onInit();
    refreshStats(); // Load stats on initialization
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    imageUrlController.dispose();
    actionUrlController.dispose();
    actionTitleController.dispose();
    soundController.dispose();
    priorityController.dispose();
    ttlController.dispose();
    dataKeyController.dispose();
    dataValueController.dispose();
    super.onClose();
  }

  void setNotificationType(String type) {
    notificationType.value = type;
  }

  void addCustomData() {
    final key = dataKeyController.text.trim();
    final value = dataValueController.text.trim();

    if (key.isNotEmpty && value.isNotEmpty) {
      customData[key] = value;
      dataKeyController.clear();
      dataValueController.clear();
    } else {
      TpsLoader.customToast(
          message: 'Custom data key and value cannot be empty.');
    }
  }

  void removeCustomData(String key) {
    customData.remove(key);
  }

  Future<void> refreshStats() async {
    try {
      final fetchedStats = await _notificationService.getNotificationStats();
      stats.value = fetchedStats;
    } catch (e) {
      debugPrint('Error loading notification stats: $e');
      TpsLoader.customToast(message: 'Failed to load notification stats: $e');
    }
  }

  Future<void> sendNotification(String targetType) async {
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      TpsLoader.customToast(message: 'Title and body are required');
      return;
    }

    isLoading.value = true;
    lastResult.value = ''; // Clear previous result

    try {
      final notificationData = {
        'title': titleController.text.trim(),
        'body': bodyController.text.trim(),
        'imageUrl': imageUrlController.text.trim().isNotEmpty
            ? imageUrlController.text.trim()
            : null,
        'actionTitle': actionTitleController.text.trim().isNotEmpty
            ? actionTitleController.text.trim()
            : null,
        'actionUrl': actionUrlController.text.trim().isNotEmpty
            ? actionUrlController.text.trim()
            : null,
        'sound': soundController.text.trim(),
        'priority': priorityController.text.trim(),
        'ttl': int.tryParse(ttlController.text.trim()) ?? 86400,
        'customData': customData.value,
      };

      NotificationSendResult sendResult;

      if (notificationType.value == 'push') {
        // Send push notification
        sendResult = await _notificationService.sendPushNotification(
          title: notificationData['title'] as String,
          body: notificationData['body'] as String,
          imageUrl: notificationData['imageUrl'] != null
              ? notificationData['imageUrl'] as String
              : '',
          actionTitle: notificationData['actionTitle'] != null
              ? notificationData['actionTitle'] as String
              : '',
          actionUrl: notificationData['actionUrl'] != null
              ? notificationData['actionUrl'] as String
              : '', //notificationData['actionUrl'] as String,
          sound: notificationData['sound'] != null &&
                  (notificationData['sound'] as String).isNotEmpty
              ? notificationData['sound'] as String
              : 'default',
          priority: notificationData['priority'] != null &&
                  (notificationData['priority'] as String).isNotEmpty
              ? notificationData['priority'] as String
              : 'high',
          ttl: notificationData['ttl'] != null &&
                  (notificationData['ttl'] as int) > 0
              ? notificationData['ttl'] as int
              : 86400,
          customData: notificationData['customData'] != null
              ? notificationData['customData'] as Map<String, String>
              : {},
          notificationType: targetType,
        );
      } else {
        // Send in-app message
        sendResult = await _notificationService.sendInAppMessage(
          title: notificationData['title'] as String,
          body: notificationData['body'] as String,
          imageUrl: notificationData['imageUrl'] != null
              ? notificationData['imageUrl'] as String
              : '',
          actionTitle: notificationData['actionTitle'] != null
              ? notificationData['actionTitle'] as String
              : '',
          actionUrl: notificationData['actionUrl'] != null
              ? notificationData['actionUrl'] as String
              : '',
          customData: notificationData['customData'] != null
              ? notificationData['customData'] as Map<String, String>
              : {},
        );
      }

      lastResult.value =
          _formatSendResult(notificationData, sendResult, targetType);

      if (sendResult.success) {
        TpsLoader.customToast(
            message:
                '${notificationType.value == 'push' ? 'Push notification' : 'In-app message'} sent successfully');
      } else {
        TpsLoader.customToast(
            message:
                'Failed to send ${notificationType.value == 'push' ? 'push notification' : 'in-app message'}: ${sendResult.message}');
      }
    } catch (e) {
      lastResult.value = 'Error: $e';
      TpsLoader.customToast(message: 'Failed to send notification: $e');
    } finally {
      isLoading.value = false;
      refreshStats(); // Refresh stats after sending
    }
  }

  String _formatSendResult(Map<String, dynamic> notificationData,
      NotificationSendResult result, String targetType) {
    final notificationTypeName = notificationType.value == 'push'
        ? 'Push Notification'
        : 'In-App Message';
    final targetName =
        targetType == 'all' ? 'all users' : 'logged-in users only';

    return '''
$notificationTypeName sent to $targetName:
- Type: $notificationTypeName
- Title: ${notificationData['title']}
- Body: ${notificationData['body']}
- Image: ${notificationData['imageUrl'] ?? 'None'}
- Action: ${notificationData['actionTitle'] ?? 'None'} -> ${notificationData['actionUrl'] ?? 'None'}
- Sound: ${notificationData['sound']}
- Priority: ${notificationData['priority']}
- TTL: ${notificationData['ttl']} seconds
- Custom Data: ${notificationData['customData']}
- Target: $targetName
- Status: ${result.success ? 'Success' : 'Failed'}
- Processed: ${result.tokensProcessed}
- Successful: ${result.tokensSuccessful}
- Failed: ${result.tokensFailed}
- Message: ${result.message}
${result.errors != null && result.errors!.isNotEmpty ? '\nErrors:\n${result.errors!.join('\n')}' : ''}
''';
  }
}
