import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../controllers/listening_stats_controller.dart';

class ListeningStatsWidget extends StatelessWidget {
  final bool isCompact;
  final EdgeInsets? padding;

  const ListeningStatsWidget({
    super.key,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ListeningStatsController>(
      builder: (controller) {
        if (controller.isLoading) {
          return _buildLoadingWidget();
        }

        if (!controller.hasListeningData) {
          return _buildEmptyStateWidget();
        }

        return Container(
          // padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(
            //   color: Theme.of(context).dividerColor.withOpacity(0.2),
            //   width: 1,
            // ),
          ),
          child: isCompact
              ? _buildCompactStats(controller)
              : _buildFullStats(controller, context),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: LoadingWidget()
          // CircularProgressIndicator(),
          ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.theme.dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 48,
            color: Get.theme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Listening Stats',
            style: Get.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start listening to music to see your personalized statistics!',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats(ListeningStatsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem(
          icon: '📈',
          title: 'Your Listening Stats',
          isHeader: true,
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          icon: '⏰',
          title: '${controller.totalHoursThisMonth} listened this month',
        ),
        _buildStatItem(
          icon: '🎤',
          title: 'Top Artist: ${controller.topArtist}',
        ),
        _buildStatItem(
          icon: '🎵',
          title:
              'Most Played: ${controller.mostPlayedSongTitle} (${controller.mostPlayedSongCount} plays)',
        ),
        _buildStatItem(
          icon: '🌅',
          title: controller.getTimePatternWithEmoji(),
        ),
        _buildStatItem(
          icon: '📊',
          title: 'Style: ${controller.listeningStyle}',
        ),
      ],
    );
  }

  Widget _buildFullStats(
      ListeningStatsController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            const Text(
              '📈',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your Listening Stats'.tr,
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Obx(() => TextButton(
                  onPressed: () => controller.toggleShowAll(),
                  child: Text(
                    controller.showAll ? 'Hide'.tr : 'Show'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                )),
          ],
        ),
        Obx(() => controller.showAll
            ? AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: controller.fadeAnimation,
                    child: SlideTransition(
                      position: controller.slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Stats Grid
                    _buildStatsGrid(controller, context),

                    // const SizedBox(height: 16),

                    // Time Pattern
                    _buildTimePatternCard(controller),
                  ],
                ),
              )
            : const SizedBox.shrink())
      ],
    );
  }

  Widget _buildStatsGrid(
      ListeningStatsController controller, BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStatCard(
            icon: _getStatIcon(index),
            title: _getStatTitle(index),
            value: _getStatValue(index, controller),
            subtitle: _getStatSubtitle(index, controller),
          ),
        );
      },
    );
  }

  String _getStatIcon(int index) {
    switch (index) {
      case 0:
        return '⏰';
      case 1:
        return '🎤';
      case 2:
        return '🎵';
      case 3:
        return '📊';
      default:
        return '📈';
    }
  }

  String _getStatTitle(int index) {
    switch (index) {
      case 0:
        return 'This Month'.tr;
      case 1:
        return 'Top Artist'.tr;
      case 2:
        return 'Most Played'.tr;
      case 3:
        return 'Style'.tr;
      default:
        return 'Stat'.tr;
    }
  }

  String _getStatValue(int index, ListeningStatsController controller) {
    switch (index) {
      case 0:
        return controller.totalHoursThisMonth;
      case 1:
        return controller.topArtist;
      case 2:
        return controller.mostPlayedSongTitle;
      case 3:
        return controller.listeningStyle;
      default:
        return '';
    }
  }

  String _getStatSubtitle(int index, ListeningStatsController controller) {
    switch (index) {
      case 0:
        return 'listened'.tr;
      case 1:
        return 'most played'.tr;
      case 2:
        return '${controller.mostPlayedSongCount} ${"plays".tr}';
      case 3:
        return controller.listeningStyleDescription;
      default:
        return '';
    }
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Get.theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TpsColors.musicCard.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TpsColors.musicSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color:
                        Get.theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePatternCard(ListeningStatsController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '🌅',
            style: TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Listening Profile'.tr,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.getTimePatternWithEmoji(),
                style: Get.textTheme.bodyMedium?.copyWith(
                  color:
                      Get.theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${"Style:".tr} ${controller.listeningStyle}',
                style: Get.textTheme.bodySmall?.copyWith(
                  color:
                      Get.theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String title,
    bool isHeader = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (!isHeader) ...[
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            icon,
            style: TextStyle(
              fontSize: isHeader ? 20 : 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
