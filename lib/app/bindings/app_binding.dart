import 'package:get/get.dart';
import 'package:music_player/app/controllers/app_controller.dart';
import 'package:music_player/app/controllers/language_controller.dart';
import 'package:music_player/app/controllers/notification_settings_controller.dart';
import 'package:music_player/app/controllers/achievement_controller.dart';
import 'package:music_player/app/controllers/listening_stats_controller.dart';
import 'package:music_player/app/data/services/admin_service.dart';
import 'package:music_player/app/data/services/auth_service.dart';
import 'package:music_player/app/data/services/achievement_service.dart';
import 'package:music_player/app/data/services/listening_stats_service.dart';
import 'package:music_player/app/data/services/production_notification_service.dart';
import 'package:music_player/app/data/services/fcm_service.dart';
import 'package:music_player/app/data/services/real_fcm_service.dart';
import 'package:music_player/app/data/services/notification_handler_service.dart';
import 'package:music_player/app/data/services/notification_settings_service.dart';
import 'package:music_player/app/data/services/sleep_timer_service.dart';
import 'package:music_player/app/pages/authentication/auth_controller.dart';

class AppBinding implements Binding {
  @override
  List<Bind<dynamic>> dependencies() {
    Get.put(AppController(), permanent: true);
    // Get.put(StorageService(), permanent: true);
    // AppStateRepository? repository;
    Get.put(LanguageController(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(FCMService(), permanent: true);
    Get.put<AdminService>(AdminService(), permanent: true);
    Get.put(RealFCMService(), permanent: true);
    Get.put(NotificationHandlerService(), permanent: true);
    Get.put(NotificationSettingsService(), permanent: true);
    Get.put(NotificationSettingsController(), permanent: true);
    Get.put(SleepTimerService(), permanent: true);

    // Register AchievementService and AchievementController
    Get.put<AchievementService>(AchievementService(), permanent: true);
    Get.put<AchievementController>(AchievementController(), permanent: true);

    // Register ListeningStatsService and ListeningStatsController
    Get.put<ListeningStatsService>(ListeningStatsService(), permanent: true);
    Get.put<ListeningStatsController>(ListeningStatsController(),
        permanent: true);

    // Register AuthService and AuthController
    final authService = AuthService();
    Get.put<AuthService>(authService, permanent: true);
    Get.put<AuthController>(AuthController(authService), permanent: true);

    // Register AdminService and ProductionNotificationService
    Get.put<AdminService>(AdminService(), permanent: true);
    Get.put<ProductionNotificationService>(ProductionNotificationService(),
        permanent: true);

    return [];
  }
}
