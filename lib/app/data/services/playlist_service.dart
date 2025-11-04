import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import 'audio_service.dart';
import 'achievement_service.dart';
import 'auth_service.dart';

class PlaylistService extends GetxService {
  static const String _playlistsKey = 'user_playlists';
  static const String _likedSongsKey = 'liked_songs';
  static const String _recentlyPlayedKey = 'recently_played';
  // static const String _mostPlayedKey = 'most_played';
  static const String _playCountKey = 'play_count';
  static const String _dailyMixKey = 'daily_mix_data';
  static const String _weeklyMixKey = 'weekly_mix_data';
  static const String _userPreferencesKey = 'user_preferences';

  final RxList<PlaylistModel> _userPlaylists = <PlaylistModel>[].obs;
  final RxList<SongModel> _likedSongs = <SongModel>[].obs;
  final RxList<SongModel> _recentlyPlayed = <SongModel>[].obs;
  final RxList<SongModel> _currentPlayList = <SongModel>[].obs;
  final RxMap<int, int> _playCount = <int, int>{}.obs;

  // User preferences and mix data
  final RxMap<String, dynamic> _userPreferences = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _dailyMixData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _weeklyMixData = <String, dynamic>{}.obs;

  // Getters
  List<PlaylistModel> get userPlaylists => _userPlaylists;
  List<SongModel> get likedSongs => _likedSongs;
  List<SongModel> get recentlyPlayed => _recentlyPlayed;
  List<SongModel> get currentPlayList => _currentPlayList;
  Map<int, int> get playCount => _playCount;

  // Get default playlists
  List<PlaylistModel> get defaultPlaylists {
    return [
      PlaylistModel.likedSongs().copyWith(songs: _likedSongs),
      PlaylistModel.recentlyPlayed().copyWith(songs: _recentlyPlayed),
      PlaylistModel.mostPlayed().copyWith(songs: mostPlayedSongs),
    ];
  }

  // Get all playlists (default + user created)
  List<PlaylistModel> get allPlaylists {
    return [...defaultPlaylists, ..._userPlaylists];
  }

  // Get most played songs
  List<SongModel> get mostPlayedSongs {
    if (_playCount.isEmpty) return [];

    // Sort songs by play count
    final sortedEntries = _playCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 50 most played songs
    return sortedEntries
        .take(50)
        .map((entry) {
          // Find song by ID from all available songs
          return _getSongById(entry.key);
        })
        .where((song) => song != null)
        .cast<SongModel>()
        .toList();
  }

  // Helper method to get song by ID
  SongModel? _getSongById(int songId) {
    // Try to find in liked songs first
    for (final song in _likedSongs) {
      if (song.id == songId) return song;
    }

    // Try to find in recently played
    for (final song in _recentlyPlayed) {
      if (song.id == songId) return song;
    }

    // Try to find in user playlists
    for (final playlist in _userPlaylists) {
      for (final song in playlist.songs) {
        if (song.id == songId) return song;
      }
    }

    // Try to get from AudioService if available
    try {
      final audioService = Get.find<AudioPlayerService>();
      final allSongs = audioService.allSongs;
      for (final song in allSongs) {
        if (song.id == songId) return song;
      }
    } catch (e) {
      debugPrint('AudioService not found: $e');
    }

    return null;
  }

  set currentPlayList(List<SongModel> value) => _currentPlayList.value = value;

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user playlists
      final playlistsJson = prefs.getString(_playlistsKey);
      if (playlistsJson != null) {
        final List<dynamic> playlistsList = json.decode(playlistsJson);
        _userPlaylists.value = playlistsList
            .map((playlistJson) => PlaylistModel.fromJson(playlistJson))
            .toList();
      }

      // Load liked songs
      final likedSongsJson = prefs.getString(_likedSongsKey);
      if (likedSongsJson != null) {
        final List<dynamic> likedSongsList = json.decode(likedSongsJson);
        _likedSongs.value = likedSongsList
            .map((songJson) => SongModel.fromJson(songJson))
            .toList();
      }

