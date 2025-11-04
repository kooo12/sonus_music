import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/helper_widgets/popups/loaders.dart';
import 'package:music_player/app/ui/widgets/loading_widget.dart';
import '../controllers/home_controller.dart';
import '../data/models/playlist_model.dart';
import '../data/models/song_model.dart';
import '../ui/theme/app_colors.dart';

class AddSongsToPlaylistScreen extends StatelessWidget {
  final PlaylistModel playlist;
  final HomeController controller;

  AddSongsToPlaylistScreen({
    super.key,
    required this.playlist,
    required this.controller,
  });

  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final addCtrl = Get.put(
        _AddSongsController(controller: controller, playlist: playlist));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          'Add songs'.tr,
          style: themeCtrl.activeTheme.textTheme.titleLarge,
        ),
        actions: [
          Obx(() {
            final count = addCtrl.selectedSongIds.length;
            return TextButton(
              onPressed: count == 0 || addCtrl.isAdding.value
                  ? null
                  : () => addCtrl.addSelectedSongs(),
              child: addCtrl.isAdding.value
                  ? const LoadingWidget()
                  : Text(
                      count > 0 ? 'Add ($count)' : 'Add',
                      style: themeCtrl.activeTheme.textTheme.bodyMedium,
                    ),
            );
          })
        ],
      ),
      body: Column(
        children: [
          // Search field
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: TextField(
              controller: addCtrl.searchController,
              onChanged: (v) => addCtrl.searchQuery.value = v,
              style: themeCtrl.activeTheme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search songs...'.tr,
                hintStyle: themeCtrl.activeTheme.textTheme.bodySmall,
                prefixIcon:
                    Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                suffixIcon: Obx(() => addCtrl.searchQuery.value.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          addCtrl.searchController.clear();
                          addCtrl.searchQuery.value = '';
                        },
                        icon: Icon(Icons.clear,
                            color: Colors.white.withOpacity(0.7)),
                      )
                    : const SizedBox.shrink()),
                border: InputBorder.none,
              ),
            ),
          ),

          // Song list
          Expanded(
            child: Obx(() {
              final songs = addCtrl.filteredSongs;
              if (songs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_music,
                          size: 64, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No songs to add'.tr,
                        style: themeCtrl.activeTheme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 110),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Obx(() => CheckboxListTile(
                          value: addCtrl.selectedSongIds.contains(song.id),
                          onChanged: (_) => addCtrl.toggle(song.id),
                          activeColor: TpsColors.musicPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            song.title,
                            style: themeCtrl.activeTheme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${song.artist} • ${song.album}',
                            style: themeCtrl.activeTheme.textTheme.bodySmall!
                                .copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: SizedBox(
                            width: 48,
                            height: 48,
                            child: FutureBuilder<Uint8List?>(
                              future: controller.getAlbumArtwork(song.id),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(snapshot.data!,
                                        fit: BoxFit.cover),
                                  );
                                }
                                return const Icon(Icons.music_note,
                                    color: Colors.white);
                              },
                            ),
                          ),
                        )),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AddSongsController extends GetxController {
  final HomeController controller;
  final PlaylistModel playlist;

  _AddSongsController({required this.controller, required this.playlist});

  final RxString searchQuery = ''.obs;
  final RxSet<int> selectedSongIds = <int>{}.obs;
  final RxBool isAdding = false.obs;
  late final TextEditingController searchController;

  late final Set<int> existingIds;

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    existingIds =
        controller.getPlaylistSongs(playlist.id).map((e) => e.id).toSet();
  }

  List<SongModel> get filteredSongs {
    final all =
        controller.allSongs.where((s) => !existingIds.contains(s.id)).toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
        .toList();
  }

  void toggle(int songId) {
    if (selectedSongIds.contains(songId)) {
      selectedSongIds.remove(songId);
    } else {
      selectedSongIds.add(songId);
    }
  }

  Future<void> addSelectedSongs() async {
    if (selectedSongIds.isEmpty) return;
    isAdding.value = true;
    try {
      final idList = selectedSongIds.toList();
      for (final song
          in controller.allSongs.where((s) => idList.contains(s.id))) {
        await controller.addSongToPlaylist(playlist.id, song);
      }
      Get.back();
      // Force playlist details to reflect new totals next time it's opened
      // Get.snackbar(
      //   'Success',
      //   'Added ${idList.length} song(s) to "${playlist.name}"',
      //   backgroundColor: TpsColors.musicPrimary.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
      TpsLoader.customToast(
          message: 'Added ${idList.length} song(s) to "${playlist.name}"');
      // Optionally you can navigate to refreshed screen, but caller is already on it
    } catch (e) {
      TpsLoader.customToast(message: 'Failed to add songs: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to add songs: $e',
      //   backgroundColor: Colors.red.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
    } finally {
      isAdding.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
