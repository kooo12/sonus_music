import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import 'package:music_player/app/pages/player_widgets/half_screen_player.dart';
import 'package:music_player/app/pages/player_widgets/mini_player.dart';
import 'package:music_player/app/pages/playlist_dialog/edit_playlist_dialog.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import '../controllers/home_controller.dart';
import '../data/models/song_model.dart';
import '../data/models/playlist_model.dart';
import '../ui/theme/app_colors.dart';

class PlaylistSongsScreen extends StatelessWidget {
  final PlaylistModel playlist;
  final List<SongModel> songs;
  final HomeController controller;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.songs,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Determine layout based on screen size and orientation
    final isTablet = screenWidth >= 768; // Tablet breakpoint
    final isLandscape = orientation == Orientation.landscape;
    final isTabletLandscape = isTablet && isLandscape;
    // final isPhoneLandscape = !isTablet && isLandscape;

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          playlist.name.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
          if (!playlist.isDefault)
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
                        onSelected: (value) => _handlePlaylistMenuAction(value),
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        elevation: 0,
                        color: TpsColors.darknessGrey.withOpacity(0.9),
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
      body: Obx(() {
        // Recompute songs reactively when playlist changes
        final reactiveSongs = controller.getPlaylistSongs(playlist.id);
        return isTabletLandscape
            ? _landscapedView(reactiveSongs)
            : _portraidView(reactiveSongs);
        // Column(
        //   children: [
        //     // Playlist Info Header
        //     Container(
        //       margin: const EdgeInsets.all(20),
        //       padding: const EdgeInsets.all(20),
        //       decoration: BoxDecoration(
        //         gradient: _getPlaylistGradient(),
        //         borderRadius: BorderRadius.circular(20),
        //         border: Border.all(
        //           color: Colors.white.withOpacity(0.3),
        //           width: 1,
        //         ),
        //         boxShadow: [
        //           BoxShadow(
        //             color: _getPlaylistColor().withOpacity(0.3),
        //             blurRadius: 20,
        //             offset: const Offset(0, 10),
        //           ),
        //         ],
        //       ),
        //       child: Row(
        //         children: [
        //           // Playlist Icon
        //           Container(
        //             width: 80,
        //             height: 80,
        //             decoration: BoxDecoration(
        //               borderRadius: BorderRadius.circular(12),
        //               gradient: playlist.isDefault
        //                   ? const LinearGradient(
        //                       colors: [
        //                         TpsColors.musicAccent,
        //                         TpsColors.musicSecondary
        //                       ],
        //                     )
        //                   : playlist.colorHex != null
        //                       ? LinearGradient(
        //                           colors: [
        //                             Color(int.parse('FF${playlist.colorHex!}',
        //                                 radix: 16)),
        //                             Color(int.parse('FF${playlist.colorHex!}',
        //                                     radix: 16))
        //                                 .withOpacity(0.7),
        //                           ],
        //                         )
        //                       : const LinearGradient(
        //                           colors: [
        //                             TpsColors.musicPrimary,
        //                             TpsColors.musicSecondary
        //                           ],
        //                         ),
        //             ),
        //             child: Icon(
        //               playlist.isDefault
        //                   ? Icons.music_note_outlined
        //                   : Icons.queue_music,
        //               color: Colors.white,
        //               size: 40,
        //             ),
        //           ),
        //           const SizedBox(width: 20),
        //           // Playlist Info
        //           Expanded(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text(
        //                   playlist.name,
        //                   style: const TextStyle(
        //                     color: Colors.white,
        //                     fontSize: 24,
        //                     fontWeight: FontWeight.bold,
        //                   ),
        //                 ),
        //                 const SizedBox(height: 8),
        //                 Text(
        //                   '${reactiveSongs.length} songs • ${playlist.formattedTotalDuration}',
        //                   style: TextStyle(
        //                     color: Colors.white.withOpacity(0.7),
        //                     fontSize: 16,
        //                   ),
        //                 ),
        //                 const SizedBox(height: 4),
        //                 Text(
        //                   playlist.isDefault
        //                       ? 'Liked Songs'
        //                       : 'Custom Playlist',
        //                   style: TextStyle(
        //                     color: Colors.white.withOpacity(0.7),
        //                     fontSize: 14,
        //                   ),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //     if (!playlist.isDefault)
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: 20),
        //         child: GestureDetector(
        //           onTap: _openAddSongs,
        //           child: Container(
        //             padding: const EdgeInsets.symmetric(
        //                 horizontal: 16, vertical: 12),
        //             decoration: BoxDecoration(
        //               borderRadius: BorderRadius.circular(30),
        //               gradient: const LinearGradient(
        //                 colors: [
        //                   TpsColors.musicPrimary,
        //                   TpsColors.musicSecondary
        //                 ],
        //               ),
        //               boxShadow: [
        //                 BoxShadow(
        //                   color: TpsColors.musicPrimary.withOpacity(0.25),
        //                   blurRadius: 12,
        //                   offset: const Offset(0, 6),
        //                 ),
        //               ],
        //             ),
        //             child: const Row(
        //               mainAxisSize: MainAxisSize.min,
        //               children: [
        //                 Icon(Icons.add, color: Colors.white, size: 20),
        //                 SizedBox(width: 8),
        //                 Text(
        //                   'Add Songs',
        //                   style: TextStyle(
        //                     color: Colors.white,
        //                     fontWeight: FontWeight.w600,
        //                   ),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //     const SizedBox(height: TpsSizes.spaceBtwItems),
        //     // Songs List
        //     Expanded(
        //       child: reactiveSongs.isEmpty
        //           ? _buildEmptyState()
        //           : ListView.builder(
        //               padding: const EdgeInsets.only(
        //                 left: 20,
        //                 right: 20,
        //                 bottom: 100,
        //               ),
        //               itemCount: reactiveSongs.length,
        //               itemBuilder: (context, index) {
        //                 final song = reactiveSongs[index];
        //                 return _buildSongListItem(song, index, reactiveSongs);
        //               },
        //             ),
        //     ),
        //   ],
        // );
      }),
    );
  }

  Widget _portraidView(List<SongModel> reactiveSongs) {
    return Stack(
      children: [
        Column(
          children: [
            // Album Info Header
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getPlaylistGradient(),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getPlaylistColor().withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Playlist Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: playlist.isDefault
                          ? const LinearGradient(
                              colors: [
                                TpsColors.musicAccent,
                                TpsColors.musicSecondary
                              ],
                            )
                          : playlist.colorHex != null
                              ? LinearGradient(
                                  colors: [
                                    Color(int.parse('FF${playlist.colorHex!}',
                                        radix: 16)),
                                    Color(int.parse('FF${playlist.colorHex!}',
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
                    child: Icon(
                      playlist.isDefault
                          ? Icons.music_note_outlined
                          : Icons.queue_music,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Playlist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reactiveSongs.length} songs • ${playlist.formattedTotalDuration}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist.isDefault ? '' : 'Custom Playlist'.tr,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!playlist.isDefault)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _openAddSongs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          TpsColors.musicPrimary,
                          TpsColors.musicSecondary
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TpsColors.musicPrimary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Songs'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: TpsSizes.spaceBtwItems),
            // Songs List
            Expanded(
              child: reactiveSongs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 140,
                      ),
                      itemCount: reactiveSongs.length,
                      itemBuilder: (context, index) {
                        final song = reactiveSongs[index];
                        return _buildSongListItem(song, index, reactiveSongs);
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

  Widget _landscapedView(List<SongModel> reactiveSongs) {
    return Row(
      children: [
        // Album Info Header
        Container(
          width: Get.width * 0.3,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _getPlaylistGradient(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getPlaylistColor().withOpacity(0.3),
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
                  // Playlist Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: playlist.isDefault
                          ? const LinearGradient(
                              colors: [
                                TpsColors.musicAccent,
                                TpsColors.musicSecondary
                              ],
                            )
                          : playlist.colorHex != null
                              ? LinearGradient(
                                  colors: [
                                    Color(int.parse('FF${playlist.colorHex!}',
                                        radix: 16)),
                                    Color(int.parse('FF${playlist.colorHex!}',
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
                    child: Icon(
                      playlist.isDefault
                          ? Icons.music_note_outlined
                          : Icons.queue_music,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Playlist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${reactiveSongs.length} songs • ${playlist.formattedTotalDuration}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist.isDefault
                              ? 'Liked Songs'
                              : 'Custom Playlist',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!playlist.isDefault)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _openAddSongs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            TpsColors.musicPrimary,
                            TpsColors.musicSecondary
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: TpsColors.musicPrimary.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Songs',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: TpsSizes.spaceBtwItems),
              // Songs List
              Expanded(
                child: reactiveSongs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        // padding: const EdgeInsets.only(
                        //   left: 20,
                        //   right: 20,
                        //   bottom: 100,
                        // ),
                        itemCount: reactiveSongs.length,
                        itemBuilder: (context, index) {
                          final song = reactiveSongs[index];
                          return _buildSongListItem(song, index, reactiveSongs);
                        },
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            playlist.isDefault ? Icons.music_note_outlined : Icons.queue_music,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            playlist.isDefault
                ? 'No liked songs yet'.tr
                : 'No songs in this playlist'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.isDefault
                ? 'Like some songs to see them here'.tr
                : 'Add some songs to this playlist'.tr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongListItem(
      SongModel song, int index, List<SongModel> currentList) {
    return Container(
      key: ValueKey('playlist_song_${song.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Obx(() => Container(
            decoration: BoxDecoration(
              gradient: controller.currentSong?.id == song.id
                  ? LinearGradient(
                      colors: [
                        _getPlaylistColor().withOpacity(0.4),
                        _getPlaylistColor().withOpacity(0.2),
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
                    ? _getPlaylistColor().withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: controller.currentSong?.id == song.id
                      ? _getPlaylistColor().withOpacity(0.2)
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${song.artist} • ${song.album} • ${song.formattedDuration}',
                style: TextStyle(
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
                                  TpsColors.musicPrimary.withOpacity(0.22),
                              highlightColor:
                                  TpsColors.musicPrimary.withOpacity(0.12),
                              hoverColor:
                                  TpsColors.musicPrimary.withOpacity(0.08),
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
                              color: TpsColors.darknessGrey.withOpacity(0.9),
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
                                            ? 'Unlike'
                                            : 'Like',
                                        style: controller.themeCtrl.activeTheme
                                            .textTheme.bodySmall!
                                            .copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!playlist.isDefault)
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Remove from Playlist',
                                          style: controller.themeCtrl
                                              .activeTheme.textTheme.bodySmall!
                                              .copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          )),
                  // PopupMenuButton<String>(
                  //   icon: Icon(
                  //     Icons.more_vert,
                  //     color: Colors.white.withOpacity(0.7),
                  //   ),
                  //   onSelected: (value) => _handleSongMenuAction(value, song),
                  //   itemBuilder: (context) => [
                  //     PopupMenuItem(
                  //       value: 'like',
                  //       child: Row(
                  //         children: [
                  //           Icon(
                  //             controller.isSongLiked(song)
                  //                 ? Icons.favorite
                  //                 : Icons.favorite_border,
                  //             size: 20,
                  //           ),
                  //           const SizedBox(width: 12),
                  //           Text(controller.isSongLiked(song)
                  //               ? 'Unlike'
                  //               : 'Like'),
                  //         ],
                  //       ),
                  //     ),
                  //     if (!playlist.isDefault)
                  //       const PopupMenuItem(
                  //         value: 'remove',
                  //         child: Row(
                  //           children: [
                  //             Icon(Icons.remove_circle_outline, size: 20),
                  //             SizedBox(width: 12),
                  //             Text('Remove from Playlist'),
                  //           ],
                  //         ),
                  //       ),
                  //   ],
                  // ),
                ],
              ),
              onTap: () {
                debugPrint(
                    'Playlist song tapped: ${song.title} (id: ${song.id})');
                controller.playSong(currentList, song);
              },
            ),
          )),
    );
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
      case 'remove':
        _removeFromPlaylist(song);
        break;
    }
  }

  void _removeFromPlaylist(SongModel song) async {
    try {
      await controller.removeSongFromPlaylist(playlist.id, song);
      TpsLoader.customToast(message: 'Removed from "${playlist.name}"');
      // Get.snackbar(
      //   'Success',
      //   'Removed from "${playlist.name}"',
      //   backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
      // Reactive UI will refresh automatically
    } catch (e) {
      TpsLoader.customToast(message: 'Failed to remove from playlist: $e');
    }
  }

  void _handlePlaylistMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditPlaylistDialog(playlist);
        break;
      case 'delete':
        _showDeletePlaylistDialog(playlist);
        break;
      // case 'add':
      //   _openAddSongs();
      //   break;
    }
  }

  void _openAddSongs() {
    Get.toNamed(Routes.ADDSONGTOPLAYLISTSCREEN, arguments: {
      'playlist': playlist,
      'controller': controller,
    });
  }

  void _showEditPlaylistDialog(PlaylistModel playlist) {
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
          } catch (e) {
            TpsLoader.customToast(message: 'Failed to update playlist: $e');
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist) {
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await controller.deletePlaylist(playlist.id);
                Get.back(); // Close dialog
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

  Color _getBackgroundColor() {
    if (playlist.isDefault) {
      // Modern fancy colors for default playlists
      switch (playlist.name.toLowerCase()) {
        case 'liked songs':
          return const Color(0xFF1A1A2E); // Dark blue-purple
        case 'recently played':
          return const Color(0xFF16213E); // Dark blue
        case 'most played':
          return const Color(0xFF0F3460); // Darker blue
        default:
          return const Color(0xFF1A1A2E); // Default dark blue-purple
      }
    } else {
      // Use playlist color for custom playlists
      if (playlist.colorHex != null) {
        return Color(int.parse('FF${playlist.colorHex!}', radix: 16))
            .withOpacity(0.1);
      }
      return const Color(0xFF1A1A2E); // Fallback
    }
  }

  Color _getPlaylistColor() {
    if (playlist.isDefault) {
      switch (playlist.name.toLowerCase()) {
        case 'liked songs':
          return const Color(0xFFE91E63); // Pink
        case 'recently played':
          return const Color(0xFF2196F3); // Blue
        case 'most played':
          return const Color(0xFF4CAF50); // Green
        default:
          return TpsColors.musicPrimary;
      }
    } else {
      if (playlist.colorHex != null) {
        return Color(int.parse('FF${playlist.colorHex!}', radix: 16));
      }
      return TpsColors.musicPrimary;
    }
  }

  LinearGradient _getPlaylistGradient() {
    final color = _getPlaylistColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ],
    );
  }
}
