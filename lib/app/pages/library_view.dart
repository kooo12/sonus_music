import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:music_player/app/ui/theme/sizes.dart';
import '../../constants.dart';
import '../controllers/home_controller.dart';
import 'package:music_player/app/helper_widgets/popups/glass_dialog.dart';
import '../data/models/song_model.dart';
import '../data/models/playlist_model.dart';
import '../ui/theme/app_colors.dart';
import 'playlist_dialog/create_playlist_dialog.dart';
import 'playlist_dialog/edit_playlist_dialog.dart';
import 'playlist_dialog/add_to_playlist_dialog.dart';

class LibraryView extends StatelessWidget {
  final HomeController controller;

  const LibraryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    var tabbar = TabBar(
      controller: controller.tabController,
      indicator: BoxDecoration(
        color: TpsColors.musicPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.all(10),
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      onTap: (value) => FocusManager.instance.primaryFocus?.unfocus(),
      tabs: const [
        Tab(text: 'All Songs'),
        Tab(text: 'Artists'),
        Tab(text: 'Albums'),
        Tab(text: 'Playlists'),
      ],
    );
    return DefaultTabController(
      length: tabbar.tabs.length,
      child: Column(
        children: [
          // Tab Bar
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: tabbar),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildAllSongsTab(),
                _buildArtistsTab(),
                _buildAlbumsTab(),
                _buildPlaylistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSongsTab() {
    return Obx(() {
      if (controller.allSongs.isEmpty) {
        return _buildEmptyState(
            'No songs found', 'Add some music to your device'.tr);
      }

      return Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchBar(),
          ),

          // Songs List
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: const PageStorageKey('library_allSongs_list'),
              controller: controller.allSongsScrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 170,
              ),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final song = controller.searchResults[index];
                return _buildSongListItem(controller.allSongs, song, index);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      // padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          hintText: 'Search songs, artists, albums...'.tr,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
          ),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  onPressed: () => controller.updateSearchQuery(''),
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.7),
                  ),
                )
              : const SizedBox.shrink()),
        ),
      ),
    );
  }

  Widget _buildSongListItem(
      List<SongModel> songList, SongModel song, int index) {
    return Container(
        key: ValueKey(
            'song_${song.id}'), // Add key to prevent unnecessary rebuilds
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
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.currentSong?.id == song.id
                      ? TpsColors.musicPrimary.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: controller.currentSong?.id == song.id
                        ? TpsColors.musicPrimary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                      colors: [
                        TpsColors.musicPrimary,
                        TpsColors.musicSecondary
                      ],
                    ),
                  ),
                  child: FutureBuilder<Uint8List?>(
                    key: ValueKey(
                        'artwork_${song.id}'), // Add key to prevent rebuilds
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
                  '${song.artist} • ${song.album}',
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
                    Text(
                      song.formattedDuration,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                                color: TpsColors.darkerGrey.withOpacity(0.7),
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
                                          style: controller.themeCtrl
                                              .activeTheme.textTheme.bodySmall!
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
                                        Text('Add to Playlist'.tr,
                                            style: controller
                                                .themeCtrl
                                                .activeTheme
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline,
                                            size: 20, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('Song Details'.tr,
                                            style: controller
                                                .themeCtrl
                                                .activeTheme
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ),
                onTap: () {
                  debugPrint(
                      'Library song tapped: ${song.title} (id: ${song.id})');
                  controller.playSong(songList, song);
                },
              ),
            )));
  }

  Widget _buildArtistsTab() {
    return Obx(() {
      final artists = controller.allArtists;
      if (artists.isEmpty) {
        return _buildEmptyState(
            'No artists found', 'Add some music to see artists');
      }

      return ListView.builder(
        key: const PageStorageKey('library_artists_list'),
        controller: controller.artistsScrollController,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 170, // Extra space under the list
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final artistSongs = controller.getSongsByArtist(artist);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              // contentPadding: const EdgeInsets.all(16),
              visualDensity: const VisualDensity(vertical: -2),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: const LinearGradient(
                    colors: [TpsColors.musicPrimary, TpsColors.musicAccent],
                  ),
                ),
                child: Center(
                  child: Text(
                    artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                artist,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${artistSongs.length} songs',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
              onTap: () => _showArtistSongs(artist, artistSongs),
            ),
          );
        },
      );
    });
  }

  Widget _buildAlbumsTab() {
    return Obx(() {
      final albums = controller.allAlbums;
      if (albums.isEmpty) {
        return _buildEmptyState(
            'No albums found', 'Add some music to see albums');
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: GridView.builder(
          key: const PageStorageKey('library_albums_grid'),
          controller: controller.albumsScrollController,
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: 150,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 4 : 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            final albumSongs = controller.getSongsByAlbum(album);
            final firstSong = albumSongs.isNotEmpty ? albumSongs.first : null;

            return GestureDetector(
              onTap: () => _showAlbumSongs(album, albumSongs),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(12),
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
                                future:
                                    controller.getAlbumArtwork(firstSong.id),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                                      Icons.album,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(
                                  Icons.album,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${albumSongs.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildPlaylistsTab() {
    return Obx(() {
      final allPlaylists = controller.allPlaylists;

      return Column(
        children: [
          // Create Playlist Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  TpsColors.musicGradientStart,
                  TpsColors.musicGradientEnd,
                ]),
                borderRadius:
                    BorderRadius.all(Radius.circular(TpsSizes.borderRadiusLg))),
            child: ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Playlist'.tr,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Playlists List
          Expanded(
            child: allPlaylists.isEmpty
                ? _buildEmptyState(
                    'No playlists yet', 'Create your first playlist'.tr)
                : ListView.builder(
                    key: const PageStorageKey('library_playlists_list'),
                    controller: controller.playlistsScrollController,
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 170, // Extra space under the list
                    ),
                    itemCount: allPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = allPlaylists[index];
                      return _buildPlaylistListItem(playlist);
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildPlaylistListItem(PlaylistModel playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        // contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: playlist.isDefault
                ? const LinearGradient(
                    colors: [TpsColors.musicAccent, TpsColors.musicSecondary],
                  )
                : playlist.colorHex != null
                    ? LinearGradient(
                        colors: [
                          Color(
                              int.parse('FF${playlist.colorHex!}', radix: 16)),
                          Color(int.parse('FF${playlist.colorHex!}', radix: 16))
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
            playlist.isDefault ? Icons.music_note_outlined : Icons.queue_music,
            color: Colors.white,
          ),
        ),
        title: Text(
          playlist.name.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${playlist.songCount} songs • ${playlist.formattedTotalDuration}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        trailing: playlist.isDefault
            ? null
            : Builder(
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
                        color: TpsColors.darkerGrey.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Edit Playlist'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete Playlist'.tr,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

        onTap: () => _showPlaylistSongs(playlist),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSongMenuAction(String action, SongModel song) {
    switch (action) {
      case 'like':
        controller.toggleLikeSong(song);
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(song);
        break;
      case 'details':
        _showSongDetailsDialog(song);
        break;
    }
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

  void _showCreatePlaylistDialog() {
    Get.dialog(
      CreatePlaylistDialog(
        onCreatePlaylist: (name, description, color) async {
          try {
            await controller.createPlaylist(
              name: name,
              description: description,
              colorHex: color,
            );
            TpsLoader.customToast(
                message: 'Playlist "$name" created successfully!');
          } catch (e) {
            TpsLoader.customToast(message: 'Failed to create playlist: $e');
          }
        },
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
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
            TpsLoader.customToast(message: 'Playlist updated successfully!'.tr);
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
        title: Text('Delete Playlist'.tr),
        content: Text(
          '${"Are you sure you want to delete".tr} "${playlist.name}"? ${"This action cannot be undone.".tr}',
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
                    message: 'Playlist deleted successfully!'.tr);
              } catch (e) {
                TpsLoader.customToast(message: 'Failed to delete playlist: $e');
              }
            },
            child: Text(
              'Delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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

  void _showSongDetailsDialog(SongModel song) {
    Get.dialog(
      GlassAlertDialog(
        backgroundColor: TpsColors.darkGrey.withOpacity(0.3),
        textColor: Colors.white,
        title: Text(song.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${song.artist}'),
            Text('Album: ${song.album}'),
            Text('Duration: ${song.formattedDuration}'),
            Text('Size: ${song.formattedSize}'),
            Text('Format: ${song.fileExtension}'),
            if (song.genre != null) Text('Genre: ${song.genre}'),
            const SizedBox(height: 8),
            const Text('Location:'),
            SelectableText(
              song.data,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child:
                Text('Close'.tr, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  void _showArtistSongs(String artist, List<SongModel> songs) {
    Get.toNamed(Routes.ARTISTSONGSCREEN, arguments: {
      'artist': artist,
      'songs': songs,
      'controller': controller,
    });
  }

  void _showAlbumSongs(String album, List<SongModel> songs) {
    Get.toNamed(Routes.ALBUMSONGSCREEN, arguments: {
      'album': album,
      'songs': songs,
      'controller': controller,
    });
  }

  void _showPlaylistSongs(PlaylistModel playlist) {
    final playlistSongs = controller.getPlaylistSongs(playlist.id);
    Get.toNamed(Routes.PLAYLISTSONGSCREEN, arguments: {
      'playlist': playlist,
      'playlistSongs': playlistSongs,
      'controller': controller,
    });
  }
}

// Individual tab widgets with AutomaticKeepAliveClientMixin to preserve scroll positions

// class _AllSongsTab extends StatefulWidget {
//   final HomeController controller;

//   const _AllSongsTab({required this.controller});

//   @override
//   State<_AllSongsTab> createState() => _AllSongsTabState();
// }

// class _AllSongsTabState extends State<_AllSongsTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // Required for AutomaticKeepAliveClientMixin

//     return Obx(() {
//       if (widget.controller.allSongs.isEmpty) {
//         return _buildEmptyState(
//             'No songs found', 'Add some music to your device');
//       }

//       return Column(
//         children: [
//           // Search Bar
//           Container(
//             margin: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(25),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.2),
//                 width: 1,
//               ),
//             ),
//             child: TextField(
//               onChanged: (value) => widget.controller.searchQuery.value = value,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Search songs...',
//                 hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//               ),
//             ),
//           ),

//           // Songs List
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 bottom: 100, // Extra space under the list
//               ),
//               itemCount: widget.controller.searchResults.length,
//               itemBuilder: (context, index) {
//                 final song = widget.controller.searchResults[index];
//                 return _buildSongListItem(song, index);
//               },
//             ),
//           ),
//         ],
//       );
//     });
//   }

Widget _buildEmptyState(String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.music_note,
          size: 64,
          color: Colors.white.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

  // Widget _buildSongListItem(SongModel song, int index) {
  //   return Container(
  //     key: ValueKey('song_${song.id}'),
  //     margin: const EdgeInsets.only(bottom: 8),
  //     child: Obx(() => Container(
  //           decoration: BoxDecoration(
  //             gradient: widget.controller.currentSong?.id == song.id
  //                 ? LinearGradient(
  //                     colors: [
  //                       TpsColors.musicPrimary.withOpacity(0.3),
  //                       TpsColors.musicPrimary.withOpacity(0.1),
  //                     ],
  //                   )
  //                 : LinearGradient(
  //                     begin: Alignment.topLeft,
  //                     end: Alignment.bottomRight,
  //                     colors: [
  //                       Colors.white.withOpacity(0.15),
  //                       Colors.white.withOpacity(0.05),
  //                     ],
  //                   ),
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(
  //               color: widget.controller.currentSong?.id == song.id
  //                   ? TpsColors.musicPrimary.withOpacity(0.5)
  //                   : Colors.white.withOpacity(0.2),
  //               width: 1,
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: widget.controller.currentSong?.id == song.id
  //                     ? TpsColors.musicPrimary.withOpacity(0.2)
  //                     : Colors.black.withOpacity(0.1),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: ListTile(
  //             visualDensity: const VisualDensity(vertical: -2),
  //             contentPadding:
  //                 const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  //             leading: Container(
  //               width: 50,
  //               height: 50,
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(8),
  //                 gradient: const LinearGradient(
  //                   colors: [TpsColors.musicPrimary, TpsColors.musicSecondary],
  //                 ),
  //               ),
  //               child: FutureBuilder<Uint8List?>(
  //                 key: ValueKey('artwork_${song.id}'),
  //                 future: widget.controller.getAlbumArtwork(song.id),
  //                 builder: (context, snapshot) {
  //                   if (snapshot.hasData && snapshot.data != null) {
  //                     return ClipRRect(
  //                       borderRadius: BorderRadius.circular(8),
  //                       child: Image.memory(
  //                         snapshot.data!,
  //                         fit: BoxFit.cover,
  //                       ),
  //                     );
  //                   }
  //                   return const Icon(Icons.music_note, color: Colors.white);
  //                 },
  //               ),
  //             ),
  //             title: Text(
  //               song.title,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //             subtitle: Text(
  //               '${song.artist} • ${song.album}',
  //               style: TextStyle(
  //                 color: Colors.white.withOpacity(0.7),
  //                 fontSize: 12,
  //               ),
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //             trailing: PopupMenuButton<String>(
  //               onSelected: (value) => _handleSongMenuAction(value, song),
  //               icon: Icon(
  //                 Icons.more_vert,
  //                 color: Colors.white.withOpacity(0.7),
  //               ),
  //               itemBuilder: (context) => [
  //                 const PopupMenuItem(
  //                   value: 'like',
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.favorite_border, size: 20),
  //                       SizedBox(width: 12),
  //                       Text('Like'),
  //                     ],
  //                   ),
  //                 ),
  //                 const PopupMenuItem(
  //                   value: 'add_to_playlist',
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.playlist_add, size: 20),
  //                       SizedBox(width: 12),
  //                       Text('Add to Playlist'),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             onTap: () {
  //               debugPrint('Song tapped: ${song.title} (id: ${song.id})');
  //               widget.controller.playSong(widget.controller.allSongs, song);
  //             },
  //           ),
  //         )),
  //   );
  // }

  // void _handleSongMenuAction(String action, SongModel song) {
  //   switch (action) {
  //     case 'like':
  //       widget.controller.toggleLikeSong(song);
  //       break;
  //     case 'add_to_playlist':
  //       _showAddToPlaylistDialog(song);
  //       break;
  //   }
  // }

//   void _showAddToPlaylistDialog(SongModel song) {
//     Get.dialog(
//       AddToPlaylistDialog(
//         song: song,
//         controller: widget.controller,
//       ),
//       barrierDismissible: true,
//       barrierColor: Colors.black54,
//     );
//   }
// }

// class _ArtistsTab extends StatefulWidget {
//   final HomeController controller;

//   const _ArtistsTab({required this.controller});

//   @override
//   State<_ArtistsTab> createState() => _ArtistsTabState();
// }

// class _ArtistsTabState extends State<_ArtistsTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Obx(() {
//       final artists = widget.controller.allArtists;

//       if (artists.isEmpty) {
//         return _buildEmptyState(
//             'No artists found', 'Add some music to see artists');
//       }

//       return ListView.builder(
//         padding: const EdgeInsets.only(
//           top: 20,
//           left: 20,
//           right: 20,
//           bottom: 100, // Extra space under the list
//         ),
//         itemCount: artists.length,
//         itemBuilder: (context, index) {
//           final artist = artists[index];
//           final artistSongs = widget.controller.getSongsByArtist(artist);

//           return GestureDetector(
//             onTap: () => _showArtistSongs(artist, artistSongs),
//             child: Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.white.withOpacity(0.1),
//                     Colors.white.withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: ListTile(
//                 // contentPadding: const EdgeInsets.all(16),
//                 leading: Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(25),
//                     gradient: const LinearGradient(
//                       colors: [TpsColors.musicPrimary, TpsColors.musicAccent],
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 title: Text(
//                   artist,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                 ),
//                 subtitle: Text(
//                   '${artistSongs.length} songs',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.7),
//                     fontSize: 14,
//                   ),
//                 ),
//                 trailing: Icon(
//                   Icons.arrow_forward_ios,
//                   color: Colors.white.withOpacity(0.5),
//                   size: 16,
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     });
//   }

//   Widget _buildEmptyState(String title, String subtitle) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.person,
//             size: 64,
//             color: Colors.white.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showArtistSongs(String artist, List<SongModel> songs) {
//     Get.to(
//       () => ArtistSongsScreen(
//         artist: artist,
//         songs: songs,
//         controller: widget.controller,
//       ),
//       transition: Transition.rightToLeft,
//       duration: const Duration(milliseconds: 300),
//     );
//   }
// }

// class _AlbumsTab extends StatefulWidget {
//   final HomeController controller;

//   const _AlbumsTab({required this.controller});

//   @override
//   State<_AlbumsTab> createState() => _AlbumsTabState();
// }

// class _AlbumsTabState extends State<_AlbumsTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Obx(() {
//       final albums = widget.controller.allAlbums;

//       if (albums.isEmpty) {
//         return _buildEmptyState(
//             'No albums found', 'Add some music to see albums');
//       }

//       return GridView.builder(
//         padding: const EdgeInsets.only(
//           top: 20,
//           left: 20,
//           right: 20,
//           bottom: 150, // Extra space under the list
//         ),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 15,
//           mainAxisSpacing: 15,
//           childAspectRatio: 0.8,
//         ),
//         itemCount: albums.length,
//         itemBuilder: (context, index) {
//           final album = albums[index];
//           final albumSongs = widget.controller.getSongsByAlbum(album);
//           final firstSong = albumSongs.isNotEmpty ? albumSongs.first : null;

//           return GestureDetector(
//             onTap: () => _showAlbumSongs(album, albumSongs),
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.white.withOpacity(0.1),
//                     Colors.white.withOpacity(0.05),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.2),
//                   width: 1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Album Artwork
//                   Expanded(
//                     flex: 3,
//                     child: Container(
//                       width: double.infinity,
//                       margin: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         gradient: const LinearGradient(
//                           colors: [
//                             TpsColors.musicPrimary,
//                             TpsColors.musicSecondary
//                           ],
//                         ),
//                       ),
//                       child: firstSong != null
//                           ? FutureBuilder<Uint8List?>(
//                               future: widget.controller
//                                   .getAlbumArtwork(firstSong.id),
//                               builder: (context, snapshot) {
//                                 if (snapshot.hasData && snapshot.data != null) {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.memory(
//                                       snapshot.data!,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   );
//                                 }
//                                 return const Icon(
//                                   Icons.album,
//                                   color: Colors.white,
//                                   size: 40,
//                                 );
//                               },
//                             )
//                           : const Icon(
//                               Icons.album,
//                               color: Colors.white,
//                               size: 40,
//                             ),
//                     ),
//                   ),
//                   // Album Info
//                   Expanded(
//                     flex: 2,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             album,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${albumSongs.length} songs',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.7),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     });
//   }

//   Widget _buildEmptyState(String title, String subtitle) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.album,
//             size: 64,
//             color: Colors.white.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAlbumSongs(String album, List<SongModel> songs) {
//     Get.to(
//       () => AlbumSongsScreen(
//         album: album,
//         songs: songs,
//         controller: widget.controller,
//       ),
//       transition: Transition.rightToLeft,
//       duration: const Duration(milliseconds: 300),
//     );
//   }
// }

// class _PlaylistsTab extends StatefulWidget {
//   final HomeController controller;

//   const _PlaylistsTab({required this.controller});

//   @override
//   State<_PlaylistsTab> createState() => _PlaylistsTabState();
// }

// class _PlaylistsTabState extends State<_PlaylistsTab>
//     with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true;

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);

//     return Obx(() {
//       final playlists = widget.controller.allPlaylists;

//       if (playlists.isEmpty) {
//         return _buildEmptyState(
//             'No playlists found', 'Create your first playlist');
//       }

//       return ListView.builder(
//         padding: const EdgeInsets.only(
//           top: 20,
//           left: 20,
//           right: 20,
//           bottom: 100, // Extra space under the list
//         ),
//         itemCount: playlists.length,
//         itemBuilder: (context, index) {
//           final playlist = playlists[index];
//           return _buildPlaylistListItem(playlist);
//         },
//       );
//     });
//   }

//   Widget _buildEmptyState(String title, String subtitle) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.queue_music,
//             size: 64,
//             color: Colors.white.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

  // Widget _buildPlaylistListItem(PlaylistModel playlist) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 12),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Colors.white.withOpacity(0.1),
  //           Colors.white.withOpacity(0.05),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(15),
  //       border: Border.all(
  //         color: Colors.white.withOpacity(0.2),
  //         width: 1,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: ListTile(
  //       // contentPadding: const EdgeInsets.all(16),
  //       leading: Container(
  //         width: 50,
  //         height: 50,
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(8),
  //           gradient: playlist.isDefault
  //               ? const LinearGradient(
  //                   colors: [TpsColors.musicAccent, TpsColors.musicSecondary],
  //                 )
  //               : playlist.colorHex != null
  //                   ? LinearGradient(
  //                       colors: [
  //                         Color(
  //                             int.parse('FF${playlist.colorHex!}', radix: 16)),
  //                         Color(int.parse('FF${playlist.colorHex!}', radix: 16))
  //                             .withOpacity(0.7),
  //                       ],
  //                     )
  //                   : const LinearGradient(
  //                       colors: [
  //                         TpsColors.musicPrimary,
  //                         TpsColors.musicSecondary
  //                       ],
  //                     ),
  //         ),
  //         child: Icon(
  //           playlist.isDefault
  //               ? (playlist.name == 'Liked Songs'
  //                   ? Icons.favorite
  //                   : playlist.name == 'Recently Played'
  //                       ? Icons.history
  //                       : Icons.trending_up)
  //               : Icons.queue_music,
  //           color: Colors.white,
  //           size: 24,
  //         ),
  //       ),
  //       title: Text(
  //         playlist.name,
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.w600,
  //           fontSize: 16,
  //         ),
  //       ),
  //       subtitle: Text(
  //         '${playlist.songCount} songs',
  //         style: TextStyle(
  //           color: Colors.white.withOpacity(0.7),
  //           fontSize: 14,
  //         ),
  //       ),
  //       trailing: playlist.isDefault
  //           ? Icon(
  //               Icons.arrow_forward_ios,
  //               color: Colors.white.withOpacity(0.5),
  //               size: 16,
  //             )
  //           : PopupMenuButton<String>(
  //               onSelected: (value) =>
  //                   _handlePlaylistMenuAction(value, playlist),
  //               icon: Icon(
  //                 Icons.more_vert,
  //                 color: Colors.white.withOpacity(0.7),
  //               ),
  //               itemBuilder: (context) => [
  //                 const PopupMenuItem(
  //                   value: 'edit',
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.edit, size: 20),
  //                       SizedBox(width: 12),
  //                       Text('Edit Playlist'),
  //                     ],
  //                   ),
  //                 ),
  //                 const PopupMenuItem(
  //                   value: 'delete',
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.delete, size: 20),
  //                       SizedBox(width: 12),
  //                       Text('Delete Playlist'),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //       onTap: () => _showPlaylistSongs(playlist),
  //     ),
  //   );
  // }

  // void _handlePlaylistMenuAction(String action, PlaylistModel playlist) {
  //   switch (action) {
  //     case 'edit':
  //       _showEditPlaylistDialog(playlist);
  //       break;
  //     case 'delete':
  //       _showDeletePlaylistDialog(playlist);
  //       break;
  //   }
  // }

  // void _showEditPlaylistDialog(PlaylistModel playlist) {
  //   Get.dialog(
  //     EditPlaylistDialog(
  //       playlist: playlist,
  //       onUpdatePlaylist: (name, description, color) async {
  //         try {
  //           await widget.controller.updatePlaylistDetails(
  //             playlistId: playlist.id,
  //             name: name,
  //             description: description,
  //             colorHex: color,
  //           );
  //           Get.snackbar(
  //             'Success',
  //             'Playlist updated successfully!',
  //             backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
  //             colorText: Colors.white,
  //           );
  //         } catch (e) {
  //           Get.snackbar(
  //             'Error',
  //             'Failed to update playlist: $e',
  //             backgroundColor: Colors.red.withOpacity(0.8),
  //             colorText: Colors.white,
  //           );
  //         }
  //       },
  //     ),
  //     barrierDismissible: true,
  //     barrierColor: Colors.black54,
  //   );
  // }

//   void _showDeletePlaylistDialog(PlaylistModel playlist) {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: TpsColors.darkerGrey.withOpacity(0.8),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         title: const Text(
//           'Delete Playlist',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: Text(
//           'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
//           style: TextStyle(color: Colors.white.withOpacity(0.8)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(Get.context!),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 await widget.controller.deletePlaylist(playlist.id);
//                 Get.back(); // Close dialog
//                 Get.snackbar(
//                   'Success',
//                   'Playlist deleted successfully!',
//                   backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
//                   colorText: Colors.white,
//                 );
//               } catch (e) {
//                 Get.snackbar(
//                   'Error',
//                   'Failed to delete playlist: $e',
//                   backgroundColor: Colors.red.withOpacity(0.8),
//                   colorText: Colors.white,
//                 );
//               }
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPlaylistSongs(PlaylistModel playlist) {
//     final playlistSongs = widget.controller.getPlaylistSongs(playlist.id);

//     Get.to(
//       () => PlaylistSongsScreen(
//         playlist: playlist,
//         songs: playlistSongs,
//         controller: widget.controller,
//       ),
//       transition: Transition.rightToLeft,
//       duration: const Duration(milliseconds: 300),
//     );
//   }
// }
