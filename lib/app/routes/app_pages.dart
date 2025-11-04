import 'package:get/get.dart';
import 'package:music_player/app/bindings/developer_mode_binding.dart';
import 'package:music_player/app/bindings/home_binding.dart';
import 'package:music_player/app/bindings/splash_binding.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/data/models/in_app_message_model.dart';
import 'package:music_player/app/data/models/playlist_model.dart';
import 'package:music_player/app/data/models/song_model.dart';
import 'package:music_player/app/pages/add_songs_to_playlist_screen.dart';
import 'package:music_player/app/pages/admin/admin_dashboard_page.dart';
import 'package:music_player/app/pages/admin/fcm_management_page.dart';
import 'package:music_player/app/pages/admin/enhanced_notification_sender_page.dart';
import 'package:music_player/app/pages/admin/user_management_page.dart';
import 'package:music_player/app/pages/album_songs_screen.dart';
import 'package:music_player/app/pages/artist_songs_screen.dart';
import 'package:music_player/app/pages/authentication/login_page.dart';
import 'package:music_player/app/pages/authentication/signup_page.dart';
import 'package:music_player/app/pages/equalizer_page.dart';
import 'package:music_player/app/pages/home.dart';
import 'package:music_player/app/pages/player_widgets/full_screen_player.dart';
import 'package:music_player/app/pages/player_widgets/full_screen_player_landscape.dart';
import 'package:music_player/app/pages/playlist_songs_screen.dart';
import 'package:music_player/app/pages/privacy_view.dart';
import 'package:music_player/app/pages/queue_page.dart';
import 'package:music_player/app/pages/splash.dart';
import 'package:music_player/app/pages/notifications/in_app_messages_page.dart';
import 'package:music_player/app/pages/notifications/notification_detail_page.dart';
import 'package:music_player/app/pages/notifications/notification_settings_page.dart';
import 'package:music_player/app/data/services/notification_handler_service.dart';
import 'package:music_player/app/pages/storage_manager_page.dart';
import 'package:music_player/app/pages/terms_view.dart';
import 'package:music_player/app/routes/app_routes.dart';

class AppPages {
  static final pages = [
    // Splash
    GetPage(
        name: Routes.SPLASH,
        page: () => const SplashScreen(),
        binding: SplashBinding()),
    GetPage(
        name: Routes.HOME,
        page: () => const HomeScreen(),
        binding: HomeBinding()),
    // GetPage(
    //     name: Routes.DEVELOPERMODE,
    //     page: () => DeveloperModePage(),
    //     transition: Transition.leftToRight,
    //     binding: DeveloperModeBinding()),
    GetPage(
        name: Routes.FCMMANAGEMENTPAGE,
        page: () => const FCMManagementPage(),
        transition: Transition.leftToRight,
        binding: DeveloperModeBinding()),

    GetPage(
        name: Routes.USERMANAGEMENTPAGE,
        page: () => const UserManagementPage(),
        binding: DeveloperModeBinding(),
        transition: Transition.rightToLeft),
    GetPage(
        name: Routes.ADMINDASHBOARDPAGE,
        page: () => const AdminDashboardPage(),
        binding: DeveloperModeBinding(),
        transition: Transition.rightToLeft),

    GetPage(
        name: Routes.PRIVACY,
        page: () => const PrivacyView(),
        transition: Transition.rightToLeft),
    GetPage(
        name: Routes.TERMS,
        page: () => const TermsView(),
        transition: Transition.rightToLeft),

// -------------------------------------------------------------------------------

// Players

    GetPage(
      name: Routes.FULLSCREENPLAYER,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final controller = args['controller'] as HomeController;
        return FullScreenPlayer(controller: controller);
      },
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.FULLSCREENPLAYERLANDSCAPE,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final controller = args['controller'] as HomeController;
        return FullScreenPlayerLandscape(controller: controller);
      },
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.QUEUE,
      page: () => const QueuePage(),
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: Routes.EQUALIZER,
      page: () => const EqualizerPage(),
      opaque: false,
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ----------------------------------------------------------------------
    // Notifications
    GetPage(
      name: Routes.INAPPMESSAGEPAGE,
      page: () => InAppMessagesPage(),
      opaque: false,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
        name: Routes.NOTIFICATIONDETAIL,
        page: () {
          // Get arguments passed to the route
          final args = Get.arguments as Map<String, dynamic>;
          return NotificationDetailPage(
            message: args['message'] as InAppMessage,
            notificationHandler:
                args['notificationHandler'] as NotificationHandlerService,
          );
        },
        transition: Transition.rightToLeft),
    GetPage(
        name: Routes.NOTIFICATIONSENDERPAGE,
        page: () => const EnhancedNotificationSenderPage(),
        transition: Transition.leftToRight,
        binding: DeveloperModeBinding()),

    GetPage(
        name: Routes.NOTIFICATIONSETTINGS,
        page: () => NotificationSettingsPage(),
        transition: Transition.rightToLeft),

    // ------------------------------------------------------------
    // Song screens
    GetPage(
      name: Routes.ARTISTSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;

        return ArtistSongsScreen(
          artist: args['artist'] as String,
          songs: args['songs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.ALBUMSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;

        return AlbumSongsScreen(
          album: args['album'] as String,
          songs: args['songs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.PLAYLISTSONGSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return PlaylistSongsScreen(
          playlist: args['playlist'] as PlaylistModel,
          songs: args['playlistSongs'] as List<SongModel>,
          controller: args['controller'] as HomeController,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: Routes.ADDSONGTOPLAYLISTSCREEN,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final playlist = args['playlist'] as PlaylistModel;
        final controller = args['controller'] as HomeController;
        return AddSongsToPlaylistScreen(
          playlist: playlist,
          controller: controller,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ---------------------------------------------------------------------
    // Authentication
    GetPage(
        name: Routes.LOGINPAGE,
        page: () => const LoginPage(),
        transition: Transition.downToUp,
        transitionDuration: const Duration(milliseconds: 250),
        opaque: false),
    GetPage(
        name: Routes.SIGNUPPAGE,
        page: () => const SignupPage(),
        transition: Transition.downToUp,
        transitionDuration: const Duration(milliseconds: 250),
        opaque: false),

    // ---------------------------------------------------------------------

    // Settings
    GetPage(
      name: Routes.STORAGEMANAGERPAGE,
      page: () => const StorageManagerPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      opaque: false,
    ),
  ];
}