      // Load recently played
      final recentlyPlayedJson = prefs.getString(_recentlyPlayedKey);
      if (recentlyPlayedJson != null) {
        final List<dynamic> recentlyPlayedList =
            json.decode(recentlyPlayedJson);
        _recentlyPlayed.value = recentlyPlayedList
            .map((songJson) => SongModel.fromJson(songJson))
            .toList();
      }

      // Load play count
      final playCountJson = prefs.getString(_playCountKey);
      if (playCountJson != null) {
        final Map<String, dynamic> playCountMap = json.decode(playCountJson);
        _playCount.value = playCountMap
            .map((key, value) => MapEntry(int.parse(key), value as int));
      }

      // Load user preferences and mix data
      await _loadUserPreferences();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user playlists
      final playlistsJson =
          json.encode(_userPlaylists.map((p) => p.toJson()).toList());
      await prefs.setString(_playlistsKey, playlistsJson);

      // Save liked songs
      final likedSongsJson =
          json.encode(_likedSongs.map((s) => s.toJson()).toList());
      await prefs.setString(_likedSongsKey, likedSongsJson);

      // Save recently played
      final recentlyPlayedJson =
          json.encode(_recentlyPlayed.map((s) => s.toJson()).toList());
      await prefs.setString(_recentlyPlayedKey, recentlyPlayedJson);

