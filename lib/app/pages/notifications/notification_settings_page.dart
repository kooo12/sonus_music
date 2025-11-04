import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import '../../controllers/notification_settings_controller.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/sizes.dart';

class NotificationSettingsPage extends StatelessWidget {
  NotificationSettingsPage({super.key});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationSettingsController>();

    return Scaffold(
      backgroundColor: TpsColors.musicGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        // actions: [
        //   TextButton(
        //       onPressed: controller.saveSettings,
        //       child: Text(
        //         'Save',
        //         style: themeCtrl.activeTheme.textTheme.bodyMedium,
        //       ))
        // ],
        title: Text(
          'Notification Settings',
          style: themeCtrl.activeTheme.textTheme.headlineSmall!
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TpsColors.musicGradientStart,
              TpsColors.musicGradientEnd,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TpsSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Push Notifications Section
              _buildSectionCard(
                title: 'Push Notifications',
                icon: Icons.notifications,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Push Notifications',
                    subtitle: 'Receive notifications from the app',
                    value: controller.isPushNotificationsEnabled,
                    onChanged: controller.togglePushNotifications,
                  ),
                  _buildSwitchTile(
                    title: 'Notification Sound',
                    subtitle: 'Play sound when notifications arrive',
                    value: controller.isNotificationSoundEnabled,
                    onChanged: controller.toggleNotificationSound,
                    enabled: controller.isPushNotificationsEnabled,
                  ),
                  _buildSwitchTile(
                    title: 'Vibration',
                    subtitle: 'Vibrate when notifications arrive',
                    value: controller.isNotificationVibrationEnabled,
                    onChanged: controller.toggleNotificationVibration,
                    enabled: controller.isPushNotificationsEnabled,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // In-App Messages Section
              _buildSectionCard(
                title: 'In-App Messages',
                icon: Icons.message,
                children: [
                  _buildSwitchTile(
                    title: 'Enable In-App Messages',
                    subtitle: 'Show messages as glass dialogs',
                    value: controller.isInAppMessagesEnabled,
                    onChanged: controller.toggleInAppMessages,
                  ),
                  _buildSwitchTile(
                    title: 'Auto-Show New Messages',
                    subtitle: 'Automatically display new messages',
                    value: controller.isAutoShowMessagesEnabled,
                    onChanged: controller.toggleAutoShowMessages,
                    enabled: controller.isInAppMessagesEnabled,
                  ),
                  _buildActionTile(
                    title: 'Test In-App Message',
                    subtitle: 'Preview how messages will look',
                    icon: Icons.preview,
                    onTap: controller.showTestMessage,
                    enabled: controller.isInAppMessagesEnabled,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sleep Timer Notifications Section
              _buildSectionCard(
                title: 'Sleep Timer Notifications',
                icon: Icons.timer,
                children: [
                  _buildSwitchTile(
                    title: 'Sleep Timer Alerts',
                    subtitle: 'Get notified when sleep timer ends',
                    value: controller.isSleepTimerNotificationsEnabled,
                    onChanged: controller.toggleSleepTimerNotifications,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quiet Hours Section
              _buildSectionCard(
                title: 'Quiet Hours',
                icon: Icons.bedtime,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Quiet Hours',
                    subtitle: 'Disable notifications during specific times',
                    value: controller.isQuietHoursEnabled,
                    onChanged: controller.toggleQuietHours,
                  ),
                  Obx(() {
                    if (controller.isQuietHoursEnabled.value) {
                      return Column(
                        children: [
                          _buildTimeTile(
                            title: 'Start Time',
                            subtitle: 'When to start quiet hours',
                            time: controller.quietStart.value,
                            onTap: () => controller.selectTime(context, true),
                          ),
                          _buildTimeTile(
                            title: 'End Time',
                            subtitle: 'When to end quiet hours',
                            time: controller.quietEnd.value,
                            onTap: () => controller.selectTime(context, false),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),

              const SizedBox(height: 40),

              // Save Button
              // _buildSaveButton(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x30FFFFFF),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TpsColors.musicPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: themeCtrl.activeTheme.textTheme.headlineSmall!
                          .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required RxBool value,
    required ValueChanged<bool> onChanged,
    RxBool? enabled,
  }) {
    return Obx(() {
      final isEnabled = enabled?.value ?? true;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                      color: isEnabled ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      color: isEnabled ? Colors.white70 : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled ? value.value : false,
              onChanged: isEnabled ? onChanged : null,
              activeColor: TpsColors.musicSecondary,
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: Colors.white24,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    RxBool? enabled,
  }) {
    return Obx(() {
      final isEnabled = enabled?.value ?? true;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Row(
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.white70 : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                        color: isEnabled ? Colors.white : Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                          themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                        color: isEnabled ? Colors.white70 : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isEnabled ? Colors.white54 : Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time.format(Get.context!),
              style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
