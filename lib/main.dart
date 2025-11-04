import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:music_player/app/bindings/app_binding.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_player/app/data/services/app_audio_handler.dart';
import 'package:music_player/app/data/services/audio_service.dart' as svc;
import 'package:music_player/app/data/services/app_audio_session.dart';
import 'package:music_player/app/data/services/app_lifecycle_manager.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/services/storage_service.dart';
import 'package:music_player/app/pages/splash.dart';
import 'package:music_player/app/routes/app_pages.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/translations/app_translations.dart';

FutureOr<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [
        SystemUiOverlay.top,
      ],
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (Platform.isAndroid) {
    try {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
        apiKey: "your_api_key_from_firebase",
        appId: 'your_appId_from_firebase',
        messagingSenderId: 'your_id',
        projectId: 'your_proj_id',
        storageBucket: 'your_id',
      )).whenComplete(() {
        debugPrint("=>Firebase initialize completed on Android");
      });
    } catch (e) {
      debugPrint("=>Firebase initialize failed on Android $e");
    }
  }
  // Ensure core services in Get before AudioHandler bridges to them
  Get.put<svc.AudioPlayerService>(svc.AudioPlayerService(), permanent: true);
  final appSession = AppAudioSession();
  await appSession.configure();
  Get.put<AppAudioSession>(appSession, permanent: true);

  // Initialize audio_service handler
  final handler = await AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'media_playback',
      androidNotificationChannelName: 'Media Playback',
      androidNotificationChannelDescription: 'Music playback controls',
      androidNotificationOngoing: true,
      // androidStopForegroundOnPause:
      //     false,
      androidShowNotificationBadge: false,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
    ),
  );
  Get.put<AppAudioHandler>(handler, permanent: true);
  Get.put(StorageService(), permanent: true);

  // Initialize lifecycle manager for battery optimization
  final lifecycleManager = AppLifecycleManager(
    Get.find<svc.AudioPlayerService>(),
    handler,
  );
  Get.put<AppLifecycleManager>(lifecycleManager, permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        themeMode:
            themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        debugShowCheckedModeBanner: false,
        binds: AppBinding().dependencies(),

        initialRoute: Routes.SPLASH,
        theme: themeController.activeTheme,
        defaultTransition: Transition.fade,
        getPages: AppPages.pages,
        darkTheme: themeController.darkTheme,
        home: const SplashScreen(),

        // locale: const Locale('pt', 'BR'),
        // translationsKeys: AppTranslation.translations,

        locale: AppTranslation.locale,
        fallbackLocale: AppTranslation.fallbackLocale,
        translations: AppTranslation(),
      ),
    );
  }
}
