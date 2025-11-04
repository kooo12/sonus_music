import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import '../../ui/theme/app_colors.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/add_to_playlist_controller.dart';

class AddToPlaylistDialog extends StatelessWidget {
  final SongModel song;
  final HomeController controller;

  const AddToPlaylistDialog({
    super.key,
    required this.song,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(AddToPlaylistController());
    final dialogController = Get.find<AddToPlaylistController>();

    return AnimatedBuilder(
      animation: dialogController.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: dialogController.scaleAnimation.value,
          child: FadeTransition(
            opacity: dialogController.fadeAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                // margin: const EdgeInsets.all(0),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      TpsColors.musicPrimary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.playlist_add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add to Playlist'.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song.title,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: dialogController.closeDialog,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Playlists List
                        Expanded(
                          child: Obx(() {
                            final playlists = controller.allPlaylists
                                .where((p) => !p.isDefault)
                                .toList();

                            if (playlists.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.queue_music,
                                      size: 64,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No custom playlists'.tr,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create a playlist first'.tr,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = playlists[index];
                                final isInPlaylist =
                                    playlist.songs.contains(song);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: playlist.colorHex != null
                                            ? LinearGradient(
                                                colors: [
                                                  Color(int.parse(
                                                      'FF${playlist.colorHex!}',
                                                      radix: 16)),
                                                  Color(int.parse(
                                                          'FF${playlist.colorHex!}',
                                                          radix: 16))
                                                      .withOpacity(0.7),
                                                ],
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  TpsColors.musicPrimary,
                                                  TpsColors.musicSecondary
                                                ],
                                              ),
                                      ),
                                      child: const Icon(
                                        Icons.queue_music,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${playlist.songCount} songs',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: isInPlaylist
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: TpsColors.musicPrimary,
                                            size: 24,
                                          )
                                        : IconButton(
                                            onPressed: () =>
                                                _addToPlaylist(playlist),
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 24,
                                            ),
                                          ),
                                    onTap: isInPlaylist
                                        ? null
                                        : () => _addToPlaylist(playlist),
                                  ),
                                );
                              },
                            );
                          }),
                        ),

                        // Close Button
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: dialogController.closeDialog,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'Close'.tr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addToPlaylist(PlaylistModel playlist) async {
    try {
      await controller.addSongToPlaylist(playlist.id, song);
      TpsLoader.customToast(message: 'Added to "${playlist.name}"');
      // Get.snackbar(
      //   'Success',
      //   'Added to "${playlist.name}"',
      //   backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
    } catch (e) {
      TpsLoader.customToast(message: 'Failed to add to playlist: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to add to playlist: $e',
      //   backgroundColor: Colors.red.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
    }
  }
}
