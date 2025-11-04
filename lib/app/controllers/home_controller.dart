import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/theme_controller.dart';
import 'package:music_player/app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/song_model.dart';
import '../data/models/playlist_model.dart';
import '../data/services/audio_service.dart';
import '../data/services/playlist_service.dart';
import '../data/services/sleep_timer_service.dart';
import '../helper_widgets/popups/sleep_timer_dialog.dart';

// Repeat mode states for the player
enum RepeatMode { off, all, one }

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final themeCtrl = Get.find<ThemeController>();
  // Services
  late final AudioPlayerService audioService;
  late final PlaylistService _playlistService;
  late final SleepTimerService _sleepTimerService;

  // Scroll controllers to persist scroll positions across rebuilds/tabs
  late final ScrollController allSongsScrollController;
  late final ScrollController artistsScrollController;
  late final ScrollController albumsScrollController;
  late final ScrollController playlistsScrollController;
  late final TextEditingController searchTextController;

  late TabController _tabController;

  // Observable variables
  final RxString currentView = 'home'.obs; // home, search, library, profile
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxInt playlistsVersion = 0.obs;
  final RxBool isShuffleOn = false.obs;
  final Rx<RepeatMode> repeatMode = RepeatMode.off.obs;

  static const String _prefsKeyRecentSearches = 'recent_searches';

  // Cache for album artwork to prevent constant reloading
  final Map<int, Uint8List?> _artworkCache = {};

  // Reactive current song observable
  // final Rx<SongModel?> _currentSong = Rx<SongModel?>(null);

  // Getters for audio service - now properly reactive
  bool get isPlaying => audioService.isPlaying.value;
  bool get isAudioLoading => audioService.isLoading.value;
  int get currentSongIndex => audioService.currentIndex.value;
  double get currentPosition => audioService.currentPosition.value;
  double get totalDuration => audioService.totalDuration.value;
  bool get hasPermission => audioService.hasPermission.value;
  List<SongModel> get allSongs => audioService.allSongs;

  // Reactive current song getter
  SongModel? get currentSong => audioService.currentSong;
  TabController get tabController => _tabController;

  // Getters for playlist service
  PlaylistService get playlistService => _playlistService;
  List<SongModel> get likedSongs => _playlistService.likedSongs;
  List<SongModel> get recentlyPlayed => _playlistService.recentlyPlayed;
  List<SongModel> get currentPlayList => _playlistService.currentPlayList;
  List<PlaylistModel> get userPlaylists => _playlistService.userPlaylists;
  List<PlaylistModel> get allPlaylists => _playlistService.allPlaylists;

  // Getters for sleep timer service
  SleepTimerService get sleepTimerService => _sleepTimerService;
  bool get isSleepTimerActive => _sleepTimerService.isActive;
  String get sleepTimerFormattedTime => _sleepTimerService.formattedTime;
  double get sleepTimerProgress => _sleepTimerService.progress;

  set currentPlayList(List<SongModel> value) {
    _playlistService.currentPlayList = value;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    // audioService.requestPermissions();
    // _setupReactivity();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize scroll controllers
    allSongsScrollController = ScrollController();
    artistsScrollController = ScrollController();
    albumsScrollController = ScrollController();
    playlistsScrollController = ScrollController();
    searchTextController = TextEditingController();
    _loadRecentSearches();
    audioService.initEqualizer();
  }

  void _initializeServices() {
    try {
      audioService = Get.find<AudioPlayerService>();
      debugPrint('HomeController: Found existing AudioPlayerService instance');
    } catch (e) {
      audioService = Get.put(AudioPlayerService(), permanent: true);
      debugPrint('HomeController: Created new AudioPlayerService instance');
    }

    try {
      _playlistService = Get.find<PlaylistService>();
      debugPrint('HomeController: Found existing PlaylistService instance');
    } catch (e) {
      _playlistService = Get.put(PlaylistService(), permanent: true);
      debugPrint('HomeController: Created new PlaylistService instance');
    }

    try {
      _sleepTimerService = Get.find<SleepTimerService>();
      debugPrint('HomeController: Found existing SleepTimerService instance');
    } catch (e) {
      _sleepTimerService = Get.put(SleepTimerService(), permanent: true);
      debugPrint('HomeController: Created new SleepTimerService instance');
    }
  }

  // Equalizer bridge
  Future<bool> isEqualizerAvailable() => audioService.isEqualizerAvailable();
  Future<void> setEqualizerEnabled(bool enabled) =>
      audioService.setEqualizerEnabled(enabled);
  Future<List<dynamic>> getEqualizerBands() async {
    // Return a simple list of {band, center, min, max, level}
    final bands = await audioService.getBands();
    return bands
        .map((b) => {
              'band': b.band,
              'center': b.center,
              'min': b.minLevel,
              'max': b.maxLevel,
            })
        .toList();
  }

  Future<void> setBandLevel(int band, int level) =>
      audioService.setBandLevel(band, level);

  // Waveform data for visualization
  Future<List<double>> getWaveformData() => audioService.getWaveformData();

  // void _setupReactivity() {
  //   // Listen to currentIndex changes and update current song
  //   ever(audioService.currentIndex, (int index) {
  //     debugPrint('HomeController: currentIndex changed to $index');
  //     final songs = audioService.allSongs;
  //     if (songs.isEmpty || index >= songs.length || index < 0) {
  //       _currentSong.value = null;
  //       debugPrint('HomeController: currentSong set to null');
  //     } else {
  //       _currentSong.value = songs[index];
  //       debugPrint('HomeController: currentSong set to ${songs[index].title}');
  //     }
  //   });
  // }

  // Music player controls
  Future<void> playPause() async {
    await audioService.playPause();
  }

  Future<void> nextSong() async {
    await audioService.next();
    if (currentSong != null) {
      await _playlistService.addToRecentlyPlayed(currentSong!);
      await _playlistService.incrementPlayCount(currentSong!);
    }
  }

  Future<void> previousSong() async {
    await audioService.previous();
    if (currentSong != null) {
      await _playlistService.addToRecentlyPlayed(currentSong!);
      await _playlistService.incrementPlayCount(currentSong!);
    }
  }

  Future<void> seekTo(double positionMs) async {
    await audioService.seekTo(Duration(milliseconds: positionMs.toInt()));
  }

  // Shuffle and Repeat controls (UI state)
  void toggleShuffle() {
    isShuffleOn.value = !isShuffleOn.value;
    audioService.setShuffleEnabled(isShuffleOn.value);
  }

  void cycleRepeatMode() {
    switch (repeatMode.value) {
      case RepeatMode.off:
        repeatMode.value = RepeatMode.all;
        break;
      case RepeatMode.all:
        repeatMode.value = RepeatMode.one;
        break;
      case RepeatMode.one:
        repeatMode.value = RepeatMode.off;
        break;
    }
    // Forward to audio service
    switch (repeatMode.value) {
      case RepeatMode.off:
        audioService.setRepeatMode(RepeatModeAS.off);
        break;
      case RepeatMode.all:
        audioService.setRepeatMode(RepeatModeAS.all);
        break;
      case RepeatMode.one:
        audioService.setRepeatMode(RepeatModeAS.one);
        break;
    }
  }

  Future<void> playSong(List<SongModel> songList, SongModel song) async {
    try {
      debugPrint(
          'HomeController.playSong: Playing ${song.title} by ${song.artist}');
      currentPlayList = songList;
      debugPrint('Current playlist: ${currentPlayList.length} songs');
      await audioService.playSong(songList, song);
      await _playlistService.addToRecentlyPlayed(song);
      await _playlistService.incrementPlayCount(song);
      debugPrint('HomeController.playSong: Completed playing ${song.title}');
    } catch (e) {
      debugPrint('HomeController.playSong: ERROR - $e');
    }
  }

  void playAllSongs(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      playSong(songs, songs.first);
    }
  }

  void shuffleAllSongs(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      final shuffledSongs = List<SongModel>.from(songs)..shuffle();
      playSong(shuffledSongs, shuffledSongs.first);
    }
  }

  // Future<void> playAtIndex(int index) async {
  //   await audioService.playAtIndex(index);
  //   if (currentSong != null) {
  //     await _playlistService.addToRecentlyPlayed(currentSong!);
  //     await _playlistService.incrementPlayCount(currentSong!);
  //   }
  // }

  // Navigation
  void changeView(String view) {
    currentView.value = view;
    if (searchQuery.value.isNotEmpty) {
      updateSearchQuery('');
      searchTextController.clear();
    }
  }

  void titleTapAction(String view, String title) {
    changeView(view);
    if (title == 'All Songs') {
      tabController.index = 0;
    } else if (title == 'Recently Played') {
      tabController.index = 3;
    } else if (title == 'All Artists') {
      tabController.index = 1;
    } else if (title == 'All Albums') {
      tabController.index = 2;
    }
  }

  void showPlaylistSongs(PlaylistModel playlist) {
    final playlistSongs = getPlaylistSongs(playlist.id);

    Get.toNamed(Routes.PLAYLISTSONGSCREEN, arguments: {
      'playlist': playlist,
      'playlistSongs': playlistSongs,
      'controller': this,
    });
  }

  @override
  void onClose() {
    // Dispose scroll controllers
    allSongsScrollController.dispose();
    artistsScrollController.dispose();
    albumsScrollController.dispose();
    playlistsScrollController.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  // Permission handling
  Future<void> requestPermissions() async {
    await audioService.requestPermissions();
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKeyRecentSearches) ?? <String>[];
      recentSearches.assignAll(list);
    } catch (_) {}
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    // Move to front, unique, cap at 10
    final List<String> next = List<String>.from(recentSearches);
    next.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    next.insert(0, trimmed);
    if (next.length > 10) {
      next.removeRange(10, next.length);
    }
    recentSearches.assignAll(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyRecentSearches, next);
    } catch (_) {}
  }

  Future<void> removeRecentSearch(String query) async {
    final List<String> next = List<String>.from(recentSearches)
      ..removeWhere((e) => e == query);
    recentSearches.assignAll(next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKeyRecentSearches, next);
    } catch (_) {}
  }

  Future<void> clearAllRecentSearches() async {
    recentSearches.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyRecentSearches);
    } catch (_) {}
  }

  List<SongModel> get searchResults {
    if (searchQuery.value.isEmpty) return allSongs;
    return audioService.searchSongs(searchQuery.value);
  }

  // Playlist management
  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    List<SongModel>? initialSongs,
    String? colorHex,
  }) async {
    return await _playlistService.createPlaylist(
      name: name,
      description: description,
      initialSongs: initialSongs,
      colorHex: colorHex,
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
  }

  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    await _playlistService.addSongToPlaylist(playlistId, song);
    playlistsVersion.value++;
  }

  Future<void> removeSongFromPlaylist(String playlistId, SongModel song) async {
    await _playlistService.removeSongFromPlaylist(playlistId, song);
    playlistsVersion.value++;
  }

  // Update playlist details
  Future<void> updatePlaylistDetails({
    required String playlistId,
    required String name,
    String? description,
    String? colorHex,
  }) async {
    await _playlistService.updatePlaylistDetails(
      playlistId: playlistId,
      name: name,
      description: description,
      colorHex: colorHex,
    );
  }

  Future<void> toggleLikeSong(SongModel song) async {
    await _playlistService.toggleLikeSong(song);
  }

  bool isSongLiked(SongModel song) {
    return _playlistService.isSongLiked(song);
  }

  // Get songs for a specific playlist
  List<SongModel> getPlaylistSongs(String playlistId) {
    return _playlistService.getPlaylistSongs(playlistId);
  }

  void openFullPlayer(HomeController controller) {
    Get.toNamed(Routes.FULLSCREENPLAYER, arguments: {
      'controller': controller,
    });
  }

  void openLandscapeFullPlayer(HomeController controller) {
    Get.toNamed(Routes.FULLSCREENPLAYERLANDSCAPE, arguments: {
      'controller': controller,
    });
  }

  void openEqualizer(HomeController controller) {
    Get.toNamed(Routes.EQUALIZER);
  }

  void openQueue() {
    Get.toNamed(Routes.QUEUE);
  }

  void toInAppMessagesPage() {
    Get.toNamed(Routes.INAPPMESSAGEPAGE);
  }

  Future<void> launchWeb(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Get suggested playlists based on listening history
  List<PlaylistModel> get suggestedPlaylists {
    return allPlaylists.take(3).toList();
  }

  // Get artists from device
  List<String> get allArtists => audioService.getAllArtists();

  // Get albums from device
  List<String> get allAlbums => audioService.getAllAlbums();

  // Get songs by artist
  List<SongModel> getSongsByArtist(String artist) {
    return audioService.getSongsByArtist(artist);
  }

  // Get songs by album
  List<SongModel> getSongsByAlbum(String album) {
    return audioService.getSongsByAlbum(album);
  }

  // Format time helper
  String formatTime(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get album artwork with caching
  Future<Uint8List?> getAlbumArtwork(int songId) async {
    // Check cache first
    if (_artworkCache.containsKey(songId)) {
      return _artworkCache[songId];
    }

    // Fetch from service and cache
    final artwork = await audioService.getAlbumArtwork(songId);
    _artworkCache[songId] = artwork;

    // Limit cache size to prevent memory issues
    if (_artworkCache.length > 100) {
      final oldestKey = _artworkCache.keys.first;
      _artworkCache.remove(oldestKey);
    }

    return artwork;
  }

  void toAdminDashboard() {
    Get.toNamed(Routes.ADMINDASHBOARDPAGE);
  }

  // Sleep Timer methods
  void startSleepTimer(int minutes) {
    _sleepTimerService.startTimer(minutes);
  }

  void restartSleepTimer() {
    _sleepTimerService.startTimer(_sleepTimerService.lastSelectedMinutes);
  }

  void stopSleepTimer() {
    _sleepTimerService.stopTimer();
  }

  void addTimeToSleepTimer(int minutes) {
    _sleepTimerService.addTime(minutes);
  }

  void showSleepTimerDialog() {
    Get.dialog(
      SleepTimerDialog(),
      barrierDismissible: true,
    );
  }
}
