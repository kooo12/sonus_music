import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../controllers/enhanced_notification_controller.dart';
import '../../ui/theme/app_colors.dart';

class EnhancedNotificationSenderPage extends StatelessWidget {
  const EnhancedNotificationSenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EnhancedNotificationController());
    final themeCtrl = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: TpsColors.musicBackgroundDark,
      appBar: AppBar(
        title: Text(
          'Send Notifications',
          style: themeCtrl.activeTheme.textTheme.headlineMedium!
              .copyWith(color: TpsColors.white),
        ),
        backgroundColor: TpsColors.musicBackgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back,
              color: TpsColors.white,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(controller),
            const SizedBox(height: 20),
            _buildNotificationTypeCard(controller),
            const SizedBox(height: 20),
            _buildBasicFieldsCard(controller),
            const SizedBox(height: 20),
            _buildAdvancedFieldsCard(controller),
            const SizedBox(height: 20),
            _buildCustomDataCard(controller),
            const SizedBox(height: 20),
            _buildSendButtons(controller),
            const SizedBox(height: 20),
            _buildResultCard(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(EnhancedNotificationController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Notification Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.refreshStats,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final stats = controller.stats.value;
              if (stats != null) {
                return Column(
                  children: [
                    _buildStatRow(
                        'Total FCM Tokens', stats.totalTokens.toString()),
                    _buildStatRow(
                        'Active Tokens', stats.activeTokens.toString()),
                    _buildStatRow(
                        'Logged-in Users', stats.loggedInUsers.toString()),
                    _buildStatRow(
                        'Inactive Tokens', stats.inactiveTokens.toString()),
                  ],
                );
              } else {
                return const Text(
                  'Loading statistics...',
                  style: TextStyle(color: Colors.white70),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeCard(EnhancedNotificationController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => RadioListTile<String>(
                  title: const Text(
                    'Push Notification',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'System notification (appears in notification bar)',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: 'push',
                  groupValue: controller.notificationType.value,
                  onChanged: (value) => controller.setNotificationType(value!),
                  activeColor: TpsColors.musicPrimary,
                )),
            Obx(() => RadioListTile<String>(
                  title: const Text(
                    'In-App Message',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Message appears within the app',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: 'in_app',
                  groupValue: controller.notificationType.value,
                  onChanged: (value) => controller.setNotificationType(value!),
                  activeColor: TpsColors.musicPrimary,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicFieldsCard(EnhancedNotificationController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Notification Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.titleController,
              label: 'Title *',
              hint: 'Enter notification title',
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.bodyController,
              label: 'Body *',
              hint: 'Enter notification message',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.imageUrlController,
              label: 'Image URL',
              hint: 'https://example.com/image.jpg',
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFieldsCard(EnhancedNotificationController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Notification Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.actionTitleController,
                    label: 'Action Title',
                    hint: 'View Details',
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: controller.actionUrlController,
                    label: 'Action URL',
                    hint: 'https://example.com/action',
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.soundController,
                    label: 'Sound',
                    hint: 'default',
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: controller.priorityController,
                    label: 'Priority',
                    hint: 'high',
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.ttlController,
              label: 'TTL (seconds)',
              hint: '86400',
              maxLines: 1,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDataCard(EnhancedNotificationController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Data Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.dataKeyController,
                    label: 'Data Key',
                    hint: 'key',
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: controller.dataValueController,
                    label: 'Data Value',
                    hint: 'value',
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: controller.addCustomData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TpsColors.musicPrimary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            Obx(() {
              if (controller.customData.isNotEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Custom Data:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...controller.customData.entries.map((entry) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    controller.removeCustomData(entry.key),
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                iconSize: 16,
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButtons(EnhancedNotificationController controller) {
    return Obx(() {
      final isPushNotification = controller.notificationType.value == 'push';

      return Column(
        children: [
          // Send to All button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.sendNotification('all'),
              icon: controller.isLoading.value
                  ? const LoadingWidget()
                  : Icon(
                      isPushNotification ? Icons.notifications : Icons.message),
              label: Text(controller.isLoading.value
                  ? 'Sending...'
                  : 'Send ${isPushNotification ? 'Push Notification' : 'In-App Message'} to All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TpsColors.musicPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Send to Logged-in Users button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.sendNotification('logged_in_users'),
              icon: controller.isLoading.value
                  ? const LoadingWidget()
                  : Icon(isPushNotification
                      ? Icons.notifications_active
                      : Icons.message_outlined),
              label: Text(controller.isLoading.value
                  ? 'Sending...'
                  : 'Send ${isPushNotification ? 'Push Notification' : 'In-App Message'} to Logged-in Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TpsColors.musicPrimary),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }

  Widget _buildResultCard(EnhancedNotificationController controller) {
    return Obx(() {
      if (controller.lastResult.value.isEmpty) return const SizedBox.shrink();

      return Card(
        color: TpsColors.musicCardDark,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last Send Result',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.lastResult.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
