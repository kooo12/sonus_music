import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../controllers/achievement_controller.dart';
import '../../data/models/achievement_model.dart';
import '../../ui/theme/app_colors.dart';
import 'achievement_badge.dart';

class AchievementUnlockOverlay extends StatelessWidget {
  const AchievementUnlockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AchievementController>();

    return Obx(() {
      if (!controller.isUnlockOverlayVisible.value ||
          controller.currentUnlockedAchievement.value == null) {
        return const SizedBox.shrink();
      }

      final achievement = controller.currentUnlockedAchievement.value!;
      final achievementData =
          controller.getAchievementById(achievement.achievementId);

      if (achievementData == null) return const SizedBox.shrink();

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background overlay with blur effect
            GestureDetector(
              onTap: controller.hideUnlockOverlay,
              child: Container(
                color: Colors.black.withOpacity(0.85),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: controller.confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                colors: const [
                  Colors.pink,
                  Colors.purple,
                  Colors.blue,
                  Colors.red,
                  Colors.orange,
                ],
              ),
            ),

            // Floating balloons from bottom
            // ..._buildFloatingBalloons(controller, achievementData),

            // Rays of light effect
            ..._buildRayEffects(controller, achievementData),

            // Achievement badge (modern design)
            Center(
              child: AnimatedBuilder(
                animation: controller.animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: controller.scaleAnimation.value,
                    child: Opacity(
                      opacity: controller.fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * controller.slideAnimation.value),
                        child: _buildModernAchievementBadge(
                            achievementData, controller),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // Modern Badge Design (Circle badge instead of card)
  Widget _buildModernAchievementBadge(
      AchievementModel achievement, AchievementController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing rings around badge
        AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                Container(
                  width: 200 + (20 * controller.animationController.value),
                  height: 200 + (20 * controller.animationController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getRarityColor(achievement.rarity).withOpacity(
                          0.3 * (1 - controller.animationController.value)),
                      width: 3,
                    ),
                  ),
                ),
                // Inner pulsing ring
                Container(
                  width: 180 + (10 * controller.animationController.value),
                  height: 180 + (10 * controller.animationController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getRarityColor(achievement.rarity).withOpacity(
                          0.5 * (1 - controller.animationController.value)),
                      width: 2,
                    ),
                  ),
                ),
                // Main badge
                child!,
              ],
            );
          },
          child: AchievementBadge(
            type: achievement.badgeType,
            rarity: achievement.rarity,
            iconEmoji: achievement.icon,
            size: 160,
          ),
        ),
        const SizedBox(height: 30),

        // Achievement info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Achievement Unlocked" text with shine
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    _getRarityColor(achievement.rarity),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: const Text(
                  '✨ Achievement Unlocked! ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Achievement name
              Text(
                achievement.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                achievement.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Points and rarity badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoChip(
                    '${achievement.points}',
                    Icons.stars,
                    Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    _getRarityName(achievement.rarity),
                    _getRarityIcon(achievement.rarity),
                    _getRarityColor(achievement.rarity),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Floating balloons from bottom
  List<Widget> _buildFloatingBalloons(
      AchievementController controller, AchievementModel achievement) {
    final balloonColors = [
      _getRarityColor(achievement.rarity),
      TpsColors.musicPrimary,
      TpsColors.musicSecondary,
      TpsColors.musicAccent,
      Colors.purple,
      Colors.pink,
    ];

    return List.generate(8, (index) {
      final delay = index * 0.15;
      final baseX = (index * Get.width / 8) + (Get.width * 0.05);
      final color = balloonColors[index % balloonColors.length];

      // Deterministic randomness per balloon (so motion differs per index)
      final rand = math.Random(index * 7919);
      final amp = 12 + rand.nextDouble() * 28; // wobble amplitude
      final freq = 1.5 + rand.nextDouble() * 3.5; // wobble frequency
      final phase = rand.nextDouble() * 2 * math.pi; // phase offset
      final drift = (rand.nextDouble() * 100) - 50; // slow horizontal drift
      final jitterX = (rand.nextDouble() * 60) - 30; // initial x jitter

      return Positioned(
        left: baseX + jitterX,
        bottom: -100,
        child: AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, child) {
            final t =
                (controller.animationController.value - delay).clamp(0.0, 1.0);
            final yOffset = t * (Get.height + 220); // bottom -> top
            // Free-form x movement: wobble + slow drift (never reverses downward)
            final wobble = math.sin(t * freq * math.pi + phase) * amp;
            final slowDrift = drift * t;
            final xMove = wobble + slowDrift;

            return Transform.translate(
              offset: Offset(xMove, -yOffset),
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0), // fade near top
                child: _buildBalloon(color, 30 + (index % 3) * 10),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildBalloon(Color color, double size) {
    return Column(
      children: [
        // Balloon
        Container(
          width: size,
          height: size * 1.2,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.5),
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size / 2),
              topRight: Radius.circular(size / 2),
              bottomLeft: Radius.circular(size / 2),
              bottomRight: Radius.circular(size / 2 * 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
        ),
        // String
        Container(
          width: 1,
          height: size * 0.8,
          color: Colors.white.withOpacity(0.3),
        ),
      ],
    );
  }

  // Rays of light
  List<Widget> _buildRayEffects(
      AchievementController controller, AchievementModel achievement) {
    return List.generate(8, (index) {
      final angle = (index / 8) * 2 * math.pi;

      return Positioned(
        left: Get.width / 2,
        top: Get.height / 2,
        child: AnimatedBuilder(
          animation: controller.animationController,
          builder: (context, child) {
            final progress = controller.animationController.value;
            return Transform.rotate(
              angle: angle + (progress * math.pi / 4),
              child: Opacity(
                opacity: (0.3 * (1 - progress)).clamp(0.0, 1.0),
                child: Container(
                  width: 4,
                  height: 200 * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _getRarityColor(achievement.rarity).withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF6C63FF);
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
}
