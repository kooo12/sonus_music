import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:music_player/app/controllers/app_controller.dart';
import 'package:music_player/app/controllers/language_controller.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import '../helper_widgets/popups/loaders.dart';
import '../helper_widgets/popups/glass_dialog.dart';
import '../data/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../ui/theme/app_colors.dart';
import '../data/services/auth_service.dart';
import 'authentication/auth_controller.dart';
import '../routes/app_routes.dart';
import 'widgets/achievement_display_widget.dart';
import 'widgets/listening_stats_widget.dart';

class ProfileView extends StatelessWidget {
  final HomeController controller;

  ProfileView({super.key, required this.controller});

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    // final themeController = Get.find<ThemeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 15),

          // Achievements Section
          _buildAchievementsSection(),
          const SizedBox(height: 15),

          // Listening Stats Section
          _buildListeningStatsSection(),
          const SizedBox(height: 15),

          // Statistics
          _buildStatistics(),
          const SizedBox(height: 15),

          // Settings Section
          _buildSettingsSection(),
          const SizedBox(height: 15),

          // Music Library Info
          _buildLibraryInfo(),
          const SizedBox(height: 15),

          // About Section
          _buildAboutSection(),
          const SizedBox(
            height: 160,
          )
        ],
      ),
    );
  }

  Widget _buildProfileTabletHeader() {
    return Obx(() {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      final auth =
          Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final fUser = auth?.firebaseUser.value;
      final isLoggedIn = fUser != null;
      final displayName = isLoggedIn
          ? ((fUser.displayName?.trim().isNotEmpty == true
                  ? fUser.displayName
                  : (fUser.email ?? user.displayName)) ??
              user.displayName)
          : user.displayName;
      final emailText = isLoggedIn ? fUser.email : user.email;
      final photoUrl = isLoggedIn ? fUser.photoURL : user.profileImageUrl;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(
                        colors: [
                          TpsColors.musicPrimary,
                          TpsColors.musicSecondary
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(37),
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),

                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (emailText != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      emailText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],

                  const SizedBox(height: 15),

                  // Login/Logout Button
                  if (!isLoggedIn)
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(Routes.LOGINPAGE);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TpsColors.musicPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: Text(
                        'Sign In'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        _showSignOutDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Sign Out'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to sync your achievements across devices and unlock exclusive features',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAuthFeature('📧', 'Email & Password'),
                      const SizedBox(width: 16),
                      _buildAuthFeature('🔐', 'Google Sign-In'),
                      const SizedBox(width: 16),
                      _buildAuthFeature('📱', 'Phone Verification'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // Helper method
  Widget _buildAuthFeature(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      final auth =
          Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final fUser = auth?.firebaseUser.value;
      final isLoggedIn = fUser != null;
      final displayName = isLoggedIn
          ? ((fUser.displayName?.trim().isNotEmpty == true
                  ? fUser.displayName
                  : (fUser.email ?? user.displayName)) ??
              user.displayName)
          : user.displayName;
      final emailText = isLoggedIn ? fUser.email : user.email;
      final photoUrl = isLoggedIn ? fUser.photoURL : user.profileImageUrl;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: [TpsColors.musicPrimary, TpsColors.musicSecondary],
                ),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(37),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 15),

            // Name
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (emailText != null) ...[
              const SizedBox(height: 5),
              Text(
                emailText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],

            const SizedBox(height: 15),

            // Login/Logout Button
            if (!isLoggedIn)
              ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(Routes.LOGINPAGE);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TpsColors.musicPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.login, color: Colors.white),
                label: Text(
                  'Sign In'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  _showSignOutDialog();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Sign Out'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildStatistics() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Music Stats'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Songs'.tr,
                      '${controller.allSongs.length}',
                      Icons.music_note,
                      TpsColors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatItem(
                      'Playlists'.tr,
                      '${controller.userPlaylists.length}',
                      Icons.queue_music,
                      TpsColors.musicSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Liked Songs'.tr,
                      '${controller.likedSongs.length}',
                      Icons.favorite,
                      TpsColors.musicAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatItem(
                      'Artists'.tr,
                      '${controller.allArtists.length}',
                      Icons.person,
                      TpsColors.cphsd,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final languageCtrl = Get.find<LanguageController>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Settings'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Language Toggle
          Obx(() => _buildSettingItem(
                'Language'.tr,
                'Switch language preferences to change English / မြန်မာ'.tr,
                Icons.language,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text(
                    //   'EN',
                    //   style: TextStyle(
                    //     color: Colors.white.withOpacity(0.7),
                    //     fontSize: 14,
                    //   ),
                    // ),
                    Switch(
                      value: languageCtrl.currentLangIndex.value == 1,
                      onChanged: (value) {
                        // themeCtrl.setDarkMode(value);
                        if (value) {
                          languageCtrl.changeLanguage('မြန်မာ');
                        } else {
                          languageCtrl.changeLanguage('English');
                        }
                      },
                      activeColor: TpsColors.musicSecondary,
                      inactiveThumbColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.2),
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
                    // Text(
                    //   'MM',
                    //   style: TextStyle(
                    //     color: Colors.white.withOpacity(0.7),
                    //     fontSize: 14,
                    //   ),
                    // ),
                  ],
                ),
              )),
          // Dark Mode Toggle
          Obx(
            () => _buildSettingItem(
              'Color Mode'.tr,
              'Switch between primary and grey mode'.tr,
              Iconsax.sun_1_copy,
              trailing: Switch(
                value: themeCtrl.isDarkMode,
                onChanged: (value) {
                  languageCtrl.changeMode(value);
                },
                activeColor: TpsColors.musicSecondary,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.2),
                inactiveTrackColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),

          _buildSettingItem(
            'Notifications'.tr,
            'Manage notification preferences'.tr,
            Icons.notifications,
            onTap: () {
              Get.toNamed(Routes.NOTIFICATIONSETTINGS);
            },
          ),

          // _buildSettingItem(
          //   'Audio Quality',
          //   'Adjust playback quality settings',
          //   Icons.high_quality,
          //   onTap: () {
          //     Get.snackbar(
          //       'Coming Soon',
          //       'Audio quality settings will be available soon',
          //       snackPosition: SnackPosition.bottom,
          //     );
          //   },
          // ),

          _buildSettingItem(
            'Storage'.tr,
            'Manage music folder locations'.tr,
            Icons.storage,
            onTap: () {
              Get.toNamed(Routes.STORAGEMANAGERPAGE);
            },
          ),

          // Delete Account Button (only show for logged-in users)
          Obx(() {
            final authController = Get.find<AuthController>();
            final user = authController.currentUser.value;

            if (user.id != null && user.id!.isNotEmpty && !user.isGuest) {
              return _buildSettingItem(
                'Delete Account'.tr,
                'Permanently delete your account and all data'.tr,
                Icons.delete_forever,
                onTap: () {
                  authController.deleteAccount();
                },
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red,
                  size: 16,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TpsColors.musicSecondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: TpsColors.musicSecondary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.5),
            size: 16,
          ),
      onTap: onTap,
    );
  }

  Widget _buildLibraryInfo() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Music Library'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoRow('Total Songs'.tr, '${controller.allSongs.length}'),
              _buildInfoRow(
                  'Total Artists'.tr, '${controller.allArtists.length}'),
              _buildInfoRow(
                  'Total Albums'.tr, '${controller.allAlbums.length}'),
              _buildInfoRow(
                  'Recently Played'.tr, '${controller.recentlyPlayed.length}'),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Trigger rescan using selected folders
                    TpsLoader.customToast(
                        message:
                            'Refreshing Library: scanning for new music files...');
                    final svc = Get.find<AudioPlayerService>();
                    await svc.loadSongs();
                    TpsLoader.customToast(
                        message:
                            'Scan complete. Found ${svc.allSongs.length} songs');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TpsColors.musicSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh Library',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const AchievementDisplayWidget(
        showAll: true,
      ),
    );
  }

  Widget _buildListeningStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const ListeningStatsWidget(),
    );
  }

  Widget _buildAboutSection() {
    var appCtrl = Get.find<AppController>();
    // AdminService adminService = Get.find<AdminService>();

    // final user = authController.currentUser.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onDoubleTapCancel: () async {
              // bool isAdmin = await adminService.isCurrentUserAdmin();
              // if (isAdmin) {
              controller.toAdminDashboard();
              // }
            },
            child: _buildAboutItem(
              'Version',
              appCtrl.version?.value.isNotEmpty == true
                  ? 'v${appCtrl.version!.value} (Build ${appCtrl.buildNumber!.value})'
                  : '1.0.0',
              Icons.info_outline,
            ),
          ),
          _buildAboutItem(
            'Privacy Policy',
            'View our privacy policy',
            Icons.privacy_tip,
            onTap: () => Get.toNamed(Routes.PRIVACY),
          ),
          _buildAboutItem(
            'Terms of Service',
            'View terms and conditions',
            Icons.description,
            onTap: () => Get.toNamed(Routes.TERMS),
          ),
          _buildAboutItem('Contact Support',
              'Get help and support from Developer', Icons.support_agent,
              onTap: () => controller
                  .launchWeb(Uri.parse('https://forms.gle/Ay2vPSZiTWYggogB6'))),
        ],
      ),
    );
  }

  Widget _buildAboutItem(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            )
          : null,
      onTap: onTap,
    );
  }

  void _showLoginDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sign In'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showSignOutDialog() {
    Get.dialog(
      GlassAlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              final authController = Get.find<AuthController>();
              authController.signOut();
              Navigator.pop(Get.context!);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }
}
