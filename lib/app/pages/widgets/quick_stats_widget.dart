import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/listening_stats_controller.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class QuickStatsWidget extends StatelessWidget {
  final bool isCompact;

  const QuickStatsWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ListeningStatsController>();

    return Obx(() {
      if (isCompact) {
        return _buildCompactStats(controller);
      }

      return _buildFullStats(controller);
    });
  }

  Widget _buildCompactStats(ListeningStatsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: '⏰',
            value: controller.totalHoursThisMonth,
            label: 'Hours',
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: '🎤',
            value: controller.topArtist,
            label: 'Top Artist',
            color: const Color(0xFFFF6B6B),
            isText: true,
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: '🎵',
            value: controller.mostPlayedSongTitle,
            label: 'Most Played',
            color: const Color(0xFF6C63FF),
            isText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFullStats(ListeningStatsController controller) {
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
                  color: TpsColors.musicPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: TpsColors.musicPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: '⏰',
                  value: controller.totalHoursThisMonth,
                  label: 'Hours This Month',
                  color: const Color(0xFF4ECDC4),
                  subtitle: controller.listeningStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: '🎤',
                  value: controller.topArtist,
                  label: 'Top Artist',
                  color: const Color(0xFFFF6B6B),
                  subtitle: 'Most played',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: '🎵',
                  value: controller.mostPlayedSongTitle,
                  label: 'Most Played Song',
                  color: const Color(0xFF6C63FF),
                  subtitle: '${controller.mostPlayedSongCount} plays',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: '📊',
                  value: controller.listeningStyle,
                  label: 'Listening Style',
                  color: const Color(0xFF9B59B6),
                  subtitle: controller.listeningStyleDescription,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required dynamic value,
    required String label,
    required Color color,
    bool isText = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isText ? value.toString() : value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required dynamic value,
    required String label,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
