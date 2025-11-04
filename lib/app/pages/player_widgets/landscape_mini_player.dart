import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';
import 'package:music_player/app/ui/theme/sizes.dart';

class LandscapeMiniPlayer extends StatelessWidget {
  const LandscapeMiniPlayer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final song = controller.currentSong;
      if (song == null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => controller.openLandscapeFullPlayer(controller),
        child: Container(
          key: ValueKey(
              'mini_player_${song.id}'), // Force rebuild when song changes
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),

          decoration: BoxDecoration(
            // Liquid glass background effect
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
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
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Album Art - made smaller for compact look
                  const SizedBox(
                    width: TpsSizes.defaultSpace,
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          TpsColors.musicPrimary,
                          TpsColors.musicSecondary
                        ],
                      ),
                    ),
                    child: FutureBuilder<Uint8List?>(
                      key: ValueKey(
                          'album_art_${song.id}'), // Add key to prevent rebuilds
                      future: controller.getAlbumArtwork(song.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                          );
                        }
                        return const Icon(Icons.music_note,
                            color: Colors.white, size: 20);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Main player row
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Control Buttons - made more compact

                    IconButton(
                      onPressed: () => controller.previousSong(),
                      icon:
                          const Icon(Icons.skip_previous, color: Colors.white),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      onPressed: () => controller.playPause(),
                      icon: Icon(
                        controller.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 28,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      onPressed: () => controller.nextSong(),
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ]),

                  const SizedBox(height: 6),

                  // Progress Bar - made more compact
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Text(
                          controller.formatTime(controller.currentPosition),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 2,
                              thumbShape:
                                  RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape:
                                  RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: controller.totalDuration > 0
                                  ? (controller.currentPosition /
                                          controller.totalDuration)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              onChanged: (value) {
                                final newPosition =
                                    value * controller.totalDuration;
                                controller.seekTo(newPosition);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          controller.formatTime(controller.totalDuration),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
