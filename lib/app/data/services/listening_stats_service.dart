import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/listening_stats_model.dart';
import '../models/song_model.dart';
import '../database/listening_stats_database.dart';
import 'auth_service.dart';

class ListeningStatsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  final ListeningStatsDatabase _database = ListeningStatsDatabase();

  // Collections
  static const String listeningStatsCollection = 'listening_stats';
  static const String playHistoryCollection = 'play_history';

  // Observable variables
  final Rx<ListeningStatsModel?> _currentStats = Rx<ListeningStatsModel?>(null);
  Rx<ListeningStatsModel?> get currentStatsRx => _currentStats;
  final RxList<PlayHistoryEntry> _playHistory = <PlayHistoryEntry>[].obs;
  final RxBool _isLoading = false.obs;

  // Getters
  ListeningStatsModel? get currentStats => _currentStats.value;
  List<PlayHistoryEntry> get playHistory => _playHistory;
  bool get isLoading => _isLoading.value;
  RxBool get isLoadingRx => _isLoading;

  @override
  void onInit() {
    super.onInit();
    // Run migration if needed
    // MigrationHelper.migrateIfNeeded();
    // Load stats immediately on service initialization
    _loadCurrentStats();
    checkDatabase('guest');
  }

  void checkDatabase(String? userId) async {
    debugPrint('=== Database Check ===');

    // Check for different userIds
    final userIds = ['', 'guest', 'guest_2025_10', userId ?? 'current_user'];

    for (final id in userIds) {
      final stats = await _database.getAllListeningStats(id);
      final playHistory = await _database.getPlayHistory(id, limit: 10);

      debugPrint('User ID: "$id"');
      debugPrint('- Stats count: ${stats.length}');
      debugPrint('- Play history count: ${playHistory.length}');

      if (stats.isNotEmpty) {
        for (final stat in stats) {
          debugPrint(
              '  Stats: ${stat.id} - userId: "${stat.userId}" - hours: ${stat.totalHoursThisMonth}');
        }
      }

      if (playHistory.isNotEmpty) {
        for (final entry in playHistory.take(3)) {
          debugPrint('  Play: ${entry.songTitle} - userId: "${entry.userId}"');
        }
      }
    }

    debugPrint('=== End Database Check ===');
  }

  /// Load current month's statistics
  Future<void> _loadCurrentStats() async {
    try {
      _isLoading.value = true;

      // final user = _authService.firebaseUser.value;
      // if (user != null) {
      //   // Load from Firestore
      //   await _loadStatsFromFirestore(user.uid);
      // } else {
      // Load from local storage for guest users
      await _loadStatsFromLocal();
      // }
    } catch (e) {
      debugPrint('Error loading current stats: $e');
      // Create empty stats if loading fails
      _currentStats.value = ListeningStatsModel.empty('guest');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load stats from Firestore
  Future<void> _loadStatsFromFirestore(String userId) async {
    try {
      final now = DateTime.now();
      final docId = '${userId}_${now.year}_${now.month}';

      final doc = await _firestore
          .collection(listeningStatsCollection)
          .doc(docId)
          .get();

      if (doc.exists) {
        _currentStats.value = ListeningStatsModel.fromMap(doc.data()!);
      } else {
        // Create new stats for this month
        _currentStats.value = ListeningStatsModel.empty(userId);
        await _saveStatsToFirestore(_currentStats.value!);
      }
    } catch (e) {
      debugPrint('Error loading stats from Firestore: $e');
      // Fallback to local storage
      await _loadStatsFromLocal();
    }
  }

  /// Load stats from local storage (SQLite)
  Future<void> _loadStatsFromLocal() async {
    try {
      final now = DateTime.now();
      final monthYear = '${now.year}_${now.month}';
      final userId = _authService.firebaseUser.value?.uid ?? 'guest';

      // Try to load stats for the current user
      var stats = await _database.getListeningStats(userId, monthYear);

      // If no stats found for current user, try to load with empty userId (legacy data)
      if (stats == null) {
        stats = await _database.getListeningStats('', monthYear);
        if (stats != null) {
          debugPrint(
              'Found legacy data with empty userId, migrating to: $userId');
          // Migrate the data to current user ID
          final migratedStats = stats.copyWith(userId: userId);
          await _database.saveListeningStats(migratedStats);
          stats = migratedStats;
        }
      }

      // If still no stats found, try to load guest data
      if (stats == null) {
        stats = await _database.getListeningStats('guest', monthYear);
        if (stats != null) {
          debugPrint('Found guest data, migrating to: $userId');
          // Migrate the data to current user ID
          final migratedStats = stats.copyWith(userId: userId);
          await _database.saveListeningStats(migratedStats);
          stats = migratedStats;
        }
      }

      // Load play history first - try multiple userIds
      var playHistory = await _database.getPlayHistory(userId, limit: 1000);
      if (playHistory.isEmpty) {
        playHistory = await _database.getPlayHistory('', limit: 1000);
        if (playHistory.isNotEmpty) {
          debugPrint(
              'Found legacy play history with empty userId, migrating to: $userId');
          // Migrate play history entries
          for (final entry in playHistory) {
            final migratedEntry = PlayHistoryEntry(
              id: entry.id.replaceFirst('_', '_${userId}_'),
              userId: userId,
              songId: entry.songId,
              songTitle: entry.songTitle,
              artist: entry.artist,
              album: entry.album,
              genre: entry.genre,
              duration: entry.duration,
              playDuration: entry.playDuration,
              playedAt: entry.playedAt,
              createdAt: entry.createdAt,
            );
            await _database.savePlayHistory(migratedEntry);
          }
          // Reload with correct userId
          playHistory = await _database.getPlayHistory(userId, limit: 1000);
        }
      }
      if (playHistory.isEmpty) {
        playHistory = await _database.getPlayHistory('guest', limit: 1000);
        if (playHistory.isNotEmpty) {
          debugPrint('Found guest play history, migrating to: $userId');
          // Migrate play history entries
          for (final entry in playHistory) {
            final migratedEntry = PlayHistoryEntry(
              id: entry.id.replaceFirst('guest', userId),
              userId: userId,
              songId: entry.songId,
              songTitle: entry.songTitle,
              artist: entry.artist,
              album: entry.album,
              genre: entry.genre,
              duration: entry.duration,
              playDuration: entry.playDuration,
              playedAt: entry.playedAt,
              createdAt: entry.createdAt,
            );
            await _database.savePlayHistory(migratedEntry);
          }
          // Reload with correct userId
          playHistory = await _database.getPlayHistory(userId, limit: 1000);
        }
      }

      _playHistory.value = playHistory;

      // Now check stats and recalculate if needed
      if (stats != null) {
        _currentStats.value = stats;
        debugPrint('Loaded listening stats from SQLite for user: $userId');
        print(stats.toMap());

        // If stats are empty but we have play history, recalculate stats
        if (stats.totalHoursThisMonth == 0 && playHistory.isNotEmpty) {
          debugPrint(
              'Stats are empty but play history exists, recalculating...');
          await _recalculateStatsFromPlayHistory(userId);
        }
      } else {
        _currentStats.value = ListeningStatsModel.empty(userId);
        debugPrint(
            'No local listening stats found, created empty stats for user: $userId');

        // If we have play history but no stats, calculate stats from play history
        if (playHistory.isNotEmpty) {
          debugPrint(
              'No stats but play history exists, calculating stats from play history...');
          await _recalculateStatsFromPlayHistory(userId);
        }
      }
    } catch (e) {
      debugPrint('Error loading stats from local: $e');
      final userId = _authService.firebaseUser.value?.uid ?? 'guest';
      _currentStats.value = ListeningStatsModel.empty(userId);
    }
  }

  /// Save stats to Firestore
  Future<void> _saveStatsToFirestore(ListeningStatsModel stats) async {
    try {
      await _firestore
          .collection(listeningStatsCollection)
          .doc(stats.id)
          .set(stats.toMap());
    } catch (e) {
      debugPrint('Error saving stats to Firestore: $e');
    }
  }

  /// Save stats to local storage (SQLite)
  Future<void> _saveStatsToLocal(ListeningStatsModel stats) async {
    try {
      await _database.saveListeningStats(stats);
      debugPrint('Saved listening stats to SQLite');
    } catch (e) {
      debugPrint('Error saving stats to local: $e');
    }
  }

  /// Track a song play
  Future<void> trackSongPlay(SongModel song, Duration duration) async {
    try {
      final now = DateTime.now();
      final userId = _authService.firebaseUser.value?.uid ?? 'guest';

      // Create play history entry
      final playEntry = PlayHistoryEntry.fromSong(
        userId: userId,
        songId: song.id.toString(),
        songTitle: song.title,
        artist: song.artist,
        album: song.album,
        genre: song.genre,
        duration: song.duration,
        playDuration: duration.inSeconds,
      );

      // Save to database
      await _database.savePlayHistory(playEntry);

      // Add to in-memory history
      _playHistory.add(playEntry);

      // Update current stats
      await _updateCurrentStats(song, duration, now);

      // Save to storage immediately
      await _saveCurrentStats();

      debugPrint(
          'Tracked song play: ${song.title} - Actual Play Time: ${duration.inMinutes}min ${duration.inSeconds % 60}s');
    } catch (e) {
      debugPrint('Error tracking song play: $e');
    }
  }

  /// Update current month's statistics
  Future<void> _updateCurrentStats(
      SongModel song, Duration duration, DateTime playedAt) async {
    if (_currentStats.value == null) return;

    final stats = _currentStats.value!;
    final now = DateTime.now();
    final userId = _authService.firebaseUser.value?.uid ?? 'guest';

    // Check if we need to create new month's stats
    if (stats.monthYear.month != now.month ||
        stats.monthYear.year != now.year) {
      // Save current month's stats and create new one
      await _saveCurrentStats();
      _currentStats.value = ListeningStatsModel.empty(userId);
    }

    // Get fresh data from database for accurate calculations
    final songPlayCounts = await _database.getSongPlayCounts(userId);
    final artistStats = await _database.getArtistPlayCounts(userId);
    final genreStats = await _database.getGenrePlayCounts(userId);
    final timePatterns = await _database.getTimePatterns(userId);

    // Convert time patterns to Map<String, int>
    final timePatternsMap = <String, int>{};
    for (final pattern in timePatterns) {
      timePatternsMap[pattern['hour'] as String] = pattern['play_count'] as int;
    }

    // Calculate total hours from play history
    final playHistory = await _database.getPlayHistory(userId);
    final totalMinutes = playHistory.fold<int>(
      0,
      (sums, entry) => sums + entry.playDuration,
    );
    final totalHours = (totalMinutes / 60).round();

    // Find top artist
    String topArtist = 'No data yet';
    if (artistStats.isNotEmpty) {
      topArtist =
          artistStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Find most played song
    String mostPlayedSong = 'No data yet';
    int mostPlayedCount = 0;
    if (songPlayCounts.isNotEmpty) {
      final topSong =
          songPlayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      mostPlayedSong = topSong.key;
      mostPlayedCount = topSong.value;
    }

    debugPrint('Listening Stats Calculation:');
    debugPrint('- Total play history entries: ${playHistory.length}');
    debugPrint('- Total minutes played: $totalMinutes');
    debugPrint('- Total hours played: $totalHours');
    debugPrint(
        '- Top artist: $topArtist (${artistStats[topArtist] ?? 0} plays)');
    debugPrint('- Most played song: $mostPlayedSong ($mostPlayedCount plays)');
    debugPrint('- Unique artists: ${artistStats.length}');
    debugPrint('- Unique genres: ${genreStats.length}');
    debugPrint('- Time patterns: ${timePatternsMap.length} hours tracked');

    _currentStats.value = stats.copyWith(
      totalHoursThisMonth: totalHours,
      songPlayCounts: songPlayCounts,
      artistStats: artistStats,
      genreStats: genreStats,
      timePatterns: timePatternsMap,
      topArtist: topArtist,
      mostPlayedSong: mostPlayedSong,
      mostPlayedSongCount: mostPlayedCount,
      lastUpdated: now,
    );
  }

  /// Save current stats to appropriate storage
  Future<void> _saveCurrentStats() async {
    if (_currentStats.value == null) return;

    // Always save to local storage first
    await _saveStatsToLocal(_currentStats.value!);

    // Only save to Firestore if user is authenticated and has internet
    // final user = _authService.firebaseUser.value;
    // if (user != null) {
    //   try {
    //     // Check internet connection before saving to Firestore
    //     final hasInternet = await _hasInternetConnection();
    //     if (hasInternet) {
    //       await _saveStatsToFirestore(_currentStats.value!);
    //     } else {
    //       debugPrint('No internet connection - stats saved locally only');
    //     }
    //   } catch (e) {
    //     debugPrint('Error saving to Firestore: $e - stats saved locally');
    //   }
    // }
  }

  /// Get listening time pattern description
  String getTimePatternDescription() {
    if (_currentStats.value == null) {
      return 'No listening pattern data'.trimLeft();
    }
    return _currentStats.value!.timePatternDescription;
  }

  /// Get dynamic listening style based on user behavior
  String getListeningStyle() {
    if (_currentStats.value == null) return 'Casual';

    final stats = _currentStats.value!;
    final totalHours = stats.totalHoursThisMonth;
    final mostPlayedCount = stats.mostPlayedSongCount;
    final uniqueArtists = stats.artistStats.length;

    debugPrint('Listening Style Calculation:');
    debugPrint('- Total hours: $totalHours');
    debugPrint('- Most played song count: $mostPlayedCount');
    debugPrint('- Unique artists: $uniqueArtists');

    // Calculate listening intensity
    if (totalHours >= 50 && mostPlayedCount >= 20) {
      debugPrint(
          '- Style: Power Listener (50+ hours, 20+ plays on favorite song)');
      return 'Power Listener'.tr;
    } else if (totalHours >= 20 && uniqueArtists >= 10) {
      debugPrint('- Style: Explorer (20+ hours, 10+ different artists)');
      return 'Explorer'.tr;
    } else if (totalHours >= 10 && mostPlayedCount >= 10) {
      debugPrint('- Style: Enthusiast (10+ hours, 10+ plays on favorite song)');
      return 'Enthusiast'.tr;
    } else if (totalHours >= 5) {
      debugPrint('- Style: Regular (5+ hours)');
      return 'Regular'.tr;
    } else if (totalHours >= 1) {
      debugPrint('- Style: Casual (1+ hours)');
      return 'Casual'.tr;
    } else {
      debugPrint('- Style: Newcomer (< 1 hour)');
      return 'Newcomer'.tr;
    }
  }

  /// Get listening style description
  String getListeningStyleDescription() {
    final style = getListeningStyle();
    switch (style) {
      case 'Power Listener':
        return 'You listen to music extensively and have favorite tracks'.tr;
      case 'Explorer':
        return 'You enjoy discovering new artists and genres'.tr;
      case 'Enthusiast':
        return 'You have a strong passion for music'.tr;
      case 'Regular':
        return 'You listen to music regularly'.tr;
      case 'Casual':
        return 'You enjoy music occasionally'.tr;
      case 'Newcomer':
        return 'You\'re just getting started with music'.tr;
      default:
        return 'Your listening style is developing'.tr;
    }
  }

  /// Get formatted total hours
  String getFormattedTotalHours() {
    if (_currentStats.value == null) return '0 hours';
    return _currentStats.value!.formattedTotalHours;
  }

  /// Get top artist
  String getTopArtist() {
    if (_currentStats.value == null) return 'No data yet';
    return _currentStats.value!.topArtist;
  }

  /// Get most played song with count
  String getMostPlayedSong() {
    if (_currentStats.value == null) return 'No data yet';
    final stats = _currentStats.value!;
    if (stats.mostPlayedSongCount == 0) return 'No data yet';
    return '${stats.mostPlayedSong} (${stats.mostPlayedSongCount} plays)';
  }

  /// Get most played song title only
  String getMostPlayedSongTitle() {
    if (_currentStats.value == null) return 'No data yet';
    return _currentStats.value!.mostPlayedSong;
  }

  /// Get most played song count
  int getMostPlayedSongCount() {
    if (_currentStats.value == null) return 0;
    return _currentStats.value!.mostPlayedSongCount;
  }

  /// Sync local stats to Firestore when user logs in
  Future<void> syncLocalToFirestore(String userId) async {
    try {
      final user = _authService.firebaseUser.value;
      if (user == null || user.uid != userId) {
        debugPrint(
            'Cannot sync listening stats - user not authenticated or ID mismatch');
        return;
      }

      // Check internet connection
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        debugPrint('No internet connection - skipping sync');
        return;
      }

      debugPrint('Starting listening stats sync for user: $userId');

      // Get all local stats for this user
      final allLocalStats = await _database.getAllListeningStats(userId);

      for (final stats in allLocalStats) {
        // Check if stats already exist in Firestore for this month
        final monthYear = '${stats.monthYear.year}_${stats.monthYear.month}';
        final docId = '${userId}_$monthYear';

        final existingDoc = await _firestore
            .collection(listeningStatsCollection)
            .doc(docId)
            .get();

        if (existingDoc.exists) {
          debugPrint('Stats already exist for $monthYear, skipping');
          continue;
        }

        // Update user ID and save to Firestore
        final updatedStats = stats.copyWith(userId: userId);
        await _saveStatsToFirestore(updatedStats);
        debugPrint('Synced stats for $monthYear to Firestore');
      }

      // Also sync play history
      final playHistory = await _database.getPlayHistory(userId);
      for (final entry in playHistory) {
        // Update entry with correct userId
        final updatedEntry = PlayHistoryEntry(
          id: entry.id,
          userId: userId,
          songId: entry.songId,
          songTitle: entry.songTitle,
          artist: entry.artist,
          album: entry.album,
          genre: entry.genre,
          duration: entry.duration,
          playDuration: entry.playDuration,
          playedAt: entry.playedAt,
          createdAt: entry.createdAt,
        );

        // Save to Firestore (you might want to batch this for better performance)
        await _firestore
            .collection(playHistoryCollection)
            .doc(updatedEntry.id)
            .set(updatedEntry.toMap());
      }

      debugPrint('Listening stats sync completed for user: $userId');
    } catch (e) {
      debugPrint('Error syncing listening stats: $e');
    }
  }

  /// Migrate guest data to user data when user logs in
  Future<void> migrateGuestDataToUser(String userId) async {
    try {
      debugPrint('Migrating guest data to user: $userId');

      // Get all guest data
      final guestStats = await _database.getAllListeningStats('guest');
      final guestPlayHistory = await _database.getPlayHistory('guest');

      if (guestStats.isEmpty && guestPlayHistory.isEmpty) {
        debugPrint('No guest data to migrate');
        return;
      }

      // Migrate stats
      for (final stats in guestStats) {
        final updatedStats = stats.copyWith(userId: userId);
        await _database.saveListeningStats(updatedStats);
      }

      // Migrate play history
      for (final entry in guestPlayHistory) {
        final updatedEntry = PlayHistoryEntry(
          id: entry.id.replaceFirst('guest', userId),
          userId: userId,
          songId: entry.songId,
          songTitle: entry.songTitle,
          artist: entry.artist,
          album: entry.album,
          genre: entry.genre,
          duration: entry.duration,
          playDuration: entry.playDuration,
          playedAt: entry.playedAt,
          createdAt: entry.createdAt,
        );
        await _database.savePlayHistory(updatedEntry);
      }

      // Clear guest data
      await _database.clearAllData('guest');

      debugPrint('Guest data migrated successfully to user: $userId');

      // Reload current stats with new user ID
      await _loadCurrentStats();
    } catch (e) {
      debugPrint('Error migrating guest data: $e');
    }
  }

  /// Refresh stats (useful after sync)
  Future<void> refreshStats() async {
    await _loadCurrentStats();
  }

  /// Recalculate stats from play history
  Future<void> _recalculateStatsFromPlayHistory(String userId) async {
    try {
      debugPrint('Recalculating stats from play history for user: $userId');

      // Get fresh data from database
      final songPlayCounts = await _database.getSongPlayCounts(userId);
      final artistStats = await _database.getArtistPlayCounts(userId);
      final genreStats = await _database.getGenrePlayCounts(userId);
      final timePatterns = await _database.getTimePatterns(userId);
      final playHistory = await _database.getPlayHistory(userId);

      // Convert time patterns to Map<String, int>
      final timePatternsMap = <String, int>{};
      for (final pattern in timePatterns) {
        timePatternsMap[pattern['hour'] as String] =
            pattern['play_count'] as int;
      }

      // Calculate total hours from play history
      final totalMinutes = playHistory.fold<int>(
        0,
        (sum, entry) => sum + entry.playDuration,
      );
      final totalHours = (totalMinutes / 60).round();

      // Find top artist
      String topArtist = 'No data yet';
      if (artistStats.isNotEmpty) {
        topArtist =
            artistStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // Find most played song
      String mostPlayedSong = 'No data yet';
      int mostPlayedCount = 0;
      if (songPlayCounts.isNotEmpty) {
        final topSong =
            songPlayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        mostPlayedSong = topSong.key;
        mostPlayedCount = topSong.value;
      }

      // Create new stats with calculated values
      final now = DateTime.now();
      final newStats = ListeningStatsModel(
        id: '${userId}_${now.year}_${now.month}',
        userId: userId,
        totalHoursThisMonth: totalHours,
        topArtist: topArtist,
        mostPlayedSong: mostPlayedSong,
        mostPlayedSongCount: mostPlayedCount,
        timePatterns: timePatternsMap,
        genreStats: genreStats,
        artistStats: artistStats,
        songPlayCounts: songPlayCounts,
        lastUpdated: now,
        monthYear: DateTime(now.year, now.month),
      );

      _currentStats.value = newStats;
      await _saveStatsToLocal(newStats);

      debugPrint('Stats recalculated successfully:');
      debugPrint('- Total hours: $totalHours');
      debugPrint('- Top artist: $topArtist');
      debugPrint(
          '- Most played song: $mostPlayedSong ($mostPlayedCount plays)');
    } catch (e) {
      debugPrint('Error recalculating stats: $e');
    }
  }

  /// Check if device has internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      // Simple connectivity check - you can replace with connectivity_plus if needed
      final result = await Future.any([
        Future.delayed(const Duration(seconds: 3), () => false),
        Future(() async {
          // Try to make a simple request to check connectivity
          return true; // Assume connected for now
        }),
      ]);
      return result;
    } catch (e) {
      debugPrint('Internet check failed: $e');
      return false;
    }
  }

  /// Clear all stats (for testing or reset)
  Future<void> clearAllStats() async {
    try {
      final userId = _authService.firebaseUser.value?.uid ?? 'guest';
      _currentStats.value = null;
      _playHistory.clear();

      await _database.clearAllData(userId);
      debugPrint('All listening stats cleared from SQLite');
    } catch (e) {
      debugPrint('Error clearing stats: $e');
    }
  }
}
