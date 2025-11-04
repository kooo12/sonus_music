import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:music_player/app/data/models/eq_band.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import 'equalizer_adapter.dart';
import 'storage_service.dart';
import '../models/song_model.dart' as models;
import 'achievement_service.dart';
import 'auth_service.dart';
import 'listening_stats_service.dart';

// Repeat mode for internal player logic
enum RepeatModeAS { off, all, one }

class AudioPlayerService extends GetxService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Observable variables
  final RxList<models.SongModel> _allSongs = <models.SongModel>[].obs;
  final Rx<models.SongModel?> _currentSong = Rx<models.SongModel?>(null);
  final RxBool _isPlaying = false.obs;
  final RxBool _isLoading = false.obs;
  final RxInt _currentIndex = 0.obs;
  final RxDouble _currentPosition = 0.0.obs;
  final RxDouble _totalDuration = 0.0.obs;
  final RxBool _hasPermission = false.obs;

  // Current playlist tracking
  final RxList<models.SongModel> _currentPlaylist = <models.SongModel>[].obs;
  final RxString _playlistType =
      'all'.obs; // 'all', 'search', 'playlist', 'liked', 'recent'

  // Playback options
  final RxBool _shuffleEnabled = false.obs;
  final Rx<RepeatModeAS> _repeatMode = RepeatModeAS.off.obs;
  final Set<int> _playedIndices = <int>{};

  // Achievement tracking
  final RxInt _songsPlayedCount = 0.obs;
  final RxSet<String> _uniqueArtists = <String>{}.obs;
  final Rx<DateTime> _lastPlayTime = DateTime.now().obs;
  final RxInt _continuousPlayMinutes = 0.obs;

  // Listening stats tracking
  final Rx<DateTime?> _songStartTime = Rx<DateTime?>(null);
  final Rx<Duration> _totalPlayTime = Duration.zero.obs;

  // Getters - expose reactive variables directly for UI reactivity
  RxList<models.SongModel> get allSongs => _allSongs;
  RxBool get isPlaying => _isPlaying;
  RxBool get isLoading => _isLoading;
  models.SongModel? get currentSong => _currentSong.value;
  RxInt get currentIndex => _currentIndex;
  RxDouble get currentPosition => _currentPosition;
  RxDouble get totalDuration => _totalDuration;
  RxBool get hasPermission => _hasPermission;
  AudioPlayer get audioPlayer => _audioPlayer;

  // Current playlist getters
  RxList<models.SongModel> get currentPlaylist => _currentPlaylist;
  RxString get playlistType => _playlistType;
  RxBool get shuffleEnabled => _shuffleEnabled;
  Rx<RepeatModeAS> get repeatMode => _repeatMode;

  set currentSong(models.SongModel? song) => _currentSong.value = song;

  // models.SongModel? get currentSong {
  //   if (_allSongs.isEmpty || _currentIndex.value >= _allSongs.length) {
  //     return null;
  //   }
  //   return _allSongs[_currentIndex.value];
  // }

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
    // Delay permission check to ensure plugin is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      checkPermissions();
    });
  }

  @override
  void onClose() {
    // Track final play time before closing
    if (_songStartTime.value != null) {
      final playDuration = DateTime.now().difference(_songStartTime.value!);
      _totalPlayTime.value = _totalPlayTime.value + playDuration;
      _songStartTime.value = null;
    }

    _audioPlayer.dispose();
    super.onClose();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying.value = state.playing;
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition.value = position.inMilliseconds.toDouble();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration.value = duration.inMilliseconds.toDouble();
      }
    });

    // Listen to sequence state changes (for track changes)
    _audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        debugPrint(
            'AudioService._setupAudioPlayer: Sequence state changed to ${sequenceState.currentIndex}');
        // _currentIndex.value = sequenceState.currentIndex;
      }
    });

    // Listen to processing completion
    _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await _handleTrackCompleted();
      }
    });
  }

  // Equalizer via adapter
  final EqualizerAdapter _eq = EqualizerAdapter();

  Future<void> initEqualizer() async {
    try {
      await _eq.init(0);
    } catch (e) {
      debugPrint('Equalizer init failed: $e');
    }
  }

  Future<bool> isEqualizerAvailable() async {
    try {
      return await _eq.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    try {
      await _eq.setEnabled(enabled);
    } catch (e) {
      debugPrint('Equalizer setEnabled failed: $e');
    }
  }

  Future<List<EqBand>> getBands() async {
    try {
      return await _eq.getBands();
    } catch (e) {
      debugPrint('Equalizer getBands failed: $e');
      return [];
    }
  }

  Future<void> setBandLevel(int band, int level) async {
    try {
      await _eq.setBandLevel(band, level);
    } catch (e) {
      debugPrint('Equalizer setBandLevel failed: $e');
    }
  }

  // Waveform data for visualization
  Future<List<double>> getWaveformData() async {
    try {
      return await _eq.getWaveformData();
    } catch (e) {
      debugPrint('Waveform data failed: $e');
      return [];
    }
  }

  Future<void> checkPermissions() async {
    try {
      if (!Get.isRegistered<StorageService>()) {
        Get.put(StorageService(), permanent: true);
      }

      // Check current permission status
      bool hasPermission = false;
      try {
        hasPermission = await _audioQuery.permissionsStatus();
      } catch (e) {
        debugPrint('Error checking permission status: $e');
        // If permission check fails, wait and try again
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          hasPermission = await _audioQuery.permissionsStatus();
        } catch (e2) {
          debugPrint('Second permission check failed: $e2');
          _hasPermission.value = false;
          return;
        }
      }

      if (!hasPermission) {
        try {
          hasPermission = await _audioQuery.permissionsRequest();
        } catch (e) {
          debugPrint('Error requesting permissions: $e');
          _hasPermission.value = false;
          return;
        }
      }

      _hasPermission.value = hasPermission;
      loadSongs();
    } catch (e) {
      debugPrint('Error in checkPermissions: $e');
      _hasPermission.value = false;
    }
  }

  Future<void> requestPermissions() async {
    try {
      // Add a small delay to ensure plugin is ready
      await Future.delayed(const Duration(milliseconds: 200));

      bool hasPermission = false;
      try {
        hasPermission = await _audioQuery.permissionsStatus();
      } catch (e) {
        debugPrint('Error checking permission status: $e');
        _hasPermission.value = false;
        return;
      }

      if (!hasPermission) {
        try {
          hasPermission = await _audioQuery.permissionsRequest();
        } catch (e) {
          debugPrint('Error requesting permissions: $e');
          _hasPermission.value = false;
          return;
        }
      }

      _hasPermission.value = hasPermission;

      if (_hasPermission.value) {
        await loadSongs();
      } else {
        debugPrint('Audio permissions denied by user');
      }
    } catch (e) {
      debugPrint('Error in requestPermissions: $e');
      _hasPermission.value = false;
    }
  }

  Future<void> loadSongs() async {
    if (!_hasPermission.value) {
      await requestPermissions();
      return;
    }

    try {
      _isLoading.value = true;
      debugPrint('Loading music files...');

      final allSongs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );

      debugPrint('Found ${allSongs.length} total audio files');

      // Filter by selected scan folders if present
      final scanFolders = await Get.find<StorageService>().loadScanFolders();
      bool filterByFolders = scanFolders.isNotEmpty;

      final musicSongs = allSongs
          .where((song) => _isValidMusicFile(song))
          .where((song) => !filterByFolders
              ? true
              : scanFolders.any((f) => song.data.startsWith(f)))
          .map((song) => models.SongModel(
                id: song.id,
                title: song.title,
                artist: song.artist ?? 'Unknown Artist',
                album: song.album ?? 'Unknown Album',
                duration: song.duration ?? 0,
                data: song.data,
                displayName: song.displayName,
                genre: song.genre,
                track: song.track,
                year: null,
                size: song.size,
                isMusic: song.isMusic ?? true,
              ))
          .toList();

      _allSongs.value = musicSongs;
      _currentPlaylist.value = List.from(musicSongs);
      _playlistType.value = 'all';
      debugPrint('Loaded ${musicSongs.length} music files');
    } catch (e) {
      debugPrint('Error loading songs: $e');
      _allSongs.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  // Simple validation for music files
  bool _isValidMusicFile(SongModel song) {
    final duration = song.duration ?? 0;
    final path = song.data.toLowerCase();
    final title = song.title.toLowerCase();

    // Must have valid duration (30+ seconds)
    if (duration < 30000) return false;

    if (_isNotificationSound(path, title, duration)) return false;

    if (!_isMusicFile(path)) return false;

    return true;
  }

  // Helper method to check if a file is a notification sound
  bool _isNotificationSound(String path, String title, int duration) {
    final notificationPaths = [
      '/system/media/audio/notifications',
      '/system/media/audio/alarms',
      '/system/media/audio/ringtones',
      '/system/media/audio/ui',
    ];

    final notificationKeywords = [
      'notification',
      'alarm',
      'ringtone',
      'beep',
      'chime',
      'ding',
      'ping',
      'tone',
      'alert',
      'bell',
      'buzz',
      'click',
      'pop',
      'system',
      'ui_',
      'camera_',
      'lock',
      'unlock',
      'shutter'
    ];

    // Very short duration (less than 10 seconds) is likely a notification
    if (duration < 10000) return true;

    // Check path contains notification directories
    for (final notifPath in notificationPaths) {
      if (path.contains(notifPath)) return true;
    }

    // Check title contains notification keywords
    for (final keyword in notificationKeywords) {
      if (title.contains(keyword)) return true;
    }

    return false;
  }

  // Helper method to check if file extension is a music file
  bool _isMusicFile(String path) {
    final musicExtensions = [
      '.mp3',
      '.m4a',
      '.aac',
      '.wav',
      '.flac',
      '.ogg',
      '.wma',
      '.mp4',
      '.3gp',
      '.amr',
      '.opus'
    ];

    for (final ext in musicExtensions) {
      if (path.endsWith(ext)) return true;
    }

    return false;
  }

  Future<void> playSong(List<models.SongModel> songList, models.SongModel song,
      {String playlistType = 'all'}) async {
    try {
      debugPrint(
          'AudioService.playSong: Looking for song ${song.title} (id: ${song.id}) in ${songList.length} songs');

      // Set current playlist context
      _currentPlaylist.value = List.from(songList);
      _playlistType.value = playlistType;

      // Find the song in the current playlist
      final playlistIndex = songList.indexWhere((s) => s.id == song.id);
      debugPrint(
          'AudioService.playSong: Found song at playlist index $playlistIndex');

      if (playlistIndex != -1) {
        await playAtIndex(songList, playlistIndex);
      } else {
        debugPrint(
            'AudioService.playSong: Song not found in current playlist!');
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> playAtIndex(List<models.SongModel> songList, int index) async {
    try {
      if (index < 0 || index >= songList.length) {
        debugPrint(
            'AudioService.playAtIndex: Invalid index $index (songs length: ${songList.length})');
        return;
      }

      debugPrint(
          'AudioService.playAtIndex: Setting currentIndex from ${_currentIndex.value} to $index');

      _currentIndex.value = index;
      _currentSong.value = songList[index];
      _playedIndices.add(index);

      debugPrint(
          'AudioService.playAtIndex: currentIndex is now ${_currentIndex.value}');
      debugPrint(
          'AudioService.playAtIndex: currentSong is now ${_currentSong.value?.title}');

      // Update current playlist if it's different
      if (_currentPlaylist.value != songList) {
        _currentPlaylist.value = List.from(songList);
        debugPrint(
            'AudioService.playAtIndex: Updated current playlist to ${songList.length} songs');
      }

      debugPrint(
          'AudioService.playAtIndex: Playing song: ${songList[index].title} by ${songList[index].artist} (playlist index: $index)');

      await _audioPlayer.setFilePath(songList[index].data);
      await _audioPlayer.play();

      // Track actual play time start
      _songStartTime.value = DateTime.now();
      _totalPlayTime.value = Duration.zero;

      debugPrint(
          'AudioService.playAtIndex: Successfully started playing ${songList[index].title}');
    } catch (e) {
      debugPrint('Error playing song at index $index: $e');
    }
  }

  Future<void> _handleTrackCompleted() async {
    try {
      // Repeat one: replay same track
      if (_repeatMode.value == RepeatModeAS.one) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        return;
      }

      final playlist = _currentPlaylist;
      if (playlist.isEmpty) {
        return;
      }

      // Shuffle handling
      if (_shuffleEnabled.value) {
        final int length = playlist.length;
        if (_repeatMode.value == RepeatModeAS.all) {
          // Pick any random index
          final next = _pickRandomIndex(length, exclude: _currentIndex.value);
          await playAtIndex(playlist, next);
          return;
        } else {
          // repeat off: play unseen random until exhausted, then stop
          if (_playedIndices.length >= length) {
            await stop();
            return;
          }
          final next = _pickRandomUnplayedIndex(length);
          if (next == null) {
            await stop();
            return;
          }
          await playAtIndex(playlist, next);
          return;
        }
      }

      // Non-shuffle linear handling
      final isLast = _currentIndex.value >= playlist.length - 1;
      if (!isLast) {
        await next();
      } else {
        if (_repeatMode.value == RepeatModeAS.all) {
          await playAtIndex(playlist, 0);
        } else {
          await stop();
        }
      }
    } catch (e) {
      debugPrint('Error handling completion: $e');
    }
  }

  int _pickRandomIndex(int length, {int? exclude}) {
    final now = DateTime.now();
    final rand = (now.microsecondsSinceEpoch ^ now.millisecondsSinceEpoch);
    int seeded = rand % length;
    if (length <= 1) return 0;
    int idx = seeded;
    if (exclude != null && length > 1 && idx == exclude) {
      idx = (idx + 1) % length;
    }
    return idx;
  }

  int? _pickRandomUnplayedIndex(int length) {
    if (_playedIndices.length >= length) return null;
    int idx = DateTime.now().microsecondsSinceEpoch % length;
    for (int attempts = 0; attempts < length; attempts++) {
      final candidate = (idx + attempts) % length;
      if (!_playedIndices.contains(candidate)) return candidate;
    }
    // Fallback: find first unplayed
    for (int i = 0; i < length; i++) {
      if (!_playedIndices.contains(i)) return i;
    }
    return null;
  }

  // External controls for shuffle/repeat options
  void setShuffleEnabled(bool enabled) {
    _shuffleEnabled.value = enabled;
    _playedIndices.clear();
    if (enabled && _currentPlaylist.isNotEmpty) {
      _playedIndices.add(_currentIndex.value);
    }
  }

  void setRepeatMode(RepeatModeAS mode) {
    _repeatMode.value = mode;
  }

  Future<void> play() async {
    try {
      if (currentSong != null) {
        await _audioPlayer.play();
        // Track actual play time start
        _songStartTime.value = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error playing: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      // Track actual play time when pausing
      if (_songStartTime.value != null) {
        final playDuration = DateTime.now().difference(_songStartTime.value!);
        _totalPlayTime.value = _totalPlayTime.value + playDuration;
        _songStartTime.value = null;
      }
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> playPause() async {
    if (_isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    try {
      debugPrint("=== NEXT SONG DEBUG ===");
      debugPrint("_currentIndex.value: ${_currentIndex.value}");
      debugPrint("_currentPlaylist.length: ${_currentPlaylist.length}");
      debugPrint("_currentSong: ${_currentSong.value?.title}");

      // Track play time of current song before moving to next
      if (_songStartTime.value != null) {
        final playDuration = DateTime.now().difference(_songStartTime.value!);
        _totalPlayTime.value = _totalPlayTime.value + playDuration;

        // Track the current song as played before moving to next
        if (_currentSong.value != null) {
          _trackSongPlayed(_currentSong.value!);
        }

        _songStartTime.value = null;
      }

      if (_currentPlaylist.isEmpty) {
        debugPrint("Current playlist is empty, cannot play next");
        return;
      }

      if (_shuffleEnabled.value) {
        final int length = _currentPlaylist.length;
        if (_repeatMode.value == RepeatModeAS.off &&
            _playedIndices.length >= length) {
          debugPrint("Shuffle OFF repeat: all played, stopping");
          await stop();
          return;
        }
        final nextIndex = (_repeatMode.value == RepeatModeAS.off)
            ? (_pickRandomUnplayedIndex(length) ??
                _pickRandomIndex(length, exclude: _currentIndex.value))
            : _pickRandomIndex(length, exclude: _currentIndex.value);
        debugPrint("Shuffle next => $nextIndex");
        await playAtIndex(_currentPlaylist, nextIndex);
      } else {
        // Linear navigation
        if (_currentIndex.value < _currentPlaylist.length - 1) {
          debugPrint("Playing next song at index ${_currentIndex.value + 1}");
          await playAtIndex(_currentPlaylist, _currentIndex.value + 1);
        } else {
          if (_repeatMode.value == RepeatModeAS.all) {
            debugPrint("Looping to first song (index 0)");
            await playAtIndex(_currentPlaylist, 0);
          } else {
            debugPrint("Reached end of list, stopping");
            await stop();
          }
        }
      }
      debugPrint("=== END NEXT SONG DEBUG ===");
    } catch (e) {
      debugPrint('Error playing next song: $e');
    }
  }

  Future<void> previous() async {
    try {
      debugPrint("=== PREVIOUS SONG DEBUG ===");
      debugPrint("_currentIndex.value: ${_currentIndex.value}");
      debugPrint("_currentPlaylist.length: ${_currentPlaylist.length}");
      debugPrint("_currentSong: ${_currentSong.value?.title}");

      // Track play time of current song before moving to previous
      if (_songStartTime.value != null) {
        final playDuration = DateTime.now().difference(_songStartTime.value!);
        _totalPlayTime.value = _totalPlayTime.value + playDuration;

        // Track the current song as played before moving to previous
        if (_currentSong.value != null) {
          _trackSongPlayed(_currentSong.value!);
        }

        _songStartTime.value = null;
      }

      if (_currentPlaylist.isEmpty) {
        debugPrint("Current playlist is empty, cannot play previous");
        return;
      }

      if (_shuffleEnabled.value) {
        final int length = _currentPlaylist.length;
        final prevIndex =
            _pickRandomIndex(length, exclude: _currentIndex.value);
        debugPrint("Shuffle previous => $prevIndex");
        await playAtIndex(_currentPlaylist, prevIndex);
      } else {
        // Linear navigation
        if (_currentIndex.value > 0) {
          debugPrint(
              "Playing previous song at index ${_currentIndex.value - 1}");
          await playAtIndex(_currentPlaylist, _currentIndex.value - 1);
        } else {
          if (_repeatMode.value == RepeatModeAS.all) {
            debugPrint(
                "Looping to last song (index ${_currentPlaylist.length - 1})");
            await playAtIndex(_currentPlaylist, _currentPlaylist.length - 1);
          } else {
            debugPrint("At start of list, stopping");
            await stop();
          }
        }
      }
      debugPrint("=== END PREVIOUS SONG DEBUG ===");
    } catch (e) {
      debugPrint('Error playing previous song: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  // Get album artwork
  Future<Uint8List?> getAlbumArtwork(int songId) async {
    try {
      return await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
    } catch (e) {
      debugPrint('Error getting artwork: $e');
      return null;
    }
  }

  // Search songs
  List<models.SongModel> searchSongs(String query) {
    if (query.isEmpty) return _allSongs;

    return _allSongs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
          song.artist.toLowerCase().contains(query.toLowerCase()) ||
          song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get songs by artist
  List<models.SongModel> getSongsByArtist(String artist) {
    return _allSongs.where((song) => song.artist == artist).toList();
  }

  // Get songs by album
  List<models.SongModel> getSongsByAlbum(String album) {
    return _allSongs.where((song) => song.album == album).toList();
  }

  // Get all artists
  List<String> getAllArtists() {
    return _allSongs.map((song) => song.artist).toSet().toList()..sort();
  }

  // Get all albums
  List<String> getAllAlbums() {
    return _allSongs.map((song) => song.album).toSet().toList()..sort();
  }

  // Set custom playlist
  void setPlaylist(List<models.SongModel> playlist, String type) {
    _currentPlaylist.value = List.from(playlist);
    _playlistType.value = type;
    debugPrint('Playlist set: $type with ${playlist.length} songs');
  }

  // Get current playlist info
  String getPlaylistInfo() {
    return '${_playlistType.value}: ${_currentPlaylist.length} songs';
  }

  // =====================
  // Queue manipulation
  // =====================
  void clearQueue() {
    _currentPlaylist.clear();
    _currentIndex.value = 0;
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _currentPlaylist.length) return;
    final wasBeforeCurrent = index < _currentIndex.value;
    _currentPlaylist.removeAt(index);
    if (_currentPlaylist.isEmpty) {
      _currentIndex.value = 0;
      return;
    }
    if (wasBeforeCurrent) {
      _currentIndex.value =
          (_currentIndex.value - 1).clamp(0, _currentPlaylist.length - 1);
    } else if (_currentIndex.value >= _currentPlaylist.length) {
      _currentIndex.value = _currentPlaylist.length - 1;
    }
  }

  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _currentPlaylist.length) return;
    if (newIndex < 0 || newIndex >= _currentPlaylist.length) return;
    final item = _currentPlaylist.removeAt(oldIndex);
    _currentPlaylist.insert(newIndex, item);
    // Adjust current index to keep pointing to the same song after reordering
    if (_currentIndex.value == oldIndex) {
      _currentIndex.value = newIndex;
    } else if (oldIndex < _currentIndex.value &&
        newIndex >= _currentIndex.value) {
      _currentIndex.value -= 1;
    } else if (oldIndex > _currentIndex.value &&
        newIndex <= _currentIndex.value) {
      _currentIndex.value += 1;
    }
  }

  // =====================
  // Achievement tracking
  // =====================
  void _trackSongPlayed(models.SongModel song) {
    try {
      // Only track if we actually played the song for a meaningful duration
      // This prevents counting songs that were immediately skipped
      final actualPlayTime = _totalPlayTime.value;
      final songDuration = Duration(seconds: song.duration);

      // Only count as "played" if we listened for at least 10 seconds or 10% of the song
      const minPlayTime = Duration(seconds: 10);
      final minPlayPercentage = songDuration.inSeconds * 0.1;

      if (actualPlayTime.inSeconds >= minPlayTime.inSeconds ||
          actualPlayTime.inSeconds >= minPlayPercentage) {
        // Increment songs played count
        _songsPlayedCount.value++;

        // Track unique artists
        if (song.artist.isNotEmpty) {
          _uniqueArtists.add(song.artist);
        }

        // Track time-based achievements
        final now = DateTime.now();
        final lastPlay = _lastPlayTime.value;

        // Check for night owl achievement (after midnight)
        if (now.hour >= 0 && now.hour < 6) {
          _checkTimeBasedAchievement('night_plays', 1);
        }

        // Check for early bird achievement (before 6 AM)
        if (now.hour >= 5 && now.hour < 8) {
          _checkTimeBasedAchievement('morning_plays', 1);
        }

        // Track continuous play time
        final timeDiff = now.difference(lastPlay).inMinutes;
        if (timeDiff <= 5) {
          // Within 5 minutes of last play
          _continuousPlayMinutes.value += timeDiff;
        } else {
          _continuousPlayMinutes.value = 0; // Reset if gap too long
        }

        _lastPlayTime.value = now;

        // Check achievements
        _checkAchievements();

        // Track listening statistics with actual play time
        _trackListeningStats(song);

        debugPrint(
            'Tracked song play: ${song.title} - Actual play time: ${actualPlayTime.inSeconds}s');
      } else {
        debugPrint(
            'Skipped song tracking: ${song.title} - Play time too short: ${actualPlayTime.inSeconds}s');
      }
    } catch (e) {
      debugPrint('Error tracking song played: $e');
    }
  }

  void _trackListeningStats(models.SongModel song) {
    try {
      if (Get.isRegistered<ListeningStatsService>()) {
        final statsService = Get.find<ListeningStatsService>();

        // Calculate actual play time from accumulated total
        Duration actualPlayTime = _totalPlayTime.value;

        // Cap the play time at the song's total duration to avoid over-counting
        final songDuration = Duration(seconds: song.duration);
        if (actualPlayTime > songDuration) {
          actualPlayTime = songDuration;
        }

        statsService.trackSongPlay(song, actualPlayTime);

        // Reset play time tracking for next song
        _totalPlayTime.value = Duration.zero;
        _songStartTime.value = null;
      }
    } catch (e) {
      debugPrint('Error tracking listening stats: $e');
    }
  }

  void _checkTimeBasedAchievement(String key, int value) {
    try {
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();

        // Get user ID (use 'guest' for non-logged in users)
        String userId = 'guest';
        try {
          final auth = Get.find<AuthService>();
          final user = auth.firebaseUser.value;
          if (user != null) {
            userId = user.uid;
          }
        } catch (e) {
          // AuthService not registered or no user, use guest
        }

        final stats = {key: value};
        achievementService.checkAchievements(userId, stats);
      }
    } catch (e) {
      debugPrint('Error checking time-based achievement: $e');
    }
  }

  void _checkAchievements() {
    try {
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();

        // Get user ID (use 'guest' for non-logged in users)
        String userId = 'guest';
        try {
          final auth = Get.find<AuthService>();
          final user = auth.firebaseUser.value;
          if (user != null) {
            userId = user.uid;
          }
        } catch (e) {
          // AuthService not registered or no user, use guest
        }

        final stats = {
          'songs_played': _songsPlayedCount.value,
          'unique_artists': _uniqueArtists.length,
          'total_songs': _allSongs.length,
          'continuous_listen_minutes': _continuousPlayMinutes.value,
        };

        // Add time-based stats
        final now = DateTime.now();
        if (now.hour >= 0 && now.hour < 6) {
          stats['night_plays'] = 1;
        }
        if (now.hour >= 5 && now.hour < 8) {
          stats['morning_plays'] = 1;
        }

        achievementService.checkAchievements(userId, stats);
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  // Getters for achievement data
  int get songsPlayedCount => _songsPlayedCount.value;
  int get uniqueArtistsCount => _uniqueArtists.length;
  int get continuousPlayMinutes => _continuousPlayMinutes.value;
}
