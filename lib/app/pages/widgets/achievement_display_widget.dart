import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../../controllers/achievement_controller.dart';
import '../../data/models/achievement_model.dart';
import 'achievement_badge.dart';
import '../../ui/theme/app_colors.dart';

class AchievementDisplayWidget extends StatelessWidget {
  final bool showAll;
  final int? limit;

  const AchievementDisplayWidget({
    super.key,
    this.showAll = false,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AchievementController>();

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingWidget();
      }

      final achievements = showAll
          ? controller.unlockedAchievements
          : controller.unlockedAchievements.take(limit ?? 6).toList();

      if (achievements.isEmpty) {
        return _buildEmptyWidget();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(controller),
          const SizedBox(height: 16),
          _buildAchievementGrid(achievements, controller),
          if (!showAll && controller.unlockedAchievements.length > (limit ?? 6))
            _buildViewAllButton(),
        ],
      );
    });
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(child: LoadingWidget()
          // CircularProgressIndicator(
          //   color: TpsColors.musicPrimary,
          // ),
          ),
    );
  }

  Widget _buildEmptyWidget() {
    final themeCtrl = Get.find<ThemeController>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          // color: Colors.white.withOpacity(0.1),
          // borderRadius: BorderRadius.circular(15),
          // border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No Achievements Yet'.tr,
            style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Start playing music to unlock achievements!'.tr,
            style: themeCtrl.activeTheme.textTheme.titleSmall!
                .copyWith(color: TpsColors.light.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AchievementController controller) {
    final themeCtrl = Get.find<ThemeController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements'.tr,
              style: themeCtrl.activeTheme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.totalAchievements} ${"unlocked".tr} • ${controller.totalPoints} ${"points".tr}',
              style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                color: TpsColors.light.withOpacity(0.5),
              ),
            )
          ],
        ),
        _buildProgressIndicator(controller),
      ],
    );
  }

  Widget _buildProgressIndicator(AchievementController controller) {
    final themeCtrl = Get.find<ThemeController>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up,
            color: TpsColors.musicSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${controller.completionPercentage.toStringAsFixed(0)}%',
            style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(
      List<AchievementModel> achievements, AchievementController controller) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final userAchievement = controller.userAchievements.firstWhereOrNull(
          (ua) => ua.achievementId == achievement.id,
        );
        return _buildAchievementCard(
            achievement, userAchievement, controller, context);
      },
    );
  }

  Widget _buildAchievementCard(
    AchievementModel achievement,
    UserAchievementModel? userAchievement,
    AchievementController controller,
    BuildContext context,
  ) {
    final isNew = userAchievement?.isNew ?? false;

    return GestureDetector(
      onTap: () => _showAchievementDetails(
          achievement, userAchievement, controller, context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive font sizes based on container dimensions
          final containerWidth = constraints.maxWidth;
          final containerHeight = constraints.maxHeight;

          // Base font sizes that scale with container size
          final titleFontSize = _calculateResponsiveFontSize(
            containerWidth,
            containerHeight,
            baseSize: 14.0,
            minSize: 10.0,
            maxSize: 18.0,
          );

          final pointsFontSize = _calculateResponsiveFontSize(
            containerWidth,
            containerHeight,
            baseSize: 12.0,
            minSize: 8.0,
            maxSize: 14.0,
          );

          // Calculate badge size based on container
          final badgeSize =
              _calculateBadgeSize(containerWidth, containerHeight);

          // Calculate spacing based on container height
          final spacing = _calculateSpacing(containerHeight);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(achievement.rarity),
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge shape preview
                        AchievementBadge(
                          type: achievement.badgeType,
                          rarity: achievement.rarity,
                          iconEmoji: achievement.icon,
                          size: badgeSize,
                        ),
                        SizedBox(height: spacing),

                        // Achievement title
                        Text(
                          achievement.title.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: spacing * 0.5),

                        // Points
                        Text(
                          '${achievement.points} pts',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: pointsFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // New badge
                if (isNew)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'NEW'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _calculateResponsiveFontSize(
                            containerWidth,
                            containerHeight,
                            baseSize: 6.0,
                            minSize: 4.0,
                            maxSize: 10.0,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Rarity indicator
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          _getRarityColor(achievement.rarity).withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getRarityIcon(achievement.rarity),
                      color: Colors.white,
                      size: _calculateResponsiveFontSize(
                        containerWidth,
                        containerHeight,
                        baseSize: 12.0,
                        minSize: 8.0,
                        maxSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewAllButton() {
    final themeCtrl = Get.find<ThemeController>();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: () => _showAllAchievements(),
          icon:
              const Icon(Icons.arrow_forward, color: TpsColors.musicSecondary),
          label: Text(
            'View All Achievements'.tr,
            style: themeCtrl.activeTheme.textTheme.bodyLarge!
                .copyWith(color: TpsColors.musicSecondary),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(
      AchievementModel achievement,
      UserAchievementModel? userAchievement,
      AchievementController controller,
      BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Determine layout based on screen size and orientation
    final isTablet = screenWidth >= 768; // Tablet breakpoint
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;

    controller.markAchievementAsViewed(achievement.id);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          width: isTabletLandscape ? Get.width * 0.5 : null,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getGradientColors(achievement.rarity),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievement icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                achievement.title.tr,
                style: themeCtrl.activeTheme.textTheme.headlineLarge!
                    .copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                achievement.description.tr,
                style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
                    color: TpsColors.white.withOpacity(0.9), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Points'.tr, '${achievement.points}'),
                  _buildStatItem(
                      'Rarity'.tr, _getRarityName(achievement.rarity).tr),
                  _buildStatItem(
                      'Category'.tr, achievement.category?.tr ?? 'General'.tr),
                ],
              ),
              const SizedBox(height: 20),

              // Unlock date
              if (userAchievement != null)
                Text(
                  '${"Unlocked".tr}: ${_formatDate(userAchievement.unlockedAt)}',
                  style: themeCtrl.activeTheme.textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

              const SizedBox(height: 20),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(Get.context!),
                child: Text(
                  'Close'.tr,
                  style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final themeCtrl = Get.find<ThemeController>();
    return Column(
      children: [
        Text(
          value,
          style: themeCtrl.activeTheme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label.tr,
          style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showAllAchievements() {
    Get.toNamed('/achievements');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<Color> _getGradientColors(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return [
          TpsColors.musicPrimary.withOpacity(0.8),
          TpsColors.musicSecondary.withOpacity(0.6),
        ];
      case AchievementRarity.rare:
        return [
          const Color(0xFF4A90E2),
          const Color(0xFF7B68EE),
        ];
      case AchievementRarity.epic:
        return [
          const Color(0xFF9B59B6),
          const Color(0xFFE74C3C),
        ];
      case AchievementRarity.legendary:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFF6B35),
        ];
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return TpsColors.musicPrimary;
      case AchievementRarity.rare:
        return const Color(0xFF4A90E2);
      case AchievementRarity.epic:
        return const Color(0xFF9B59B6);
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getRarityIcon(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Icons.circle;
      case AchievementRarity.rare:
        return Icons.diamond;
      case AchievementRarity.epic:
        return Icons.star;
      case AchievementRarity.legendary:
        return Icons.auto_awesome;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  /// Calculate responsive font size based on container dimensions
  double _calculateResponsiveFontSize(
    double containerWidth,
    double containerHeight, {
    required double baseSize,
    required double minSize,
    required double maxSize,
  }) {
    // Use the smaller dimension to ensure text fits well
    final smallerDimension =
        containerWidth < containerHeight ? containerWidth : containerHeight;

    // Scale factor based on container size (adjust these values as needed)
    final scaleFactor = smallerDimension / 100.0; // Base scale on 100px width

    // Calculate responsive size
    double responsiveSize = baseSize * scaleFactor;

    // Clamp between min and max sizes
    return responsiveSize.clamp(minSize, maxSize);
  }

  /// Calculate badge size based on container dimensions
  double _calculateBadgeSize(double containerWidth, double containerHeight) {
    // Badge should be proportional to container size
    final smallerDimension =
        containerWidth < containerHeight ? containerWidth : containerHeight;

    // Badge should be about 40% of the smaller dimension, with min/max limits
    final badgeSize = smallerDimension * 0.4;

    return badgeSize.clamp(30.0, 80.0);
  }

  /// Calculate spacing between elements based on container height
  double _calculateSpacing(double containerHeight) {
    // Spacing should be proportional to container height
    final spacing = containerHeight * 0.05; // 5% of container height

    return spacing.clamp(4.0, 16.0);
  }
}
