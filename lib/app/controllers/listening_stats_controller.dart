import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/listening_stats_service.dart';

class ListeningStatsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ListeningStatsService statsService = Get.find<ListeningStatsService>();

  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  final RxBool _showAll = false.obs;

  // Getters for UI
  bool get showAll => _showAll.value;

  String get totalHoursThisMonth => statsService.getFormattedTotalHours();
  String get topArtist => statsService.getTopArtist();
  String get mostPlayedSong => statsService.getMostPlayedSong();
  String get mostPlayedSongTitle => statsService.getMostPlayedSongTitle();
  int get mostPlayedSongCount => statsService.getMostPlayedSongCount();
  String get timePatternDescription => statsService.getTimePatternDescription();
  String get listeningStyle => statsService.getListeningStyle();
  String get listeningStyleDescription =>
      statsService.getListeningStyleDescription();
  bool get isLoading => statsService.isLoading;

  set showAll(bool value) => _showAll.value = value;

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutBack,
    ));

    // Listen for stats changes
    ever(statsService.currentStatsRx, (_) {
      update(); // Trigger UI update
    });

    // Also listen for loading state changes
    ever(statsService.isLoadingRx, (_) {
      update(); // Trigger UI update when loading state changes
    });

    // Listen for showAll changes to manage animation
    ever(_showAll, (bool showAll) {
      if (showAll) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
    });
  }

  void toggleShowAll() {
    _showAll.value = !_showAll.value;
  }

  /// Refresh statistics data
  Future<void> refreshStats() async {
    try {
      await statsService.refreshStats();
      update();
    } catch (e) {
      debugPrint('Error refreshing stats: $e');
    }
  }

  /// Get listening time pattern with emoji
  String getTimePatternWithEmoji() {
    final description = timePatternDescription;

    if (description.contains('Night Owl')) {
      return '🌙 $description';
    } else if (description.contains('Morning Person')) {
      return '🌅 $description';
    } else if (description.contains('Afternoon Listener')) {
      return '☀️ $description';
    } else if (description.contains('Evening Listener')) {
      return '🌆 $description';
    } else {
      return '🌅 $description';
    }
  }

  /// Get formatted stats for display
  Map<String, String> getFormattedStats() {
    return {
      'totalHours': totalHoursThisMonth,
      'topArtist': topArtist,
      'mostPlayedSong': mostPlayedSong,
      'timePattern': getTimePatternWithEmoji(),
    };
  }

  /// Check if user has any listening data
  bool get hasListeningData {
    return mostPlayedSongCount > 0 || totalHoursThisMonth != '0 hours';
  }

  /// Get listening stats summary
  String get listeningSummary {
    if (!hasListeningData) {
      return 'Start listening to music to see your stats!'.tr;
    }

    return 'You\'ve listened to $totalHoursThisMonth this month. Your top artist is $topArtist.';
  }
}
