import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/helper_widgets/popups/sleep_timer_dialog.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class QuickAccessWidget extends StatelessWidget {
  final bool isCompact;

  const QuickAccessWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactQuickAccess();
    }

    return _buildFullQuickAccess();
  }

  Widget _buildCompactQuickAccess() {
    final quickActions = _getQuickActions();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Quick Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: quickActions
                .take(4)
                .map(
                  (action) => Expanded(
                    child: _buildCompactActionButton(action),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullQuickAccess() {
    final quickActions = _getQuickActions();

    return Container(
      margin: const EdgeInsets.only(right: TpsSizes.defaultSpace),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TpsColors.musicAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: TpsColors.musicAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Frequently used features',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickActions
                .map(
                  (action) => _buildFullActionButton(action),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['onTap'],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: action['color'].withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: action['color'].withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              action['icon'],
              color: action['color'],
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              action['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullActionButton(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['onTap'],
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: action['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action['color'].withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              action['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (action['subtitle'] != null) ...[
              const SizedBox(height: 4),
              Text(
                action['subtitle'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickActions() {
    final controller = Get.find<HomeController>();

    return [
      {
        'title': 'Shuffle All',
        'subtitle': 'Random play',
        'icon': Icons.shuffle,
        'color': const Color(0xFF6C63FF),
        'onTap': () => controller.shuffleAllSongs(controller.allSongs),
      },
      {
        'title': 'Liked Songs',
        'subtitle': '${controller.likedSongs.length} songs',
        'icon': Icons.favorite,
        'color': const Color(0xFFFF6B6B),
        'onTap': () => controller.changeView('library'),
      },
      {
        'title': 'Recently Played',
        'subtitle': '${controller.recentlyPlayed.length} songs',
        'icon': Icons.history,
        'color': const Color(0xFF4ECDC4),
        'onTap': () => controller.changeView('library'),
      },
      {
        'title': 'Playlists',
        'subtitle': '${controller.userPlaylists.length} playlists',
        'icon': Icons.playlist_play,
        'color': const Color(0xFF9B59B6),
        'onTap': () => controller.changeView('library'),
      },
      {
        'title': 'Search',
        'subtitle': 'Find music',
        'icon': Icons.search,
        'color': const Color(0xFFFF9F43),
        'onTap': () => controller.changeView('search'),
      },
      {
        'title': 'Equalizer',
        'subtitle': 'Audio settings',
        'icon': Icons.graphic_eq,
        'color': const Color(0xFF2C3E50),
        'onTap': () => _openEqualizer(controller),
      },
      {
        'title': 'Queue',
        'subtitle': 'Current queue',
        'icon': Icons.queue_music,
        'color': const Color(0xFFE67E22),
        'onTap': () => _openQueue(controller),
      },
      {
        'title': 'Sleep Timer',
        'subtitle': controller.isSleepTimerActive ? 'Active' : 'Set timer',
        'icon': Icons.timer,
        'color': controller.isSleepTimerActive
            ? const Color(0xFF27AE60)
            : const Color(0xFF95A5A6),
        'onTap': () => _openSleepTimer(controller),
      },
    ];
  }

  void _openEqualizer(HomeController controller) {
    Get.toNamed('/equalizer');
  }

  void _openQueue(HomeController controller) {
    Get.toNamed(Routes.QUEUE);
  }

  void _openSleepTimer(HomeController controller) {
    showDialog(
      context: Get.context!,
      builder: (context) => SleepTimerDialog(),
    );
  }
}
