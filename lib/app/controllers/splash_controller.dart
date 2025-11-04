import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/app_controller.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/helper_widgets/orientation_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../routes/app_routes.dart';
import '../pages/authentication/auth_controller.dart';
import '../data/models/user_model.dart';
import '../data/services/fcm_service.dart';
import '../data/services/fcm_cleanup_helper.dart';
import '../data/services/admin_service.dart';
import '../data/services/achievement_service.dart';
import '../data/services/audio_service.dart';
import 'achievement_controller.dart';

class SplashController extends GetxController {
  final _appCtrl = Get.find<AppController>();
  final themeCtrl = Get.find<ThemeController>();

  var isLoading = true.obs;
  var loadingText = 'Initializing...'.obs;
  var progress = 0.0.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OrientationHelper.setOrientation(Get.context!);
    });

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      // Start app setup in background (non-blocking)
      _appCtrl.setup().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('App setup timeout - continuing with offline mode');
        },
      ).catchError((e) {
        debugPrint('App setup error: $e');
      });

      // Perform critical startup tasks only
      await _performCriticalStartupTasks();
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Even if there's an error, navigate to home after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToHome();
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Internet check failed: $e');
      return false;
    }
  }

  /// Check if user is admin using AdminService
  Future<bool> _isAdminUser() async {
    try {
      AdminService adminService = Get.find<AdminService>();
      return await adminService.isCurrentUserAdmin();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> _performCriticalStartupTasks() async {
    // Only perform essential tasks that are required for app to function
    final criticalTasks = [
      _initializeAuthService,
      _checkAuthStatus,
    ];

    // Run critical tasks in parallel for faster startup
    await Future.wait(
      criticalTasks.map((task) => task().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('Critical task timeout - continuing');
            },
          ).catchError((e) {
            debugPrint('Critical task error: $e - continuing');
          })),
    );

    // Start non-critical tasks in background (don't wait for them)
    _startBackgroundTasks();

    // Navigate to home quickly
    progress.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 300));
    _navigateToHome();
  }

  Future<void> _startBackgroundTasks() async {
    // Run these tasks in background without blocking navigation
    Future.wait([
      _initializeNotifications(),
      _initializeFCM(),
      _requestPermissions(),
      _loadUserPreferences(),
      _checkAppVersion(),
      _loadSongsInBackground(), // Load songs in background
    ]).catchError((e) {
      debugPrint('Background task error: $e');
      return <void>[];
    });
  }

  Future<void> _loadSongsInBackground() async {
    try {
      // Get audio service and load songs in background
      if (Get.isRegistered<AudioPlayerService>()) {
        final audioService = Get.find<AudioPlayerService>();
        if (audioService.hasPermission.value) {
          debugPrint('Loading songs in background...');
          await audioService.checkPermissions();
          debugPrint(
              'Songs loaded in background: ${audioService.allSongs.length} songs');
        } else {
          debugPrint('No audio permission, skipping song loading');
        }
      }
    } catch (e) {
      debugPrint('Error loading songs in background: $e');
    }
  }

  Future<void> _checkAppVersion() async {
    loadingText.value = 'Checking app version...';
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      debugPrint('App version: ${packageInfo.version}');
      debugPrint('Build number: ${packageInfo.buildNumber}');
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    loadingText.value = 'Setting up notifications...';
    try {
      // Initialize Awesome Notifications
      await AwesomeNotifications().initialize(
        null, // Use default app icon
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
          ),
          NotificationChannel(
            channelKey: 'music_channel',
            channelName: 'Music Player',
            channelDescription:
                'Notification channel for music player controls',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: false,
            enableVibration: false,
          ),
          NotificationChannel(
            channelKey: 'sleep_timer',
            channelName: 'Sleep Timer',
            channelDescription: 'Notification channel for sleep timer alerts',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
      );

      // Initialize Firebase Messaging and Notification Handler
      // The notification handler service will be initialized automatically via AppBinding

      // // Request permission for notifications
      // NotificationSettings settings = await messaging.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );

      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   debugPrint('User granted permission');
      //   // Get FCM token
      //   String? token = await messaging.getToken();
      //   debugPrint('FCM Token: $token');
      // } else {
      //   debugPrint('User declined or has not accepted permission');
      // }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    loadingText.value = 'Requesting permissions...';
    try {
      // Request notification permission for Awesome Notifications
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _initializeAuthService() async {
    loadingText.value = 'Initializing...';
    try {
      if (!Get.isRegistered<AuthService>()) {
        Get.put(AuthService(), permanent: true);
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    loadingText.value = 'Checking authentication...';
    try {
      // Firebase restores sessions automatically
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        debugPrint('User is signed in: ${user.email}');
        // Update AuthController with current user
        if (Get.isRegistered<AuthController>()) {
          final authController = Get.find<AuthController>();
          authController.currentUser.value = UserModel.authenticated(
            id: user.uid,
            name: user.displayName ?? (user.email ?? 'User'),
            email: user.email ?? '',
            profileImageUrl: user.photoURL,
            phone: user.phoneNumber,
            provider: user.providerData.isNotEmpty
                ? user.providerData.first.providerId
                : 'unknown',
          );
        }

        // Start background sync tasks for logged-in user (non-blocking)
        _startUserSyncTasks(user.uid);
      } else {
        debugPrint('No user signed in - loading guest achievements');
        // Load achievements for guest user
        await _loadAchievementsFromLocal('guest');
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }
  }

  Future<void> _initializeFCM() async {
    loadingText.value = 'Initializing notifications...';
    try {
      // Check internet connectivity first
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        debugPrint('FCM: No internet connection - skipping FCM initialization');
        return;
      }

      if (!Get.isRegistered<FCMService>()) {
        final fcmService = Get.put(FCMService(), permanent: true);
        await fcmService.initializeFCM().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('FCM: Initialization timeout - continuing without FCM');
          },
        );
      } else {
        final fcmService = Get.find<FCMService>();
        await fcmService.initializeFCM().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('FCM: Initialization timeout - continuing without FCM');
          },
        );
      }

      // Only run cleanup for admin users and only if internet is available
      final isAdmin = await _isAdminUser();
      if (isAdmin && hasInternet) {
        debugPrint('FCM: Running cleanup for admin user');
        // Run cleanup in background without waiting
        FCMCleanupHelper.runCleanupIfNeeded().catchError((error) {
          debugPrint('FCM: Cleanup error: $error');
        });
      } else {
        debugPrint('FCM: Skipping cleanup - not admin user or no internet');
      }

      debugPrint('FCM: Service initialized');
    } catch (e) {
      debugPrint('FCM: Error initializing: $e');
      // Continue without FCM if there's an error
    }
  }

  Future<void> _loadUserPreferences() async {
    loadingText.value = 'Loading preferences...';
    try {
      _appCtrl.updateTheme();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Load any saved preferences
      // bool? isDarkMode = prefs.getBool('isDarkMode');
      String? lastPlayedSong = prefs.getString('lastPlayedSong');

      // debugPrint('Dark mode: $isDarkMode');
      debugPrint('Last played song: $lastPlayedSong');
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _finalizeSetup() async {
    loadingText.value = 'Finalizing setup...';
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      loadingText.value = 'Ready!';
    } catch (e) {
      debugPrint('Error in final setup: $e');
    }
  }

  void _navigateToHome() {
    isLoading.value = false;
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> _startUserSyncTasks(String userId) async {
    // Run user sync tasks in background without blocking navigation
    Future.wait([
      _syncUserData(userId),
    ]).catchError((e) {
      debugPrint('User sync task error: $e');
      return <void>[];
    });
  }

  Future<void> _syncUserData(String userId) async {
    try {
      // First, load achievements from local database
      await _loadAchievementsFromLocal(userId);

      // Check internet connectivity
      final hasInternet = await _hasInternetConnection();

      if (!hasInternet) {
        debugPrint('Skipping user data sync - no internet connection');
        return;
      }

      // Run sync tasks in parallel
      await Future.wait([
        _syncFCMToken(userId),
        _syncAchievements(userId),
        // _syncListeningStats(userId),
      ]);
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  Future<void> _syncFCMToken(String userId) async {
    if (Get.isRegistered<FCMService>()) {
      try {
        final fcmService = Get.find<FCMService>();
        await fcmService.updateTokenForUser(userId).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('FCM token update timeout for user');
          },
        );
      } catch (e) {
        debugPrint('Error updating FCM token for user: $e');
      }
    }
  }

  /// Load achievements from local database
  Future<void> _loadAchievementsFromLocal(String userId) async {
    if (Get.isRegistered<AchievementService>()) {
      try {
        final achievementService = Get.find<AchievementService>();

        // Load user achievements from local database
        await achievementService.getUserAchievements(userId);

        // Load achievement progress from local database
        await achievementService.getUserProgress(userId);

        debugPrint('Achievements loaded from local database for user: $userId');

        // Refresh achievement controller UI
        if (Get.isRegistered<AchievementController>()) {
          final achievementController = Get.find<AchievementController>();
          await achievementController.refreshAchievements();
        }
      } catch (e) {
        debugPrint('Error loading achievements from local: $e');
      }
    }
  }

  Future<void> _syncAchievements(String userId) async {
    if (Get.isRegistered<AchievementService>()) {
      try {
        final achievementService = Get.find<AchievementService>();
        await achievementService.syncLocalToFirestore(userId).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Achievement sync timeout for user');
          },
        );
        debugPrint('Achievement sync completed for user: $userId');

        // Refresh achievement controller UI
        if (Get.isRegistered<AchievementController>()) {
          final achievementController = Get.find<AchievementController>();
          await achievementController.refreshAchievements();
        }
      } catch (e) {
        debugPrint('Error syncing achievements for user: $e');
      }
    }
  }

  // Future<void> _syncListeningStats(String userId) async {
  //   if (Get.isRegistered<ListeningStatsService>()) {
  //     try {
  //       final listeningStatsService = Get.find<ListeningStatsService>();

  //       // First migrate guest data to user data
  //       await listeningStatsService.migrateGuestDataToUser(userId);

  //       // Then sync to Firestore
  //       await listeningStatsService.syncLocalToFirestore(userId).timeout(
  //         const Duration(seconds: 5),
  //         onTimeout: () {
  //           debugPrint('Listening stats sync timeout for user');
  //         },
  //       );
  //       debugPrint('Listening stats sync completed for user: $userId');

  //       // Refresh listening stats controller UI
  //       if (Get.isRegistered<ListeningStatsController>()) {
  //         final listeningStatsController = Get.find<ListeningStatsController>();
  //         await listeningStatsController.refreshStats();
  //       }
  //     } catch (e) {
  //       debugPrint('Error syncing listening stats for user: $e');
  //     }
  //   }
  // }
}
