import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/achievement_model.dart';

class AchievementDatabase {
  static final AchievementDatabase _instance = AchievementDatabase._internal();
  factory AchievementDatabase() => _instance;
  AchievementDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'achievements.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // User achievements table
    await db.execute('''
      CREATE TABLE user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        unlocked_at INTEGER NOT NULL,
        is_new INTEGER NOT NULL DEFAULT 1,
        progress TEXT,
        last_updated INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    // Achievement progress table
    await db.execute('''
      CREATE TABLE achievement_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        current_value INTEGER NOT NULL DEFAULT 0,
        target_value INTEGER NOT NULL DEFAULT 0,
        progress_percentage REAL NOT NULL DEFAULT 0.0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        last_updated INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_achievement_progress_user_id ON achievement_progress(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_achievement_progress_achievement_id ON achievement_progress(achievement_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate progress column from REAL to TEXT
      await db.execute('''
        ALTER TABLE user_achievements ADD COLUMN progress_new TEXT
      ''');

      // Copy data from old progress column to new one
      await db.execute('''
        UPDATE user_achievements SET progress_new = CAST(progress AS TEXT) WHERE progress IS NOT NULL
      ''');

      // Drop old progress column
      await db.execute('''
        ALTER TABLE user_achievements DROP COLUMN progress
      ''');

      // Rename new column to progress
      await db.execute('''
        ALTER TABLE user_achievements RENAME COLUMN progress_new TO progress
      ''');
    }
  }

  /// Save user achievement
  Future<void> saveUserAchievement(UserAchievementModel achievement) async {
    final db = await database;
    await db.insert(
      'user_achievements',
      {
        'id': achievement.id,
        'user_id': achievement.userId,
        'achievement_id': achievement.achievementId,
        'unlocked_at': achievement.unlockedAt.millisecondsSinceEpoch,
        'is_new': achievement.isNew ? 1 : 0,
        'progress': achievement.progress != null
            ? jsonEncode(achievement.progress!)
            : null,
        'last_updated': achievement.lastUpdated?.millisecondsSinceEpoch,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user achievements
  Future<List<UserAchievementModel>> getUserAchievements(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'unlocked_at DESC',
    );

    return maps.map((map) => UserAchievementModel.fromLocalMap(map)).toList();
  }

  /// Get user achievement by ID
  Future<UserAchievementModel?> getUserAchievement(
      String userId, String achievementId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserAchievementModel.fromLocalMap(maps.first);
  }

  /// Update user achievement
  Future<void> updateUserAchievement(UserAchievementModel achievement) async {
    final db = await database;
    await db.update(
      'user_achievements',
      {
        'is_new': achievement.isNew ? 1 : 0,
        'progress': achievement.progress,
        'last_updated': achievement.lastUpdated?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  /// Save achievement progress
  Future<void> saveAchievementProgress(
      AchievementProgress progress, String userId) async {
    final db = await database;
    await db.insert(
      'achievement_progress',
      {
        'id': '${userId}_${progress.achievementId}',
        'user_id': userId,
        'achievement_id': progress.achievementId,
        'current_value': progress.currentValue,
        'target_value': progress.targetValue,
        'progress_percentage': progress.progressPercentage,
        'is_completed': progress.isCompleted ? 1 : 0,
        'last_updated': progress.lastUpdated?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get achievement progress for user
  Future<Map<String, AchievementProgress>> getUserProgress(
      String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievement_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final progressMap = <String, AchievementProgress>{};
    for (final map in maps) {
      final progress = AchievementProgress.fromLocalMap(map);
      progressMap[progress.achievementId] = progress;
    }

    return progressMap;
  }

  /// Get achievement progress by ID
  Future<AchievementProgress?> getAchievementProgress(
      String userId, String achievementId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievement_progress',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AchievementProgress.fromLocalMap(maps.first);
  }

  /// Update achievement progress
  Future<void> updateAchievementProgress(
      AchievementProgress progress, String userId) async {
    final db = await database;
    await db.update(
      'achievement_progress',
      {
        'current_value': progress.currentValue,
        'target_value': progress.targetValue,
        'progress_percentage': progress.progressPercentage,
        'is_completed': progress.isCompleted ? 1 : 0,
        'last_updated': progress.lastUpdated?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      },
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, progress.achievementId],
    );
  }

  /// Get all user achievements (for migration)
  Future<List<UserAchievementModel>> getAllUserAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_achievements',
      orderBy: 'unlocked_at DESC',
    );

    return maps.map((map) => UserAchievementModel.fromLocalMap(map)).toList();
  }

  /// Get all achievement progress (for migration)
  Future<List<Map<String, dynamic>>> getAllAchievementProgress() async {
    final db = await database;
    return await db.query('achievement_progress');
  }

  /// Clear all data for a user
  Future<void> clearUserData(String userId) async {
    final db = await database;
    await db
        .delete('user_achievements', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('achievement_progress',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('user_achievements');
    await db.delete('achievement_progress');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
