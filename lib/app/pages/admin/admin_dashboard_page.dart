import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import 'package:music_player/app/pages/admin/controllers/developer_mode_controller.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import 'package:music_player/app/ui/widgets/tps_buttons.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../../ui/theme/app_colors.dart';
import '../../helper_widgets/popups/loaders.dart';

class AdminDashboardPage extends GetView<AdminDashboardController> {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final devCtrl = Get.find<DeveloperModeController>();
    final themeCtrl = Get.find<ThemeController>();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          backgroundColor: TpsColors.musicBackgroundDark,
          appBar: AppBar(
            title: Text(
              'Admin Dashboard',
              style: themeCtrl.activeTheme.textTheme.headlineMedium!
                  .copyWith(color: TpsColors.white),
            ),
            backgroundColor: TpsColors.musicBackgroundDark,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Obx(
                () => !devCtrl.isAuthenticated
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: controller.loadStats,
                        icon: const Icon(Icons.refresh),
                      ),
              ),
            ],
          ),
          body: Obx(() {
            if (!devCtrl.isAuthenticated) {
              return _buildPinEntryScreen(devCtrl, themeCtrl);
            }
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdminStatsCard(controller),
                    const SizedBox(height: 20),
                    _buildAdminActionsCard(controller),
                    const SizedBox(height: 20),
                    _buildQuickActionsCard(controller),
                  ],
                ),
              );
            }
          })),
    );
  }

  Widget _buildPinEntryScreen(
      DeveloperModeController devCtrl, ThemeController themeCtrl) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Enter PIN to access Developer Mode'.tr,
            style: themeCtrl.activeTheme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: devCtrl.pinController,
            keyboardType: TextInputType.number,
            focusNode: devCtrl.pinFocusNode,
            obscureText: true,
            maxLength: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                      Radius.circular(TpsSizes.borderRadiusLg))),
              labelText: 'PIN'.tr,
              counterText: '',
            ),
            onSubmitted: (value) async {
              await devCtrl.verifyPin();
            },
          ),
          const SizedBox(height: 20),
          TpsButtons.confirm(
            isLarge: true,
            borderRadius: TpsSizes.borderRadiusLg,
            onPressed: () async {
              await devCtrl.verifyPin();
            },
            text: 'Verify',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatsCard(AdminDashboardController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final stats = controller.stats.value;
              if (stats != null) {
                return Column(
                  children: [
                    _buildStatRow('Total Users', stats.totalUsers.toString()),
                    _buildStatRow('Admin Users', stats.totalAdmins.toString()),
                    _buildStatRow(
                        'Total FCM Tokens', stats.totalFcmTokens.toString()),
                    _buildStatRow(
                        'Active FCM Tokens', stats.activeFcmTokens.toString()),
                  ],
                );
              } else {
                return const Text(
                  'No statistics available',
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

  Widget _buildAdminActionsCard(AdminDashboardController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.notifications,
              title: 'Send Notifications',
              subtitle: 'Send push notifications and in-app messages',
              onTap: () => controller.toSendNotification(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.cleaning_services,
              title: 'FCM Token Management',
              subtitle: 'Clean up expired FCM tokens',
              onTap: () => controller.toFCMStatus(),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.people,
              title: 'User Management',
              subtitle: 'Manage users and admin privileges',
              onTap: () => Get.toNamed(Routes.USERMANAGEMENTPAGE),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(AdminDashboardController controller) {
    return Card(
      color: TpsColors.musicCardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.loadStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Stats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TpsColors.musicPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateAdminDialog(controller),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Create Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 12),
            // Row(
            //   children: [
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         onPressed: () =>
            //             Get.to(() => const EnhancedNotificationSenderPage()),
            //         icon: const Icon(Icons.notifications),
            //         label: const Text('Send Notifications'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.blue,
            //           foregroundColor: Colors.white,
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         onPressed: () => controller.loadStats,
            //         icon: const Icon(Icons.refresh),
            //         label: const Text('Refresh'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.green,
            //           foregroundColor: Colors.white,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () async {
            //       try {
            //         final notificationHandler =
            //             Get.find<NotificationHandlerService>();
            //         notificationHandler.debugCurrentState();

            //         // Test notification creation
            //         await AwesomeNotifications().createNotification(
            //           content: NotificationContent(
            //             id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            //             channelKey: 'in_app_messages',
            //             title: 'Test In-App Message',
            //             body:
            //                 'This is a test notification to verify the channel works',
            //           ),
            //         );

            //         Get.snackbar(
            //           'Debug & Test',
            //           'Debug info logged + test notification sent',
            //           backgroundColor: Colors.orange,
            //           colorText: Colors.white,
            //         );
            //       } catch (e) {
            //         Get.snackbar(
            //           'Error',
            //           'Error: $e',
            //           backgroundColor: Colors.red,
            //           colorText: Colors.white,
            //         );
            //       }
            //     },
            //     icon: const Icon(Icons.bug_report),
            //     label: const Text('Debug Notifications'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.orange,
            //       foregroundColor: Colors.white,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: TpsColors.musicPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  void _showFCMCleanupDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('FCM Token Cleanup'),
        content: const Text(
            'This feature will be available in the FCM Management page.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminDialog(AdminDashboardController controller) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    Get.dialog(
      GlassAlertDialog(
        title: const Text('Create Admin Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                Navigator.pop(Get.context!);

                await controller.createAdminAccount(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  displayName: nameController.text.trim(),
                );
              } else {
                TpsLoader.customToast(message: 'Please fill all fields');
              }
            },
            child: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
