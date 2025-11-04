import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  firstSong,
  musicLover,
  playlistMaster,
  marathonListener,
  nightOwl,
  earlyBird,
  socialButterfly,
  perfectionist,
  explorer,
  collector,
  artist,
  discoverer,
  loyalist,
  speedDemon,
  zenMaster,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

// Visual style of the achievement badge
enum AchievementBadgeType {
  star, // 5-point star badge
  shield, // shield/crest style
  hexagon, // hexagon plate
  medal, // circular medal with ribbons
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementRarity rarity;
  final AchievementBadgeType badgeType;
  final int points;
  final String? category;
  final bool isSecret;
  final Map<String, dynamic>? requirements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    this.badgeType = AchievementBadgeType.star,
    required this.points,
    this.category,
    this.isSecret = false,
    this.requirements,
    this.createdAt,
    this.updatedAt,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${map['type']}',
        orElse: () => AchievementType.firstSong,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.toString() == 'AchievementRarity.${map['rarity']}',
        orElse: () => AchievementRarity.common,
      ),
      badgeType: AchievementBadgeType.values.firstWhere(
        (e) => e.toString() == 'AchievementBadgeType.${map['badgeType']}',
        orElse: () => AchievementBadgeType.star,
      ),
      points: map['points'] ?? 0,
      category: map['category'],
      isSecret: map['isSecret'] ?? false,
      requirements: map['requirements'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int))
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'badgeType': badgeType.toString().split('.').last,
      'points': points,
      'category': category,
      'isSecret': isSecret,
      'requirements': requirements,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    AchievementRarity? rarity,
    AchievementBadgeType? badgeType,
    int? points,
    String? category,
    bool? isSecret,
    Map<String, dynamic>? requirements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      badgeType: badgeType ?? this.badgeType,
      points: points ?? this.points,
      category: category ?? this.category,
      isSecret: isSecret ?? this.isSecret,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserAchievementModel {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final bool isNew;
  final Map<String, dynamic>? progress;
  final DateTime? lastUpdated;

  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.isNew = false,
    this.progress,
    this.lastUpdated,
  });

  factory UserAchievementModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      achievementId: map['achievementId'] ?? '',
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] is Timestamp
              ? (map['unlockedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['unlockedAt'] as int))
          : DateTime.now(),
      isNew: map['isNew'] ?? false,
      progress: map['progress'],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] is Timestamp
              ? (map['lastUpdated'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int))
          : null,
    );
  }

  factory UserAchievementModel.fromLocalMap(Map<String, dynamic> map) {
    return UserAchievementModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      achievementId: map['achievement_id'] ?? '',
      unlockedAt:
          DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int),
      isNew: (map['is_new'] as int) == 1,
      progress: map['progress'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['progress'] as String))
          : null,
      lastUpdated: map['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'isNew': isNew,
      'progress': progress,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }

  UserAchievementModel copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    bool? isNew,
    Map<String, dynamic>? progress,
    DateTime? lastUpdated,
  }) {
    return UserAchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isNew: isNew ?? this.isNew,
      progress: progress ?? this.progress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class AchievementProgress {
  final String achievementId;
  final int currentValue;
  final int targetValue;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime? lastUpdated;

  AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.progressPercentage,
    required this.isCompleted,
    this.lastUpdated,
  });

  factory AchievementProgress.fromMap(Map<String, dynamic> map) {
    final current = map['currentValue'] ?? 0;
    final target = map['targetValue'] ?? 1;
    return AchievementProgress(
      achievementId: map['achievementId'] ?? '',
      currentValue: current,
      targetValue: target,
      progressPercentage: target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0,
      isCompleted: current >= target,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] is Timestamp
              ? (map['lastUpdated'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int))
          : null,
    );
  }

  factory AchievementProgress.fromLocalMap(Map<String, dynamic> map) {
    final current = map['current_value'] ?? 0;
    final target = map['target_value'] ?? 1;
    return AchievementProgress(
      achievementId: map['achievement_id'] ?? '',
      currentValue: current,
      targetValue: target,
      progressPercentage: map['progress_percentage']?.toDouble() ??
          (target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0),
      isCompleted: (map['is_completed'] as int) == 1,
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'progressPercentage': progressPercentage,
      'isCompleted': isCompleted,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
    };
  }
}
