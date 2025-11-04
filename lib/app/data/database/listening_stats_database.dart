import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/listening_stats_model.dart';

class ListeningStatsDatabase {
  static final ListeningStatsDatabase _instance =
      ListeningStatsDatabase._internal();
  factory ListeningStatsDatabase() => _instance;
  ListeningStatsDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'listening_stats.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create listening_stats table
    await db.execute('''
      CREATE TABLE listening_stats(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        month_year TEXT NOT NULL,
        total_hours_this_month REAL NOT NULL,
        top_artist TEXT,
        most_played_song TEXT,
        most_played_song_count INTEGER,
        time_patterns TEXT,
        genre_stats TEXT,
        artist_stats TEXT,
        last_updated INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create play_history table
    await db.execute('''
      CREATE TABLE play_history(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        song_title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        genre TEXT,
        duration INTEGER,
        play_duration INTEGER,
        played_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_listening_stats_user_month ON listening_stats(user_id, month_year)');
    await db.execute(
        'CREATE INDEX idx_play_history_user_date ON play_history(user_id, played_at)');
    await db
        .execute('CREATE INDEX idx_play_history_song ON play_history(song_id)');
  }

  // Listening Stats CRUD operations
  Future<void> saveListeningStats(ListeningStatsModel stats) async {
    final db = await database;
    await db.insert(
      'listening_stats',
      stats.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ListeningStatsModel?> getListeningStats(
      String userId, String monthYear) async {
    final db = await database;
    final result = await db.query(
      'listening_stats',
      where: 'user_id = ? AND month_year = ?',
      whereArgs: [userId, monthYear],
    );

    if (result.isNotEmpty) {
      return ListeningStatsModel.fromMap(result.first);
    }
    return null;
  }

  Future<List<ListeningStatsModel>> getAllListeningStats(String userId) async {
    final db = await database;
    final result = await db.query(
      'listening_stats',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'month_year DESC',
    );

    return result.map((map) => ListeningStatsModel.fromMap(map)).toList();
  }

  Future<void> deleteListeningStats(String userId, String monthYear) async {
    final db = await database;
    await db.delete(
      'listening_stats',
      where: 'user_id = ? AND month_year = ?',
      whereArgs: [userId, monthYear],
    );
  }

  // Play History CRUD operations
  Future<void> savePlayHistory(PlayHistoryEntry entry) async {
    final db = await database;
    await db.insert(
      'play_history',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PlayHistoryEntry>> getPlayHistory(String userId,
      {int? limit}) async {
    final db = await database;
    final result = await db.query(
      'play_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'played_at DESC',
      limit: limit,
    );

    return result.map((map) => PlayHistoryEntry.fromMap(map)).toList();
  }

  Future<List<PlayHistoryEntry>> getPlayHistoryBySong(
      String userId, String songId) async {
    final db = await database;
    final result = await db.query(
      'play_history',
      where: 'user_id = ? AND song_id = ?',
      whereArgs: [userId, songId],
      orderBy: 'played_at DESC',
    );

    return result.map((map) => PlayHistoryEntry.fromMap(map)).toList();
  }

  Future<void> deletePlayHistory(String userId, {String? songId}) async {
    final db = await database;
    if (songId != null) {
      await db.delete(
        'play_history',
        where: 'user_id = ? AND song_id = ?',
        whereArgs: [userId, songId],
      );
    } else {
      await db.delete(
        'play_history',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // Utility methods
  Future<int> getPlayHistoryCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM play_history WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getUniqueArtists(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT artist FROM play_history WHERE user_id = ? AND artist IS NOT NULL',
      [userId],
    );
    return result.map((map) => map['artist'] as String).toList();
  }

  Future<List<String>> getUniqueGenres(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT genre FROM play_history WHERE user_id = ? AND genre IS NOT NULL',
      [userId],
    );
    return result.map((map) => map['genre'] as String).toList();
  }

  Future<Map<String, int>> getSongPlayCounts(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT song_title, artist, COUNT(*) as play_count
      FROM play_history 
      WHERE user_id = ?
      GROUP BY song_title, artist
      ORDER BY play_count DESC
    ''', [userId]);

    final Map<String, int> playCounts = {};
    for (final row in result) {
      final key = '${row['song_title']} - ${row['artist']}';
      playCounts[key] = row['play_count'] as int;
    }
    return playCounts;
  }

  Future<Map<String, int>> getArtistPlayCounts(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT artist, COUNT(*) as play_count
      FROM play_history 
      WHERE user_id = ? AND artist IS NOT NULL
      GROUP BY artist
      ORDER BY play_count DESC
    ''', [userId]);

    final Map<String, int> playCounts = {};
    for (final row in result) {
      playCounts[row['artist'] as String] = row['play_count'] as int;
    }
    return playCounts;
  }

  Future<Map<String, int>> getGenrePlayCounts(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT genre, COUNT(*) as play_count
      FROM play_history 
      WHERE user_id = ? AND genre IS NOT NULL
      GROUP BY genre
      ORDER BY play_count DESC
    ''', [userId]);

    final Map<String, int> playCounts = {};
    for (final row in result) {
      playCounts[row['genre'] as String] = row['play_count'] as int;
    }
    return playCounts;
  }

  Future<List<Map<String, dynamic>>> getTimePatterns(String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        strftime('%H', datetime(played_at/1000, 'unixepoch')) as hour,
        COUNT(*) as play_count
      FROM play_history 
      WHERE user_id = ?
      GROUP BY hour
      ORDER BY hour
    ''', [userId]);

    return result;
  }

  // Clear all data
  Future<void> clearAllData(String userId) async {
    final db = await database;
    await db
        .delete('listening_stats', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('play_history', where: 'user_id = ?', whereArgs: [userId]);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

// Play History Entry model
class PlayHistoryEntry {
  final String id;
  final String userId;
  final String songId;
  final String songTitle;
  final String? artist;
  final String? album;
  final String? genre;
  final int? duration;
  final int playDuration;
  final DateTime playedAt;
  final DateTime createdAt;

  PlayHistoryEntry({
    required this.id,
    required this.userId,
    required this.songId,
    required this.songTitle,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    required this.playDuration,
    required this.playedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'song_id': songId,
      'song_title': songTitle,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'play_duration': playDuration,
      'played_at': playedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PlayHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PlayHistoryEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      songId: map['song_id'] as String,
      songTitle: map['song_title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      genre: map['genre'] as String?,
      duration: map['duration'] as int?,
      playDuration: map['play_duration'] as int,
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['played_at'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  factory PlayHistoryEntry.fromSong({
    required String userId,
    required String songId,
    required String songTitle,
    String? artist,
    String? album,
    String? genre,
    int? duration,
    required int playDuration,
  }) {
    final now = DateTime.now();
    return PlayHistoryEntry(
      id: '${userId}_${songId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      songId: songId,
      songTitle: songTitle,
      artist: artist,
      album: album,
      genre: genre,
      duration: duration,
      playDuration: playDuration,
      playedAt: now,
      createdAt: now,
    );
  }
}
