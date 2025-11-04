import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../database/achievement_database.dart';

class AchievementService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AchievementDatabase _database = AchievementDatabase();

  // Collections
  static const String achievementsCollection = 'achievements';
  static const String userAchievementsCollection = 'user_achievements';
  static const String achievementProgressCollection = 'achievement_progress';

  // Observable for achievement unlocks
  final RxInt achievementUnlockTrigger = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Only initialize Firestore achievements if user is logged in
    final user = _auth.currentUser;
    if (user != null) {
      _initializeAchievements();
    }
  }

  /// Initialize default achievements if they don't exist
  Future<void> _initializeAchievements() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return; // Skip if not logged in

      final achievementsSnapshot =
          await _firestore.collection(achievementsCollection).limit(1).get();

      if (achievementsSnapshot.docs.isEmpty) {
        await _createDefaultAchievements();
      }
    } catch (e) {
      debugPrint('Error initializing achievements: $e');
    }
  }

  /// Create default achievements
  Future<void> _createDefaultAchievements() async {
    final defaultAchievements = [
      AchievementModel(
        id: 'first_song',
        title: 'First Steps',
        description: 'Play your first song',
        icon: '🎵',
        type: AchievementType.firstSong,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.medal,
        points: 10,
        category: 'Music',
        requirements: {'songs_played': 1},
      ),
      AchievementModel(
        id: 'music_lover',
        title: 'Music Lover',
        description: 'Play 100 songs',
        icon: '❤️',
        type: AchievementType.musicLover,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.star,
        points: 50,
        category: 'Music',
        requirements: {'songs_played': 100},
      ),
      AchievementModel(
        id: 'playlist_master',
        title: 'Playlist Master',
        description: 'Create 5 playlists',
        icon: '📝',
        type: AchievementType.playlistMaster,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.hexagon,
        points: 100,
        category: 'Organization',
        requirements: {'playlists_created': 5},
      ),
      AchievementModel(
        id: 'marathon_listener',
        title: 'Marathon Listener',
        description: 'Listen for 2 hours straight',
        icon: '🏃‍♂️',
        type: AchievementType.marathonListener,
        rarity: AchievementRarity.epic,
        badgeType: AchievementBadgeType.shield,
        points: 200,
        category: 'Endurance',
        requirements: {'continuous_listen_minutes': 120},
      ),
      AchievementModel(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Play music after midnight',
        icon: '🦉',
        type: AchievementType.nightOwl,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.hexagon,
        points: 25,
        category: 'Time',
        requirements: {'night_plays': 1},
      ),
      AchievementModel(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Play music before 6 AM',
        icon: '🐦',
        type: AchievementType.earlyBird,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.medal,
        points: 25,
        category: 'Time',
        requirements: {'morning_plays': 1},
      ),
      AchievementModel(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Like 50 songs',
        icon: '⭐',
        type: AchievementType.perfectionist,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.star,
        points: 75,
        category: 'Taste',
        requirements: {'songs_liked': 50},
      ),
      AchievementModel(
        id: 'explorer',
        title: 'Explorer',
        description: 'Discover 20 different artists',
        icon: '🔍',
        type: AchievementType.explorer,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.hexagon,
        points: 100,
        category: 'Discovery',
        requirements: {'unique_artists': 20},
      ),
      AchievementModel(
        id: 'collector',
        title: 'Collector',
        description: 'Add 500 songs to your library',
        icon: '📚',
        type: AchievementType.collector,
        rarity: AchievementRarity.epic,
        badgeType: AchievementBadgeType.shield,
        points: 300,
        category: 'Library',
        requirements: {'total_songs': 500},
      ),
      AchievementModel(
        id: 'zen_master',
        title: 'Zen Master',
        description: 'Use the app for 30 consecutive days',
        icon: '🧘‍♂️',
        type: AchievementType.zenMaster,
        rarity: AchievementRarity.legendary,
        badgeType: AchievementBadgeType.medal,
        points: 500,
        category: 'Loyalty',
        requirements: {'consecutive_days': 30},
        isSecret: true,
      ),
    ];

    final batch = _firestore.batch();
    for (final achievement in defaultAchievements) {
      final docRef =
          _firestore.collection(achievementsCollection).doc(achievement.id);
      batch.set(docRef, achievement.toMap());
    }
    await batch.commit();
    debugPrint('Default achievements created successfully');
  }

  /// Get all available achievements
  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final user = _auth.currentUser;
      debugPrint('Getting achievements for user: ${user?.uid ?? 'guest'}');

      if (user != null) {
        // User is logged in - fetch from Firestore
        final snapshot =
            await _firestore.collection(achievementsCollection).get();

        final achievements = snapshot.docs
            .map((doc) => AchievementModel.fromMap(doc.data()))
            .toList();

        debugPrint('Found ${achievements.length} achievements in Firestore');

        // If no achievements in Firestore, create them and return local achievements
        if (achievements.isEmpty) {
          debugPrint(
              'No achievements in Firestore, creating default achievements');
          await _createDefaultAchievements();
          debugPrint('Created default achievements in Firestore');

          // Return local achievements for immediate use
          final localAchievements = _getLocalAchievements();
          debugPrint('Local achievements count: ${localAchievements.length}');
          return localAchievements;
        }

        return achievements;
      } else {
        // User is not logged in - use local default achievements
        debugPrint('User not logged in, using local achievements');
        final localAchievements = _getLocalAchievements();
        debugPrint('Local achievements count: ${localAchievements.length}');
        return localAchievements;
      }
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      // Fallback to local achievements
      final localAchievements = _getLocalAchievements();
      debugPrint(
          'Fallback local achievements count: ${localAchievements.length}');
      return localAchievements;
    }
  }

  /// Get local achievements (default or cached)
  List<AchievementModel> _getLocalAchievements() {
    // Return default achievements for guest users
    return [
      AchievementModel(
        id: 'first_song',
        title: 'First Steps',
        description: 'Play your first song',
        icon: '🎵',
        type: AchievementType.firstSong,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.medal,
        points: 10,
        category: 'Music',
        requirements: {'songs_played': 1},
      ),
      AchievementModel(
        id: 'music_lover',
        title: 'Music Lover',
        description: 'Play 100 songs',
        icon: '❤️',
        type: AchievementType.musicLover,
        rarity: AchievementRarity.common,
        badgeType: AchievementBadgeType.star,
        points: 50,
        category: 'Music',
        requirements: {'songs_played': 100},
      ),
      AchievementModel(
        id: 'playlist_master',
        title: 'Playlist Master',
        description: 'Create 5 playlists',
        icon: '📝',
        type: AchievementType.playlistMaster,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.hexagon,
        points: 100,
        category: 'Organization',
        requirements: {'playlists_created': 5},
      ),
      AchievementModel(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Like 50 songs',
        icon: '⭐',
        type: AchievementType.perfectionist,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.star,
        points: 75,
        category: 'Taste',
        requirements: {'songs_liked': 50},
      ),
      AchievementModel(
        id: 'explorer',
        title: 'Explorer',
        description: 'Discover 20 different artists',
        icon: '🔍',
        type: AchievementType.explorer,
        rarity: AchievementRarity.rare,
        badgeType: AchievementBadgeType.hexagon,
        points: 100,
        category: 'Discovery',
        requirements: {'unique_artists': 20},
      ),
    ];
  }

  /// Get user's unlocked achievements
  Future<List<UserAchievementModel>> getUserAchievements(String userId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // User is logged in - fetch from Firestore
        final snapshot = await _firestore
            .collection(userAchievementsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final achievements = snapshot.docs
            .map((doc) => UserAchievementModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.unlockedAt
              .compareTo(a.unlockedAt)); // Sort by unlockedAt descending

        // Save to SQLite
        for (final achievement in achievements) {
          await _database.saveUserAchievement(achievement);
        }
        return achievements;
      } else {
        // User is not logged in - use local SQLite storage
        return await _database.getUserAchievements(userId);
      }
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      // Fallback to local SQLite storage
      return await _database.getUserAchievements(userId);
    }
  }

  /// Get achievement progress for a user
  Future<Map<String, AchievementProgress>> getUserProgress(
      String userId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // User is logged in - fetch from Firestore
        final snapshot = await _firestore
            .collection(achievementProgressCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final progressMap = <String, AchievementProgress>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final progress = AchievementProgress.fromMap(data);
          progressMap[progress.achievementId] = progress;

          // Save to SQLite
          await _database.saveAchievementProgress(progress, userId);
        }

        return progressMap;
      } else {
        // User is not logged in - use local SQLite storage
        return await _database.getUserProgress(userId);
      }
    } catch (e) {
      debugPrint('Error getting user progress: $e');
      // Fallback to local SQLite storage
      return await _database.getUserProgress(userId);
    }
  }

  /// Unlock an achievement for a user
  Future<bool> unlockAchievement(String userId, String achievementId) async {
    try {
      final user = _auth.currentUser;

      // Check if already unlocked (from local or Firestore)
      final existingAchievements = await getUserAchievements(userId);
      if (existingAchievements.any((a) => a.achievementId == achievementId)) {
        return false;
      }

      // Create achievement
      final userAchievement = UserAchievementModel(
        id: '${userId}_$achievementId',
        userId: userId,
        achievementId: achievementId,
        unlockedAt: DateTime.now(),
        isNew: true,
      );

      if (user != null) {
        // User is logged in - save to Firestore (with Timestamp)
        await _firestore
            .collection(userAchievementsCollection)
            .doc(userAchievement.id)
            .set({
          'id': userAchievement.id,
          'userId': userAchievement.userId,
          'achievementId': userAchievement.achievementId,
          'unlockedAt': Timestamp.fromDate(userAchievement.unlockedAt),
          'isNew': userAchievement.isNew,
          'progress': userAchievement.progress,
          'lastUpdated': userAchievement.lastUpdated != null
              ? Timestamp.fromDate(userAchievement.lastUpdated!)
              : null,
        });

        // Mark as not new after a delay
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            await _firestore
                .collection(userAchievementsCollection)
                .doc(userAchievement.id)
                .update({'isNew': false});
          } catch (e) {
            debugPrint('Error updating achievement new status: $e');
          }
        });
      }

      // Always save to SQLite
      await _database.saveUserAchievement(userAchievement);

      debugPrint('Achievement unlocked: $achievementId for user: $userId');

      // Trigger achievement unlock notification
      achievementUnlockTrigger.value++;

      return true;
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      return false;
    }
  }

  /// Update achievement progress
  Future<void> updateProgress(
    String userId,
    String achievementId,
    int currentValue,
    int targetValue,
  ) async {
    try {
      final user = _auth.currentUser;

      final progress = AchievementProgress(
        achievementId: achievementId,
        currentValue: currentValue,
        targetValue: targetValue,
        progressPercentage: targetValue > 0
            ? (currentValue / targetValue).clamp(0.0, 1.0)
            : 0.0,
        isCompleted: currentValue >= targetValue,
        lastUpdated: DateTime.now(),
      );

      if (user != null) {
        // User is logged in - save to Firestore (with Timestamp)
        await _firestore
            .collection(achievementProgressCollection)
            .doc('${userId}_$achievementId')
            .set({
          'achievementId': progress.achievementId,
          'currentValue': progress.currentValue,
          'targetValue': progress.targetValue,
          'progressPercentage': progress.progressPercentage,
          'isCompleted': progress.isCompleted,
          'lastUpdated': progress.lastUpdated != null
              ? Timestamp.fromDate(progress.lastUpdated!)
              : null,
          'userId': userId,
        }, SetOptions(merge: true));
      }

      // Always save to SQLite
      await _database.saveAchievementProgress(progress, userId);

      // If completed, unlock the achievement
      if (progress.isCompleted) {
        await unlockAchievement(userId, achievementId);
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  /// Check and trigger achievement based on user actions
  Future<void> checkAchievements(
      String userId, Map<String, dynamic> stats) async {
    try {
      final achievements = await getAllAchievements();

      for (final achievement in achievements) {
        if (achievement.requirements == null) continue;

        final newProgress = <String, int>{};

        for (final entry in achievement.requirements!.entries) {
          final statKey = entry.key;
          final currentValue = stats[statKey] ?? 0;
          newProgress[statKey] = currentValue;
        }

        // Update progress
        final totalRequired = achievement.requirements!.values
            .fold(0, (sum, value) => sum + (value as int));
        final totalCurrent =
            newProgress.values.fold(0, (sum, value) => sum + value);

        await updateProgress(
          userId,
          achievement.id,
          totalCurrent,
          totalRequired,
        );
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  /// Get user's achievement statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      final allAchievements = await getAllAchievements();

      final totalPoints = userAchievements.fold(0, (sums, achievement) {
        try {
          final achievementData = allAchievements
              .firstWhere((a) => a.id == achievement.achievementId);
          return sums + achievementData.points;
        } catch (e) {
          debugPrint(
              'Achievement not found for stats: ${achievement.achievementId}');
          return sums;
        }
      });

      final rarityCounts = <AchievementRarity, int>{};
      for (final rarity in AchievementRarity.values) {
        rarityCounts[rarity] = 0;
      }

      for (final userAchievement in userAchievements) {
        try {
          final achievementData = allAchievements
              .firstWhere((a) => a.id == userAchievement.achievementId);
          rarityCounts[achievementData.rarity] =
              (rarityCounts[achievementData.rarity] ?? 0) + 1;
        } catch (e) {
          debugPrint(
              'Achievement not found for rarity count: ${userAchievement.achievementId}');
        }
      }

      return {
        'totalAchievements': userAchievements.length,
        'totalPoints': totalPoints,
        'rarityCounts': rarityCounts,
        'completionPercentage': allAchievements.isNotEmpty
            ? (userAchievements.length / allAchievements.length) * 100
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting user achievement stats: $e');
      return {
        'totalAchievements': 0,
        'totalPoints': 0,
        'rarityCounts': <AchievementRarity, int>{},
        'completionPercentage': 0.0,
      };
    }
  }

  /// Get recently unlocked achievements
  Future<List<UserAchievementModel>> getRecentAchievements(String userId,
      {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(userAchievementsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final achievements = snapshot.docs
          .map((doc) => UserAchievementModel.fromMap(doc.data()))
          .toList()
        ..sort((a, b) => b.unlockedAt
            .compareTo(a.unlockedAt)); // Sort by unlockedAt descending

      return achievements.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent achievements: $e');
      return [];
    }
  }

  /// Mark achievement as viewed (not new anymore)
  Future<void> markAsViewed(String userId, String achievementId) async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // User is logged in - update in Firestore
        await _firestore
            .collection(userAchievementsCollection)
            .doc('${userId}_$achievementId')
            .update({'isNew': false});
      }

      // Always update in SQLite
      final achievement =
          await _database.getUserAchievement(userId, achievementId);
      if (achievement != null) {
        final updatedAchievement = achievement.copyWith(isNew: false);
        await _database.updateUserAchievement(updatedAchievement);
      }
    } catch (e) {
      debugPrint('Error marking achievement as viewed: $e');
    }
  }

  /// Sync local achievements to Firestore when user logs in
  Future<void> syncLocalToFirestore(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('Syncing local achievements to Firestore for user: $userId');

      // First, migrate guest/empty data to real user ID
      await _migrateGuestDataToUser(userId);

      // Get all local achievements for this user
      final localAchievements = await _database.getUserAchievements(userId);
      final localProgress = await _database.getUserProgress(userId);

      // Sync user achievements (merge strategy - don't replace)
      if (localAchievements.isNotEmpty) {
        // Get existing Firestore achievements to avoid duplicates
        final existingSnapshot = await _firestore
            .collection(userAchievementsCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final existingAchievementIds = existingSnapshot.docs
            .map((doc) => doc.data()['achievementId'] as String)
            .toSet();

        // Only upload new achievements (not already in Firestore)
        for (final achievement in localAchievements) {
          if (!existingAchievementIds.contains(achievement.achievementId)) {
            await _firestore
                .collection(userAchievementsCollection)
                .doc(achievement.id)
                .set({
              'id': achievement.id,
              'userId': achievement.userId,
              'achievementId': achievement.achievementId,
              'unlockedAt': Timestamp.fromDate(achievement.unlockedAt),
              'isNew': achievement.isNew,
              'progress': achievement.progress,
              'lastUpdated': achievement.lastUpdated != null
                  ? Timestamp.fromDate(achievement.lastUpdated!)
                  : null,
            });
            debugPrint(
                'Uploaded new achievement: ${achievement.achievementId}');
          } else {
            debugPrint(
                'Achievement ${achievement.achievementId} already exists in Firestore, skipping');
          }
        }
      }

      // Replace all progress in Firestore (complete replacement strategy)
      if (localProgress.isNotEmpty) {
        // Delete existing progress for this user
        final existingProgressSnapshot = await _firestore
            .collection(achievementProgressCollection)
            .where('userId', isEqualTo: userId)
            .get();

        final progressBatch = _firestore.batch();
        for (final doc in existingProgressSnapshot.docs) {
          progressBatch.delete(doc.reference);
        }
        await progressBatch.commit();

        // Upload all local progress
        for (final entry in localProgress.entries) {
          await _firestore
              .collection(achievementProgressCollection)
              .doc('${userId}_${entry.key}')
              .set({
            'achievementId': entry.value.achievementId,
            'currentValue': entry.value.currentValue,
            'targetValue': entry.value.targetValue,
            'progressPercentage': entry.value.progressPercentage,
            'isCompleted': entry.value.isCompleted,
            'lastUpdated': entry.value.lastUpdated != null
                ? Timestamp.fromDate(entry.value.lastUpdated!)
                : null,
            'userId': userId,
          });
        }
      }

      debugPrint(
          'Achievement sync completed for user: $userId (achievements: merge, progress: replace)');
    } catch (e) {
      debugPrint('Error syncing achievements to Firestore: $e');
    }
  }

  /// Migrate guest/empty data to real user ID
  Future<void> _migrateGuestDataToUser(String userId) async {
    try {
      debugPrint('Migrating guest achievement data to user: $userId');

      // Get all guest achievements
      final guestAchievements = await _database.getUserAchievements('guest');
      final emptyAchievements = await _database.getUserAchievements('');
      final guestProgress = await _database.getUserProgress('guest');
      final emptyProgress = await _database.getUserProgress('');

      // Migrate achievements
      for (final achievement in [...guestAchievements, ...emptyAchievements]) {
        final migratedAchievement = achievement.copyWith(
          id: '${userId}_${achievement.achievementId}',
          userId: userId,
        );
        await _database.saveUserAchievement(migratedAchievement);
      }

      // Migrate progress
      for (final entry in {...guestProgress, ...emptyProgress}.entries) {
        await _database.saveAchievementProgress(entry.value, userId);
      }

      // Clear guest data
      await _database.clearUserData('guest');
      await _database.clearUserData('');

      debugPrint('Guest achievement data migrated successfully');
    } catch (e) {
      debugPrint('Error migrating guest achievement data: $e');
    }
  }

  /// Clear all user data (for account deletion)
  Future<void> clearUserData(String userId) async {
    try {
      debugPrint('Clearing achievement data for user: $userId');
      await _database.clearUserData(userId);
      debugPrint('Achievement data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing achievement data: $e');
      rethrow;
    }
  }
}
