import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/pages/player_widgets/half_screen_player.dart';
import 'package:music_player/app/pages/player_widgets/mini_player.dart';
import 'package:music_player/app/pages/playlist_dialog/add_to_playlist_dialog.dart';
import '../controllers/home_controller.dart';
import '../data/models/song_model.dart';
import '../ui/theme/app_colors.dart';

class ArtistSongsScreen extends StatelessWidget {
  final String artist;
  final List<SongModel> songs;
  final HomeController controller;

  ArtistSongsScreen({
    super.key,
    required this.artist,
    required this.songs,
    required this.controller,
  });

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final firstSong = songs.isNotEmpty ? songs.first : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Determine layout based on screen size and orientation
    final isTablet = screenWidth >= 768; // Tablet breakpoint
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;
    // final isPhoneLandscape = !isTablet && isLandscape;

    return Scaffold(
      backgroundColor: _getArtistBackgroundColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          artist,
          style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _playAllSongs(),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _shuffleAllSongs(),
            icon: const Icon(Icons.shuffle, color: Colors.white),
          ),
        ],
      ),
      body: isTabletLandscape
          ? _landscapedView(firstSong)
          : _portraidView(firstSong),
    );
  }

  Widget _portraidView(SongModel? firstSong) {
    return Stack(
      children: [
        Column(
          children: [
            // Album Info Header
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Album Artwork
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          TpsColors.musicPrimary,
                          TpsColors.musicSecondary
                        ],
                      ),
                    ),
                    child: firstSong != null
                        ? FutureBuilder<Uint8List?>(
                            future: controller.getAlbumArtwork(firstSong.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                );
                              }
                              return const Icon(
                                Icons.album,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          )
                        : const Icon(
                            Icons.album,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 20),
                  // Album Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist,
                          style: themeCtrl.activeTheme.textTheme.headlineMedium!
                              .copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          songs.isNotEmpty
                              ? songs.first.artist
                              : 'Unknown Artist'.tr,
                          style: themeCtrl.activeTheme.textTheme.bodyLarge!
                              .copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} songs • ${_getTotalDuration()}',
                          style: themeCtrl.activeTheme.textTheme.bodyMedium!
                              .copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Songs List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 140,
                ),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return _buildSongListItem(song, index);
                },
              ),
            ),
          ],
        ),
        // Mini Player as overlay
        Positioned(
          bottom: 30,
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

  Widget _landscapedView(SongModel? firstSong) {
    return Row(
      children: [
        // Album Info Header
        Container(
          width: Get.width * 0.3,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Album Artwork
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          TpsColors.musicPrimary,
                          TpsColors.musicSecondary
                        ],
                      ),
                    ),
                    child: firstSong != null
                        ? FutureBuilder<Uint8List?>(
                            future: controller.getAlbumArtwork(firstSong.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                );
                              }
                              return const Icon(
                                Icons.album,
                                color: Colors.white,
                                size: 40,
                              );
                            },
                          )
                        : const Icon(
                            Icons.album,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 20),
                  // Album Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist,
                          style: themeCtrl.activeTheme.textTheme.headlineMedium!
                              .copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          songs.isNotEmpty
                              ? songs.first.artist
                              : 'Unknown Artist'.tr,
                          style: themeCtrl.activeTheme.textTheme.bodyLarge!
                              .copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} songs • ${_getTotalDuration()}',
                          style: themeCtrl.activeTheme.textTheme.bodyMedium!
                              .copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Songs List
              ListView.builder(
                shrinkWrap: true,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return _buildSongListItem(song, index);
                },
              ),
            ],
          ),
        ),
        Expanded(
            child: HalfScreenPlayer(
          controller: controller,
          padding: const EdgeInsets.all(30),
        ))
      ],
    );
  }

  Widget _buildSongListItem(SongModel song, int index) {
    return Container(
      key: ValueKey('artist_song_${song.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Obx(() => Container(
            decoration: BoxDecoration(
              gradient: controller.currentSong?.id == song.id
                  ? LinearGradient(
                      colors: [
                        TpsColors.musicPrimary.withOpacity(0.3),
                        TpsColors.musicPrimary.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.currentSong?.id == song.id
                    ? TpsColors.musicPrimary.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: controller.currentSong?.id == song.id
                      ? TpsColors.musicPrimary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              visualDensity: const VisualDensity(vertical: -2),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [TpsColors.musicPrimary, TpsColors.musicSecondary],
                  ),
                ),
                child: FutureBuilder<Uint8List?>(
                  key: ValueKey('artwork_${song.id}'),
                  future: controller.getAlbumArtwork(song.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return const Icon(Icons.music_note, color: Colors.white);
                  },
                ),
              ),
              title: Text(
                song.title,
                style: themeCtrl.activeTheme.textTheme.titleLarge!.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${song.album} • ${song.formattedDuration}',
                style: themeCtrl.activeTheme.textTheme.bodySmall!.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                      builder: (context) => Theme(
                            data: Theme.of(context).copyWith(
                              splashColor:
                                  TpsColors.musicDark.withOpacity(0.22),
                              highlightColor:
                                  TpsColors.musicDark.withOpacity(0.12),
                              hoverColor: TpsColors.musicDark.withOpacity(0.08),
                              popupMenuTheme: const PopupMenuThemeData(
                                surfaceTintColor: Colors.transparent,
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _handleSongMenuAction(value, song),
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              elevation: 0,
                              color: TpsColors.darkerGrey.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.18),
                                    width: 1),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'like',
                                  child: Row(
                                    children: [
                                      Icon(
                                        controller.isSongLiked(song)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: controller.isSongLiked(song)
                                            ? Colors.red
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        controller.isSongLiked(song)
                                            ? 'Unlike'.tr
                                            : 'Like'.tr,
                                        style: controller.themeCtrl.activeTheme
                                            .textTheme.bodySmall!
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'add_to_playlist',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.playlist_add,
                                          size: 20, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Add to Playlist'.tr,
                                        style: controller.themeCtrl.activeTheme
                                            .textTheme.bodySmall!
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
              onTap: () {
                // print('Artist song tapped: ${song.title} (id: ${song.id})');
                controller.playSong(songs, song);
              },
            ),
          )),
    );
  }

  String _getTotalDuration() {
    final totalMs = songs.fold<int>(0, (sum, song) => sum + song.duration);
    final totalMinutes = totalMs ~/ 60000;
    final totalHours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;

    if (totalHours > 0) {
      return '${totalHours}h ${remainingMinutes}m';
    } else {
      return '${totalMinutes}m';
    }
  }

  void _playAllSongs() {
    if (songs.isNotEmpty) {
      controller.playSong(songs, songs.first);
    }
  }

  void _shuffleAllSongs() {
    if (songs.isNotEmpty) {
      final shuffledSongs = List<SongModel>.from(songs)..shuffle();
      controller.playSong(shuffledSongs, shuffledSongs.first);
    }
  }

  void _handleSongMenuAction(String action, SongModel song) {
    switch (action) {
      case 'like':
        controller.toggleLikeSong(song);
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(song);
        break;
    }
  }

  void _showAddToPlaylistDialog(SongModel song) {
    Get.dialog(
      AddToPlaylistDialog(
        song: song,
        controller: controller,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  Color _getArtistBackgroundColor() {
    // Generate a consistent color based on artist name
    final hash = artist.hashCode;
    final colors = [
      const Color(0xFF1A1A2E), // Dark blue-purple
      const Color(0xFF16213E), // Dark blue
      const Color(0xFF0F3460), // Darker blue
      const Color(0xFF2D1B69), // Purple
      const Color(0xFF1B263B), // Dark navy
      const Color(0xFF0D1B2A), // Very dark blue
    ];
    return colors[hash.abs() % colors.length];
  }
}
