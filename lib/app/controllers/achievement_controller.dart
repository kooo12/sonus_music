import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/achievement_service.dart';
import '../data/models/achievement_model.dart';

class AchievementController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final AchievementService _achievementService = Get.find<AchievementService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controller for unlock overlay
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late ConfettiController _confettiController;

  // Observable data
  final RxList<AchievementModel> allAchievements = <AchievementModel>[].obs;
  final RxList<UserAchievementModel> userAchievements =
      <UserAchievementModel>[].obs;
  final RxMap<String, AchievementProgress> userProgress =
      <String, AchievementProgress>{}.obs;
  final RxMap<String, dynamic> userStats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUnlockOverlayVisible = false.obs;
  final Rx<UserAchievementModel?> currentUnlockedAchievement =
      Rx<UserAchievementModel?>(null);

  // Getters
  List<AchievementModel> get unlockedAchievements {
    return userAchievements
        .map((userAchievement) {
          try {
            return allAchievements.firstWhere((achievement) =>
                achievement.id == userAchievement.achievementId);
          } catch (e) {
            debugPrint(
                'Achievement not found: ${userAchievement.achievementId}');
            return null;
          }
        })
        .where((achievement) => achievement != null)
        .cast<AchievementModel>()
        .toList();
  }

  List<AchievementModel> get lockedAchievements {
    final unlockedIds = userAchievements
        .map((achievement) => achievement.achievementId)
        .toSet();
    return allAchievements
        .where((achievement) => !unlockedIds.contains(achievement.id))
        .toList();
  }

  List<UserAchievementModel> get newAchievements {
    return userAchievements.where((achievement) => achievement.isNew).toList();
  }

  int get totalPoints => userStats['totalPoints'] ?? 0;
  int get totalAchievements => userStats['totalAchievements'] ?? 0;
  double get completionPercentage => userStats['completionPercentage'] ?? 0.0;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _loadAchievements();

    // Listen for achievement unlocks
    ever(_achievementService.achievementUnlockTrigger, (_) {
      debugPrint('Achievement unlock detected, refreshing...');
      _loadAchievements();
    });

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('User logged in, refreshing achievements...');
        _loadAchievements();
      }
    });

    // // Listen for auth state changes to refresh achievements
    // ever(_auth.authStateChanges(), (user) {
    //   if (user != null) {
    //     debugPrint('User logged in, refreshing achievements...');
    //     _loadAchievements();
    //   }
    // });
  }

  @override
  void onClose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.onClose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
    ));

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _animationController.forward().then((_) {
      _confettiController.play();
    });
  }

  Future<void> _loadAchievements() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      // Use 'guest' as userId for non-logged in users
      final userId = user?.uid ?? 'guest';
      debugPrint('Loading achievements for user: $userId');

      // Load all achievements and user data in parallel
      final results = await Future.wait([
        _achievementService.getAllAchievements(),
        _achievementService.getUserAchievements(userId),
        _achievementService.getUserProgress(userId),
        _achievementService.getUserStats(userId),
      ]);

      allAchievements.value = results[0] as List<AchievementModel>;
      userAchievements.value = results[1] as List<UserAchievementModel>;
      userProgress.value = results[2] as Map<String, AchievementProgress>;
      userStats.value = results[3] as Map<String, dynamic>;

      debugPrint('Loaded ${allAchievements.length} all achievements');
      debugPrint('Loaded ${userAchievements.length} user achievements');
      debugPrint(
          'User achievement IDs: ${userAchievements.map((a) => a.achievementId).toList()}');
      debugPrint(
          'All achievement IDs: ${allAchievements.map((a) => a.id).toList()}');

      // Check for new achievements to show overlay
      _checkForNewAchievements();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _checkForNewAchievements() {
    final newAchievements =
        userAchievements.where((achievement) => achievement.isNew).toList();
    if (newAchievements.isNotEmpty) {
      debugPrint('Found ${newAchievements.length} new achievements to display');
      // Small delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        _showUnlockOverlay(newAchievements.first);
      });
    }
  }

  Future<void> refreshAchievements() async {
    await _loadAchievements();
  }

  Future<void> checkAchievements(Map<String, dynamic> stats) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'guest';

      await _achievementService.checkAchievements(userId, stats);
      await _loadAchievements();
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  void _showUnlockOverlay(UserAchievementModel achievement) {
    debugPrint(
        'Showing unlock overlay for achievement: ${achievement.achievementId}');
    currentUnlockedAchievement.value = achievement;
    isUnlockOverlayVisible.value = true;

    // Reset animation first
    _animationController.reset();

    _animationController.forward().then((_) {
      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (isUnlockOverlayVisible.value) {
          hideUnlockOverlay();
        }
      });
    });
  }

  void hideUnlockOverlay() {
    _animationController.reverse().then((_) {
      isUnlockOverlayVisible.value = false;
      currentUnlockedAchievement.value = null;
    });
  }

  Future<void> markAchievementAsViewed(String achievementId) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'guest';

      await _achievementService.markAsViewed(userId, achievementId);

      // Update local state
      final index = userAchievements.indexWhere(
        (achievement) => achievement.achievementId == achievementId,
      );
      if (index != -1) {
        userAchievements[index] =
            userAchievements[index].copyWith(isNew: false);
        userAchievements.refresh();
      }
    } catch (e) {
      debugPrint('Error marking achievement as viewed: $e');
    }
  }

  AchievementModel? getAchievementById(String achievementId) {
    try {
      return allAchievements.firstWhere(
        (achievement) => achievement.id == achievementId,
      );
    } catch (e) {
      return null;
    }
  }

  AchievementProgress? getProgressForAchievement(String achievementId) {
    return userProgress[achievementId];
  }

  bool isAchievementUnlocked(String achievementId) {
    return userAchievements.any(
      (achievement) => achievement.achievementId == achievementId,
    );
  }

  List<AchievementModel> getAchievementsByRarity(AchievementRarity rarity) {
    return allAchievements
        .where((achievement) => achievement.rarity == rarity)
        .toList();
  }

  List<AchievementModel> getAchievementsByCategory(String category) {
    return allAchievements
        .where((achievement) => achievement.category == category)
        .toList();
  }

  Map<AchievementRarity, int> getRarityCounts() {
    final counts = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      counts[rarity] = 0;
    }

    for (final userAchievement in userAchievements) {
      final achievement = getAchievementById(userAchievement.achievementId);
      if (achievement != null) {
        counts[achievement.rarity] = (counts[achievement.rarity] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Animation getters for UI
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get slideAnimation => _slideAnimation;
  AnimationController get animationController => _animationController;
  ConfettiController get confettiController => _confettiController;

  // Helper method to trigger achievement checks based on user actions
  Future<void> onSongPlayed() async {
    await checkAchievements({
      'songs_played': 1,
    });
  }

  Future<void> onPlaylistCreated() async {
    await checkAchievements({
      'playlists_created': 1,
    });
  }

  Future<void> onSongLiked() async {
    await checkAchievements({
      'songs_liked': 1,
    });
  }

  Future<void> onArtistDiscovered() async {
    await checkAchievements({
      'unique_artists': 1,
    });
  }

  Future<void> onLibraryUpdated(int songCount) async {
    await checkAchievements({
      'total_songs': songCount,
    });
  }

  Future<void> onTimeBasedAction(DateTime time) async {
    final hour = time.hour;
    final stats = <String, dynamic>{};

    if (hour >= 0 && hour < 6) {
      stats['night_plays'] = 1;
    } else if (hour >= 5 && hour < 8) {
      stats['morning_plays'] = 1;
    }

    if (stats.isNotEmpty) {
      await checkAchievements(stats);
    }
  }
}