      // Save play count
      final playCountJson = json.encode(
          _playCount.map((key, value) => MapEntry(key.toString(), value)));
      await prefs.setString(_playCountKey, playCountJson);
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  // Create new playlist
  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    List<SongModel>? initialSongs,
    String? colorHex,
  }) async {
    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songs: initialSongs ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorHex: colorHex,
    );

    _userPlaylists.add(playlist);
    await savePlaylists();

    // Track achievement progress
    _trackPlaylistCreated();

    return playlist;
  }

  // Delete playlist
  Future<void> deletePlaylist(String playlistId) async {
    _userPlaylists.removeWhere((playlist) => playlist.id == playlistId);
    await savePlaylists();
  }

  // Update playlist
  Future<void> updatePlaylist(PlaylistModel updatedPlaylist) async {
    final index = _userPlaylists.indexWhere((p) => p.id == updatedPlaylist.id);
    if (index != -1) {
      _userPlaylists[index] =
          updatedPlaylist.copyWith(updatedAt: DateTime.now());
      await savePlaylists();
    }
  }

  // Update playlist with new values
  Future<void> updatePlaylistDetails({
    required String playlistId,
    required String name,
    String? description,
    String? colorHex,
  }) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _userPlaylists[index] = _userPlaylists[index].copyWith(
        name: name,
        description: description,
        colorHex: colorHex,
        updatedAt: DateTime.now(),
      );
      await savePlaylists();
    }
  }

  // Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _userPlaylists[index] = _userPlaylists[index].addSong(song);
      await savePlaylists();
    }
  }

  // Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, SongModel song) async {
    final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _userPlaylists[index] = _userPlaylists[index].removeSong(song);
      await savePlaylists();
    }
  }

  // Like/Unlike song
  Future<void> toggleLikeSong(SongModel song) async {
    if (_likedSongs.contains(song)) {
      _likedSongs.remove(song);
    } else {
      _likedSongs.add(song);
      // Track achievement progress for liking songs
      _trackSongLiked();
    }
    await savePlaylists();
  }

  // Check if song is liked
  bool isSongLiked(SongModel song) {
    return _likedSongs.contains(song);
  }

  // Add to recently played
  Future<void> addToRecentlyPlayed(SongModel song) async {
    // Remove if already exists to avoid duplicates
    _recentlyPlayed.removeWhere((s) => s.id == song.id);

    // Add to beginning
    _recentlyPlayed.insert(0, song);

    // Keep only last 50 songs
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed.removeRange(50, _recentlyPlayed.length);
    }

    await savePlaylists();

    // Update user preferences periodically
    if (_recentlyPlayed.length % 5 == 0) {
      // Update every 5 songs
      await updateUserPreferences();
    }
  }

  // Increment play count
  Future<void> incrementPlayCount(SongModel song) async {
    _playCount[song.id] = (_playCount[song.id] ?? 0) + 1;
    await savePlaylists();
  }

  // Get play count for song
  int getPlayCount(SongModel song) {
    return _playCount[song.id] ?? 0;
  }

  // Get playlist by ID
  PlaylistModel? getPlaylistById(String id) {
    // Check default playlists
    for (final playlist in defaultPlaylists) {
      if (playlist.id == id) return playlist;
    }

    // Check user playlists
    try {
      return _userPlaylists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search playlists
  List<PlaylistModel> searchPlaylists(String query) {
    if (query.isEmpty) return allPlaylists;

    return allPlaylists.where((playlist) {
      return playlist.name.toLowerCase().contains(query.toLowerCase()) ||
          (playlist.description?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  // Get playlists containing song
  List<PlaylistModel> getPlaylistsContainingSong(SongModel song) {
    return allPlaylists
        .where((playlist) => playlist.songs.contains(song))
        .toList();
  }

  // Get songs for a specific playlist by ID
  List<SongModel> getPlaylistSongs(String playlistId) {
    final playlist = getPlaylistById(playlistId);
    return playlist?.songs ?? [];
  }

  // Clear recently played
  Future<void> clearRecentlyPlayed() async {
    _recentlyPlayed.clear();
    await savePlaylists();
  }

  // Clear play count
  Future<void> clearPlayCount() async {
    _playCount.clear();
    await savePlaylists();
  }

  // User Preferences and Personalized Mixes
  Map<String, dynamic> get userPreferences => _userPreferences;
  Map<String, dynamic> get dailyMixData => _dailyMixData;
  Map<String, dynamic> get weeklyMixData => _weeklyMixData;

  // Update user preferences based on listening behavior
  Future<void> updateUserPreferences() async {
    // Analyze listening patterns
    final genreStats = <String, int>{};
    final artistStats = <String, int>{};
    final recentSongs = _recentlyPlayed.take(20).toList();

    // Count genres and artists from recent plays
    for (final song in recentSongs) {
      if (song.genre != null && song.genre!.isNotEmpty) {
        genreStats[song.genre!] = (genreStats[song.genre!] ?? 0) + 1;
      }
      artistStats[song.artist] = (artistStats[song.artist] ?? 0) + 1;
    }

    // Update preferences
    _userPreferences['favoriteGenres'] = genreStats;
    _userPreferences['favoriteArtists'] = artistStats;
    _userPreferences['lastUpdated'] = DateTime.now().toIso8601String();

    await _saveUserPreferences();
  }

  // Generate daily mix based on current user preferences
  List<SongModel> generateDailyMix(List<SongModel> allSongs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we need to regenerate daily mix
    final lastGenerated = _dailyMixData['lastGenerated'];
    if (lastGenerated != null) {
      final lastDate = DateTime.tryParse(lastGenerated);
      if (lastDate != null) {
        final lastGeneratedDate =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (lastGeneratedDate.isAtSameMomentAs(today)) {
          // Return cached daily mix if generated today
          final cachedSongs = _dailyMixData['songs'] as List<dynamic>?;
          if (cachedSongs != null) {
            return _convertToSongList(cachedSongs, allSongs);
          }
        }
      }
    }

    // Generate new daily mix
    final List<SongModel> dailyMix = [];

    // 1. Add recently played songs (30%)
    final recentCount = (50 * 0.3).round();
    dailyMix.addAll(_recentlyPlayed.take(recentCount));

    // 2. Add most played songs (25%)
    final mostPlayedCount = (50 * 0.25).round();
    final mostPlayed = mostPlayedSongs
        .take(mostPlayedCount)
        .where((song) => !dailyMix.any((mixSong) => mixSong.id == song.id))
        .toList();
    dailyMix.addAll(mostPlayed);

    // 3. Add liked songs (20%)
    final likedCount = (50 * 0.2).round();
    final likedSongs = _likedSongs
        .take(likedCount)
        .where((song) => !dailyMix.any((mixSong) => mixSong.id == song.id))
        .toList();
    dailyMix.addAll(likedSongs);

    // 4. Add songs from favorite genres (15%)
    final genreCount = (50 * 0.15).round();
    final favoriteGenres =
        _userPreferences['favoriteGenres'] as Map<String, dynamic>? ?? {};
    final genreSongs = <SongModel>[];

    for (final genre in favoriteGenres.keys.take(3)) {
      final genreSongList = allSongs
          .where((song) =>
              song.genre == genre &&
              !dailyMix.any((mixSong) => mixSong.id == song.id))
          .toList();
      genreSongList.shuffle();
      genreSongs.addAll(genreSongList.take(genreCount ~/ 3));
    }
    dailyMix.addAll(genreSongs);

    // 5. Fill remaining with random songs for discovery (10%)
    final remaining = 50 - dailyMix.length;
    if (remaining > 0) {
      final availableSongs = allSongs
          .where((song) => !dailyMix.any((mixSong) => mixSong.id == song.id))
          .toList();
      availableSongs.shuffle();
      dailyMix.addAll(availableSongs.take(remaining));
    }

    // Cache the daily mix
    _dailyMixData['songs'] = dailyMix.map((song) => song.toJson()).toList();
    _dailyMixData['lastGenerated'] = now.toIso8601String();
    _dailyMixData['songCount'] = dailyMix.length;

    _saveDailyMixData();

    return dailyMix;
  }

  // Generate weekly mix based on user preferences for discovery
  List<SongModel> generateWeeklyMix(List<SongModel> allSongs) {
    final now = DateTime.now();
    final currentWeek = now.year * 100 + _getWeekOfYear(now);

    // Check if we need to regenerate weekly mix
    final lastGenerated = _weeklyMixData['lastGenerated'];
    if (lastGenerated != null) {
      final lastDate = DateTime.tryParse(lastGenerated);
      if (lastDate != null) {
        final lastWeek = lastDate.year * 100 + _getWeekOfYear(lastDate);
        if (lastWeek == currentWeek) {
          // Return cached weekly mix if generated this week
          final cachedSongs = _weeklyMixData['songs'] as List<dynamic>?;
          if (cachedSongs != null) {
            return _convertToSongList(cachedSongs, allSongs);
          }
        }
      }
    }

    // Generate new weekly mix for discovery
    final List<SongModel> weeklyMix = [];
    final favoriteGenres =
        _userPreferences['favoriteGenres'] as Map<String, dynamic>? ?? {};
    final favoriteArtists =
        _userPreferences['favoriteArtists'] as Map<String, dynamic>? ?? {};

    // 1. Songs from favorite genres but different artists (40%)
    final genreCount = (30 * 0.4).round();
    for (final genre in favoriteGenres.keys.take(5)) {
      final genreSongs = allSongs
          .where((song) =>
              song.genre == genre && !favoriteArtists.containsKey(song.artist))
          .toList();
      genreSongs.shuffle();
      weeklyMix.addAll(genreSongs.take(genreCount ~/ 5));
    }

    // 2. Songs from favorite artists but different genres (30%)
    final artistCount = (30 * 0.3).round();
    for (final artist in favoriteArtists.keys.take(5)) {
      final artistSongs = allSongs
          .where((song) =>
              song.artist == artist && !favoriteGenres.containsKey(song.genre))
          .toList();
      artistSongs.shuffle();
      weeklyMix.addAll(artistSongs.take(artistCount ~/ 5));
    }

    // 3. Completely new genres and artists for discovery (30%)
    final discoveryCount = 30 - weeklyMix.length;
    if (discoveryCount > 0) {
      final discoverySongs = allSongs
          .where((song) =>
              !favoriteGenres.containsKey(song.genre) &&
              !favoriteArtists.containsKey(song.artist) &&
              !weeklyMix.any((mixSong) => mixSong.id == song.id))
          .toList();
      discoverySongs.shuffle();
      weeklyMix.addAll(discoverySongs.take(discoveryCount));
    }

    // Cache the weekly mix
    _weeklyMixData['songs'] = weeklyMix.map((song) => song.toJson()).toList();
    _weeklyMixData['lastGenerated'] = now.toIso8601String();
    _weeklyMixData['songCount'] = weeklyMix.length;

    _saveWeeklyMixData();

    return weeklyMix;
  }

  // Helper method to convert JSON list back to SongModel list
  List<SongModel> _convertToSongList(
      List<dynamic> jsonList, List<SongModel> allSongs) {
    final List<SongModel> songs = [];
    for (final songJson in jsonList) {
      try {
        final songId = songJson['id'] as int?;
        if (songId != null) {
          final song = allSongs.firstWhere((s) => s.id == songId,
              orElse: () => SongModel.fromJson(songJson));
          songs.add(song);
        }
      } catch (e) {
        debugPrint('Error converting song: $e');
      }
    }
    return songs;
  }

  // Save user preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPreferencesKey, json.encode(_userPreferences));
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }

  // Save daily mix data
  Future<void> _saveDailyMixData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dailyMixKey, json.encode(_dailyMixData));
    } catch (e) {
      debugPrint('Error saving daily mix data: $e');
    }
  }

  // Save weekly mix data
  Future<void> _saveWeeklyMixData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weeklyMixKey, json.encode(_weeklyMixData));
    } catch (e) {
      debugPrint('Error saving weekly mix data: $e');
    }
  }

  // Load user preferences and mix data
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user preferences
      final prefsJson = prefs.getString(_userPreferencesKey);
      if (prefsJson != null) {
        final Map<String, dynamic> prefsMap = json.decode(prefsJson);
        _userPreferences.value = prefsMap;
      }

      // Load daily mix data
      final dailyMixJson = prefs.getString(_dailyMixKey);
      if (dailyMixJson != null) {
        final Map<String, dynamic> dailyMixMap = json.decode(dailyMixJson);
        _dailyMixData.value = dailyMixMap;
      }

      // Load weekly mix data
      final weeklyMixJson = prefs.getString(_weeklyMixKey);
      if (weeklyMixJson != null) {
        final Map<String, dynamic> weeklyMixMap = json.decode(weeklyMixJson);
        _weeklyMixData.value = weeklyMixMap;
      }
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  // Helper method to get week of year
  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday =
        startOfYear.add(Duration(days: (8 - startOfYear.weekday) % 7));

    if (date.isBefore(firstMonday)) {
      return 1;
    }

    final daysSinceFirstMonday = date.difference(firstMonday).inDays;
    return (daysSinceFirstMonday / 7).floor() + 1;
  }

  // Get formatted timestamp for when mix was last generated
  String getDailyMixLastGenerated() {
    final lastGenerated = _dailyMixData['lastGenerated'] as String?;
    if (lastGenerated == null) return 'Never';

    final date = DateTime.tryParse(lastGenerated);
    if (date == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String getWeeklyMixLastGenerated() {
    final lastGenerated = _weeklyMixData['lastGenerated'] as String?;
    if (lastGenerated == null) return 'Never';

    final date = DateTime.tryParse(lastGenerated);
    if (date == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'Today';
    }
  }

  // =====================
  // Achievement tracking
  // =====================
  void _trackPlaylistCreated() {
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
          'playlists_created': _userPlaylists.length,
        };
        achievementService.checkAchievements(userId, stats);
      }
    } catch (e) {
      debugPrint('Error tracking playlist created: $e');
    }
  }

  void _trackSongLiked() {
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
          'songs_liked': _likedSongs.length,
        };
        achievementService.checkAchievements(userId, stats);
      }
    } catch (e) {
      debugPrint('Error tracking song liked: $e');
    }
  }
}
