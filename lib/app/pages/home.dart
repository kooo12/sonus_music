import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/data/models/song_model.dart';
import 'package:music_player/app/data/services/auth_service.dart';
import 'package:music_player/app/pages/authentication/auth_controller.dart';
import 'package:music_player/app/data/models/playlist_model.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import 'package:music_player/app/pages/player_widgets/landscape_mini_player.dart';
import 'package:music_player/app/pages/player_widgets/mini_player.dart';
import 'package:music_player/app/pages/playlist_dialog/edit_playlist_dialog.dart';
import 'package:music_player/app/pages/library_view.dart';
import 'package:music_player/app/pages/search_view.dart';
import 'package:music_player/app/pages/profile_view.dart';
import 'package:music_player/app/data/services/notification_handler_service.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
// import 'package:music_player/constants.dart';
import 'package:music_player/app/pages/widgets/achievement_unlock_overlay.dart';
import 'package:music_player/app/pages/widgets/music_mood_widget.dart';
import 'package:music_player/app/pages/widgets/smart_recommendations_widget.dart';
import 'package:music_player/app/pages/widgets/music_discovery_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());
    final themeCtrl = Get.find<ThemeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Determine layout based on screen size and orientation
    final isTablet = screenWidth >= 768; // Tablet breakpoint
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;
    // final isPhoneLandscape = !isTablet && isLandscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        top: false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeCtrl.isDarkMode
                          ? TpsColors.darkGradientColors
                          : TpsColors.primaryGradientColors,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: _buildResponsiveLayout(
                        controller, isTablet, isLandscape, isTabletLandscape),
                  ),
                ),
              ),
              isTabletLandscape
                  ? const SizedBox.shrink()
                  : Positioned(
                      bottom: 10,
                      child: SizedBox(
                          width: Get.width,
                          child: _buildBottomNavigation(controller))),
              // Achievement Unlock Overlay - Shows on top of all tabs
              const AchievementUnlockOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(HomeController controller, bool isTablet,
      bool isLandscape, bool isTabletLandscape) {
    if (isTabletLandscape) {
      return _buildTabletLandscapeLayout(controller, isTablet);
    }
    // else if (isTablet) {
    //   return _buildTabletLayout(controller);
    // }
    // else if (isPhoneLandscape) {
    //   return _buildPhoneLandscapeLayout(controller);
    // }
    else {
      return _buildMobileLayout(controller, isTablet);
    }
  }

  Widget _buildMobileLayout(
    HomeController controller,
    bool isTablet,
  ) {
    return Stack(
      children: [
        // Main content without mini player
        Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(controller),

            // Main Content with smooth transitions
            Expanded(
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentView(controller, isTablet),
                );
              }),
            ),

            // Bottom Navigation
            // _buildBottomNavigation(controller),
          ],
        ),

        // Mini Player as overlay
        Positioned(
          bottom: 58,
          left: 0,
          right: 0,
          child: Obx(() {
            final song = controller.currentSong;

            return song != null ? const MiniPlayer() : const SizedBox.shrink();
          }),
        ),
      ],
    );
  }

  Widget _buildTabletLandscapeLayout(HomeController controller, bool isTablet) {
    return Row(
      children: [
        // Expanded sidebar for landscape tablets
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: TpsSizes.defaultSpace,
              vertical: TpsSizes.defaultSpace),
          child: Container(
            width: Get.width * 0.3,
            padding: const EdgeInsets.symmetric(
                horizontal: TpsSizes.defaultSpace,
                vertical: TpsSizes.defaultSpace),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
              ),
              borderRadius: const BorderRadius.all(
                  Radius.circular(TpsSizes.spaceBtwSections)),
            ),
            child: Column(
              children: [
                // App Bar for tablet landscape
                _buildTabletLandscapeAppBar(controller),

                // Navigation items
                Expanded(
                  child: _buildTabletLandscapeNavigation(controller),
                ),

                // Mini player in sidebar for landscape
                Container(
                  margin: const EdgeInsets.all(16),
                  child: const LandscapeMiniPlayer(),
                ),
              ],
            ),
          ),
        ),

        // Main content area
        Expanded(
          child: Obx(() {
            return Padding(
              padding: const EdgeInsets.only(
                top: TpsSizes.defaultSpace,
                right: TpsSizes.defaultSpace,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentView(controller, isTablet),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Widget _buildTabletLayout(HomeController controller) {
  //   return Stack(
  //     children: [
  //       // Main content without mini player
  //       Column(
  //         children: [
  //           // Custom App Bar
  //           _buildCustomAppBar(controller),

  //           // Main Content with smooth transitions
  //           Expanded(
  //             child: Obx(() {
  //               return AnimatedSwitcher(
  //                 duration: const Duration(milliseconds: 300),
  //                 transitionBuilder:
  //                     (Widget child, Animation<double> animation) {
  //                   return FadeTransition(
  //                     opacity: animation,
  //                     child: SlideTransition(
  //                       position: Tween<Offset>(
  //                         begin: const Offset(0.1, 0),
  //                         end: Offset.zero,
  //                       ).animate(animation),
  //                       child: child,
  //                     ),
  //                   );
  //                 },
  //                 child: _buildCurrentView(controller),
  //               );
  //             }),
  //           ),

  //           // Bottom Navigation
  //           _buildBottomNavigation(controller),
  //         ],
  //       ),

  //       // Mini Player as overlay
  //       Positioned(
  //         bottom: 50,
  //         left: 0,
  //         right: 0,
  //         child: Obx(() {
  //           final song = controller.currentSong;

  //           return song != null
  //               ? _buildMiniPlayer(controller)
  //               : const SizedBox.shrink();
  //         }),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTabletLandscapeAppBar(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Obx(() {
            final authController = Get.find<AuthController>();
            final user = authController.currentUser.value;
            final auth = Get.isRegistered<AuthService>()
                ? Get.find<AuthService>()
                : null;
            final fUser = auth?.firebaseUser.value;
            final isLoggedIn = fUser != null;

            final photoUrl = isLoggedIn ? fUser.photoURL : user.profileImageUrl;
            return !isLoggedIn
                ? Image.asset('assets/app_icon.png',
                    fit: BoxFit.cover, width: 60, height: 60)
                : Container(
                    width: 60,
                    height: 60,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  );
          }),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Good ${_getGreeting()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Obx(() {
                final authController = Get.find<AuthController>();
                final user = authController.currentUser.value;
                final name = user.displayName;

                return Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeNavigation(HomeController controller) {
    final navItems = [
      {'icon': Iconsax.home, 'label': 'Home', 'view': 'home'},
      {'icon': Iconsax.search_normal, 'label': 'Search', 'view': 'search'},
      {'icon': Iconsax.music_library_2, 'label': 'Library', 'view': 'library'},
      {'icon': Iconsax.profile_circle, 'label': 'Profile', 'view': 'profile'},
    ];

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: navItems.length,
          itemBuilder: (context, index) {
            return Obx(() {
              final item = navItems[index];
              final isActive = controller.currentView.value == item['view'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isActive
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => controller.changeView(item['view'] as String),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isActive ? Colors.white : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white70,
                                fontSize: 16,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  // Widget _buildQuickAccessCard(Map<String, dynamic> action) {
  //   return GestureDetector(
  //     onTap: action['onTap'],
  //     child: Container(
  //       width: 100,
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: action['color'].withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(color: action['color'].withOpacity(0.3)),
  //       ),
  //       child: Column(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(12),
  //             decoration: BoxDecoration(
  //               color: action['color'].withOpacity(0.2),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Icon(
  //               action['icon'],
  //               color: action['color'],
  //               size: 24,
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           Text(
  //             action['title'],
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.bold,
  //             ),
  //             textAlign: TextAlign.center,
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //           if (action['subtitle'] != null) ...[
  //             const SizedBox(height: 4),
  //             Text(
  //               action['subtitle'],
  //               style: TextStyle(
  //                 color: Colors.white.withOpacity(0.7),
  //                 fontSize: 10,
  //               ),
  //               textAlign: TextAlign.center,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCustomAppBar(HomeController controller) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Obx(() {
                  final authController = Get.find<AuthController>();
                  final user = authController.currentUser.value;
                  final name = user.displayName;
                  return Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
              ],
            ),
            Row(
              children: [
                Obx(() {
                  final notificationHandler =
                      Get.find<NotificationHandlerService>();
                  final unreadCount = notificationHandler.unreadCount;

                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => controller.toInAppMessagesPage(),
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(width: 8),
                Obx(() {
                  final authController = Get.find<AuthController>();
                  final user = authController.currentUser.value;
                  final auth = Get.isRegistered<AuthService>()
                      ? Get.find<AuthService>()
                      : null;
                  final fUser = auth?.firebaseUser.value;
                  final isLoggedIn = fUser != null;

                  final photoUrl =
                      isLoggedIn ? fUser.photoURL : user.profileImageUrl;
                  return !isLoggedIn
                      ? Image.asset('assets/app_icon.png',
                          fit: BoxFit.cover, width: 30, height: 30)
                      : Container(
                          width: 40,
                          height: 40,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(HomeController controller, bool isTablet) {
    return Obx(() {
      // Check if permissions are granted
      if (!controller.hasPermission) {
        return _buildPermissionView(controller);
      }

      // Show loading if audio is loading
      if (controller.isAudioLoading) {
        return _buildLoadingView();
      }

      // Show empty state if no songs
      if (controller.allSongs.isEmpty) {
        return _buildEmptyStateView(controller);
      }

      // Show main content
      return isTablet
          ? _tabletHomeView(controller, isTablet)
          : _mobileHomeView(controller, isTablet);
    });
  }

  Widget _mobileHomeView(HomeController controller, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: TpsSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Quick Actions

          _buildSleepTimerCard(controller),
          const SizedBox(height: 20),

          // New Functional Widgets Section
          // Music Mood Widget
          const MusicMoodWidget(),
          const SizedBox(height: 16),

          // Recently Played
          if (controller.recentlyPlayed.isNotEmpty) ...[
            _buildSectionTitle('Recently Played'.tr,
                onTap: () =>
                    controller.showPlaylistSongs(controller.allPlaylists[1]),
                showPlay: true,
                songlist: controller.recentlyPlayed),
            const SizedBox(height: 15),
            _buildRecentlyPlayed(controller),
            const SizedBox(height: 10),
            // Smart Recommendations Widget
            const SmartRecommendationsWidget(),
            const SizedBox(height: 16),
          ],

          // Quick Stats Widget
          // const QuickStatsWidget(),
          // const SizedBox(height: 16),

          // Quick Access Widget
          // const QuickAccessWidget(),
          // const SizedBox(height: 20),

          // Made for You
          _buildSectionTitle('Made for You'.tr),
          const SizedBox(height: 15),
          _buildMadeForYou(controller),
          const SizedBox(height: 20),
          // Music Discovery Widget
          const Padding(
            padding: EdgeInsets.only(right: TpsSizes.defaultSpace),
            child: MusicDiscoveryWidget(isCompact: true),
          ),
          const SizedBox(height: 16),

          // Your Playlists
          if (controller.userPlaylists.isNotEmpty) ...[
            _buildSectionTitle(
              'Your Playlists'.tr,
              showMore: true,
              onTap: () =>
                  controller.titleTapAction('library', 'Recently Played'),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(right: TpsSizes.defaultSpace),
              child: _buildPlaylists(controller),
            ),
            const SizedBox(height: 10),
          ],

          // All Songs Preview
          _buildSectionTitle('All Songs'.tr,
              onTap: () => controller.titleTapAction('library', 'All Songs'),
              showShuffle: true,
              showPlay: true,
              songlist: controller.allSongs),
          const SizedBox(height: 15),
          _buildAllSongsPreview(controller),
          const SizedBox(height: 170),
        ],
      ),
    );
  }

  Widget _tabletHomeView(HomeController controller, bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: TpsSizes.defaultSpace * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Quick Actions
          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(child: _buildTabletTimerCard(controller)),
              const SizedBox(width: 10),
              const Expanded(child: MusicMoodWidget()),
            ],
          ),

          // New Functional Widgets Section
          // Music Mood Widget

          const SizedBox(height: 16),

          // Quick Stats Widget
          // const QuickStatsWidget(),
          // const SizedBox(height: 16),

          // Recently Played
          if (controller.recentlyPlayed.isNotEmpty) ...[
            _buildSectionTitle('Recently Played'.tr,
                onTap: () =>
                    controller.titleTapAction('library', 'Recently Played'),
                showPlay: true,
                songlist: controller.recentlyPlayed),
            const SizedBox(height: 15),
            _buildRecentlyPlayed(controller),
            const SizedBox(height: 10),
            // Smart Recommendations Widget
            const SmartRecommendationsWidget(),
            const SizedBox(height: 16),
          ],

          // Made for You
          _buildSectionTitle('Made for You'.tr),
          const SizedBox(height: 15),
          _buildMadeForYou(controller),
          const SizedBox(height: 20),

          // Music Discovery Widget
          const Padding(
            padding: EdgeInsets.only(right: TpsSizes.defaultSpace),
            child: MusicDiscoveryWidget(),
          ),
          const SizedBox(height: 16),

          // Quick Access Widget
          // const QuickAccessWidget(),
          // const SizedBox(height: 20),

          // Your Playlists
          if (controller.userPlaylists.isNotEmpty) ...[
            _buildSectionTitle('Your Playlists'.tr, showMore: true),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(right: TpsSizes.defaultSpace),
              child: _buildPlaylists(controller),
            ),
            const SizedBox(height: 10),
          ],

          // All Songs Preview
          _buildSectionTitle('All Songs'.tr,
              onTap: () => controller.titleTapAction('library', 'All Songs'),
              showShuffle: true,
              showPlay: true,
              songlist: controller.allSongs),
          const SizedBox(height: 15),
          _buildAllSongsPreview(controller),
          const SizedBox(height: 170),
        ],
      ),
    );
  }

  Widget _buildPermissionView(HomeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 30),
            const Text(
              'Music Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'To play music from your device, we need permission to access your music library.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.requestPermissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TpsColors.musicPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // CircularProgressIndicator(
          //   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          // ),
          LoadingWidget(
            color: Colors.white,
          ),
          SizedBox(height: 20),
          Text(
            'Loading your music...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(HomeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 30),
            const Text(
              'No Music Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'No music files were found on your device. Make sure you have music files stored locally.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.requestPermissions(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TpsColors.musicPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSleepTimer(HomeController controller, bool isTablet) {
  //   return Padding(
  //     padding: EdgeInsets.only(
  //         right: isTablet ? TpsSizes.defaultSpace * 2 : TpsSizes.defaultSpace),
  //     child: _buildSleepTimerCard(controller),
  //   );
  // }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTimerCard(HomeController controller) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(() {
      final isActive = controller.isSleepTimerActive;
      final timeText =
          isActive ? controller.sleepTimerFormattedTime : 'Sleep Timer'.tr;

      return GestureDetector(
        onTap: () => controller.showSleepTimerDialog(),
        child: Padding(
          padding: const EdgeInsets.only(right: TpsSizes.defaultSpace),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isActive
                  ? TpsColors.musicSecondary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isActive
                    ? TpsColors.musicPrimary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: TpsColors.musicPrimary.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? TpsColors.musicPrimary
                            : TpsColors.musicSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isActive ? Icons.timer : Icons.bedtime,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isActive ? 'Sleep Timer'.tr : 'Sleep Timer'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!isActive)
                      Text(
                        'Set up'.tr,
                        style: themeCtrl.activeTheme.textTheme.bodySmall,
                      ),
                    if (isActive) ...[
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: TpsSizes.spaceBtwItems),
                      GestureDetector(
                        onTap: () => controller.stopSleepTimer(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: TpsSizes.spaceBtwItems * 2),
                  LinearProgressIndicator(
                    value: controller.sleepTimerProgress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabletTimerCard(HomeController controller) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(() {
      final isActive = controller.isSleepTimerActive;
      final timeText =
          isActive ? controller.sleepTimerFormattedTime : 'Sleep Timer';

      return GestureDetector(
        onTap: () => controller.showSleepTimerDialog(),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isActive
                ? TpsColors.musicSecondary.withOpacity(0.2)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isActive
                  ? TpsColors.musicPrimary.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: TpsColors.musicPrimary.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: isActive
                          ? TpsColors.musicPrimary
                          : TpsColors.musicSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isActive ? Icons.timer : Icons.bedtime,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Timer Started' : 'Sleep Timer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        isActive
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: TpsSizes.spaceBtwItems),
                                  GestureDetector(
                                    onTap: () => controller.stopSleepTimer(),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.stop,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                  )
                                ],
                              )
                            : Text(
                                'Setup',
                                style:
                                    themeCtrl.activeTheme.textTheme.bodySmall,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: TpsSizes.spaceBtwItems,
              ),
              Text(
                isActive
                    ? 'Music will pause after timer ends'
                    : 'Drift Off Without a Care: Press play on your calming playlist, set the timer for 30 minutes, and close your eyes.',
                style: themeCtrl.activeTheme.textTheme.bodySmall,
              ),
              // if (!isActive) ...[
              //   Text(
              //     'Drift Off Without a Care: Press play on your calming playlist, set the timer for 30 minutes, and close your eyes.',
              //     style: themeCtrl.activeTheme.textTheme.bodySmall,
              //   ),
              // ],
              if (isActive) ...[
                const SizedBox(height: TpsSizes.spaceBtwItems * 2),
                LinearProgressIndicator(
                  value: controller.sleepTimerProgress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // Widget _buildFunctionalWidgetsSection(HomeController controller) {
  //   return const Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Music Mood Widget
  //       MusicMoodWidget(),
  //       SizedBox(height: 16),

  //       // Quick Stats Widget
  //       QuickStatsWidget(),
  //       SizedBox(height: 16),

  //       // Smart Recommendations Widget
  //       SmartRecommendationsWidget(),
  //       SizedBox(height: 16),

  //       // Music Discovery Widget
  //       MusicDiscoveryWidget(),
  //       SizedBox(height: 16),

  //       // Quick Access Widget
  //       QuickAccessWidget(),
  //     ],
  //   );
  // }

  Widget _buildSectionTitle(String title,
      {VoidCallback? onTap,
      bool showShuffle = false,
      bool showPlay = false,
      bool showMore = false,
      List<SongModel>? songlist}) {
    final controller = Get.find<HomeController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(children: [
          if (showShuffle)
            IconButton(
              onPressed: () => controller.shuffleAllSongs(songlist ?? []),
              icon: const Icon(
                Iconsax.shuffle,
                color: Colors.white70,
                size: 18,
              ),
            ),
          if (showPlay)
            IconButton(
              onPressed: () => controller.playAllSongs(songlist ?? []),
              icon: const Icon(
                Iconsax.play,
                color: Colors.white70,
                size: 18,
              ),
            ),
          if (showMore)
            TextButton(
                onPressed: () {
                  controller.changeView('library');
                  controller.tabController.index = 3;
                },
                child: Text(
                  'Show all'.tr,
                  style: const TextStyle(color: Colors.white70),
                )),
        ]),
      ],
    );
  }

  Widget _buildRecentlyPlayed(HomeController controller) {
    return SizedBox(
      height: 180,
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.recentlyPlayed.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final song = controller.recentlyPlayed[index];
              return _buildSongCard(
                  controller.recentlyPlayed, song, controller);
            },
          )),
    );
  }

  Widget _buildSongCard(
      List<SongModel> songList, SongModel song, HomeController controller) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        debugPrint('Song card tapped: ${song.title} (id: ${song.id})');
        controller.playSong(songList, song);
      },
      child: Container(
        key: ValueKey('song_card_${song.id}'), // Add key to prevent rebuilds
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TpsColors.musicPrimary.withOpacity(0.8),
                    TpsColors.musicSecondary.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FutureBuilder<Uint8List?>(
                key: ValueKey(
                    'card_artwork_${song.id}'), // Add key to prevent rebuilds
                future: controller.getAlbumArtwork(song.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  }
                  return const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMadeForYou(HomeController controller) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          // Get dynamic song counts from generated playlists
          final dailyMix =
              controller.playlistService.generateDailyMix(controller.allSongs);
          final weeklyMix =
              controller.playlistService.generateWeeklyMix(controller.allSongs);
          final releaseRadar = _createReleaseRadar(controller);

          final madeForYouData = [
            {
              'title': 'Daily Mix'.tr,
              'subtitle':
                  'Updated ${controller.playlistService.getDailyMixLastGenerated()}',
              'colors': [const Color(0xFF6C63FF), const Color(0xFF4A4AFF)],
              'songCount': '${dailyMix.length} songs',
            },
            {
              'title': 'Discover Weekly'.tr,
              'subtitle':
                  'Updated ${controller.playlistService.getWeeklyMixLastGenerated()}',
              'colors': [const Color(0xFFFF6B6B), const Color(0xFFE53E3E)],
              'songCount': '${weeklyMix.length} songs',
            },
            {
              'title': 'Release Radar'.tr,
              'subtitle': 'Made for You'.tr,
              'colors': [const Color(0xFF4ECDC4), const Color(0xFF38B2AC)],
              'songCount': '${releaseRadar.length} songs',
            },
          ];

          final data = madeForYouData[index];

          return GestureDetector(
            onTap: () {
              // Handle tap to play the personalized playlist
              _handleMadeForYouTap(controller, index);
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data['colors'] as List<Color>,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (data['colors'] as List<Color>)[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section with play icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    // Bottom section with text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['songCount'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMadeForYouTap(HomeController controller, int index) {
    // Create personalized playlists based on user's music library
    List<SongModel> personalizedSongs = [];

    switch (index) {
      case 0: // Daily Mix 1 - Mix of user's most played and recent songs
        personalizedSongs = _createDailyMix(controller);
        break;
      case 1: // Discover Weekly - Mix of different genres and artists
        personalizedSongs = _createDiscoverWeekly(controller);
        break;
      case 2: // Release Radar - Recently added songs
        personalizedSongs = _createReleaseRadar(controller);
        break;
    }

    if (personalizedSongs.isNotEmpty) {
      // Set the playlist and start playing
      controller.playSong(personalizedSongs, personalizedSongs.first);
    }
  }

  List<SongModel> _createDailyMix(HomeController controller) {
    // Use the enhanced daily mix generation from PlaylistService
    return controller.playlistService.generateDailyMix(controller.allSongs);
  }

  List<SongModel> _createDiscoverWeekly(HomeController controller) {
    // Use the enhanced weekly mix generation from PlaylistService
    return controller.playlistService.generateWeeklyMix(controller.allSongs);
  }

  List<SongModel> _createReleaseRadar(HomeController controller) {
    // Simulate recently added songs (mix of different artists)
    final List<SongModel> radar = [];
    final allSongs = List<SongModel>.from(controller.allSongs);

    // Group by artist for variety
    final Map<String, List<SongModel>> songsByArtist = {};
    for (final song in allSongs) {
      songsByArtist[song.artist] = songsByArtist[song.artist] ?? [];
      songsByArtist[song.artist]!.add(song);
    }

    // Take 1-2 songs from each artist to simulate new releases
    for (final artist in songsByArtist.keys) {
      if (radar.length >= 20) break;
      final artistSongs = songsByArtist[artist]!;
      artistSongs.shuffle();
      radar.addAll(artistSongs.take(2));
    }

    // If we don't have enough songs, fill with random ones
    if (radar.length < 20) {
      final remaining = 20 - radar.length;
      final availableSongs = allSongs
          .where((song) => !radar.any((radarSong) => radarSong.id == song.id))
          .toList();
      availableSongs.shuffle();
      radar.addAll(availableSongs.take(remaining));
    }

    return radar.take(20).toList();
  }

  Widget _buildAllSongsPreview(HomeController controller) {
    return SizedBox(
      height: 180,
      child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.allSongs.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final song = controller.allSongs[index];
              return _buildSongCard(controller.allSongs, song, controller);
            },
          )),
    );
  }

  Widget _buildPlaylists(HomeController controller) {
    return Obx(() => Column(
          children: controller.userPlaylists
              .take(3)
              .map((playlist) => _buildPlaylistItem(playlist, controller))
              .toList(),
        ));
  }

  Widget _buildPlaylistItem(PlaylistModel playlist, HomeController controller) {
    return GestureDetector(
      onTap: () => _showPlaylistSongs(playlist),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [TpsColors.musicPrimary, TpsColors.musicSecondary],
                ),
              ),
              child: const Icon(Icons.queue_music, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${playlist.songCount} songs • ${playlist.formattedTotalDuration}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Builder(
                builder: (context) => Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: TpsColors.musicPrimary.withOpacity(0.22),
                        highlightColor:
                            TpsColors.musicPrimary.withOpacity(0.12),
                        hoverColor: TpsColors.musicPrimary.withOpacity(0.08),
                        popupMenuTheme: const PopupMenuThemeData(
                          surfaceTintColor: Colors.transparent,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handlePlaylistMenuAction(value, playlist),
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        elevation: 0,
                        color: TpsColors.darkGrey.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Edit Playlist',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete Playlist',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSongs(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();

    controller.showPlaylistSongs(playlist);
  }

  void _handlePlaylistMenuAction(String action, PlaylistModel playlist) {
    switch (action) {
      case 'edit':
        _showEditPlaylistDialog(playlist);
        break;
      case 'delete':
        _showDeletePlaylistDialog(playlist);
        break;
    }
  }

  void _showEditPlaylistDialog(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();
    Get.dialog(
      EditPlaylistDialog(
        playlist: playlist,
        onUpdatePlaylist: (name, description, color) async {
          try {
            await controller.updatePlaylistDetails(
              playlistId: playlist.id,
              name: name,
              description: description,
              colorHex: color,
            );
            TpsLoader.customToast(message: 'Playlist updated successfully!');
            // Get.snackbar(
            //   'Success',
            //   'Playlist updated successfully!',
            //   backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
            //   colorText: Colors.white,
            // );
          } catch (e) {
            TpsLoader.customToast(message: 'Failed to update playlist: $e');
            // Get.snackbar(
            //   'Error',
            //   'Failed to update playlist: $e',
            //   backgroundColor: Colors.red.withOpacity(0.8),
            //   colorText: Colors.white,
            // );
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist) {
    final controller = Get.find<HomeController>();
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: TpsColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await controller.deletePlaylist(playlist.id);
                Navigator.pop(Get.context!);
                TpsLoader.customToast(
                    message: 'Playlist deleted successfully!');
              } catch (e) {
                TpsLoader.customToast(message: 'Failed to delete playlist: $e');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView(HomeController controller) {
    return SearchView(controller: controller);
  }

  Widget _buildLibraryView(HomeController controller) {
    return LibraryView(controller: controller);
  }

  Widget _buildProfileView(HomeController controller) {
    return ProfileView(controller: controller);
  }

  Widget _buildCurrentView(HomeController controller, bool isTablet) {
    // Get the current view index
    int currentIndex = 0;
    switch (controller.currentView.value) {
      case 'search':
        currentIndex = 1;
        break;
      case 'library':
        currentIndex = 2;
        break;
      case 'profile':
        currentIndex = 3;
        break;
      default: // 'home'
        currentIndex = 0;
        break;
    }

    // Use IndexedStack to preserve scroll state
    return IndexedStack(
      index: currentIndex,
      children: [
        // Home view
        Container(
          key: const ValueKey('home'),
          child: _buildHomeView(controller, isTablet),
        ),
        // Search view
        Container(
          key: const ValueKey('search'),
          child: _buildSearchView(controller),
        ),
        // Library view
        Container(
          key: const ValueKey('library'),
          child: _buildLibraryView(controller),
        ),
        // Profile view
        Container(
          key: const ValueKey('profile'),
          child: _buildProfileView(controller),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(HomeController controller) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: TpsSizes.defaultSpace * 2),
      child: Container(
        // padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
        decoration: BoxDecoration(
          color: TpsColors.dark.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Obx(() => Row(
                  children: [
                    _buildNavItem(
                      Icons.home,
                      'Home',
                      controller.currentView.value == 'home',
                      () => controller.changeView('home'),
                    ),
                    _buildNavItem(
                      Icons.search,
                      'Search',
                      controller.currentView.value == 'search',
                      () => controller.changeView('search'),
                    ),
                    _buildNavItem(
                      Icons.library_music,
                      'Library',
                      controller.currentView.value == 'library',
                      () => controller.changeView('library'),
                    ),
                    _buildNavItem(
                      Icons.person,
                      'Profile',
                      controller.currentView.value == 'profile',
                      () => controller.changeView('profile'),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(2),
                child: Icon(
                  icon,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  size: isActive ? 22 : 20,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.5),
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
