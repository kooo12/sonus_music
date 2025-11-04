import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:get/get.dart';

class ListeningStatsModel {
  final String id;
  final String userId;
  final int totalHoursThisMonth;
  final String topArtist;
  final String mostPlayedSong;
  final int mostPlayedSongCount;
  final Map<String, int> timePatterns; // hour -> play count
  final Map<String, int> genreStats; // genre -> play count
  final Map<String, int> artistStats; // artist -> play count
  final Map<String, int> songPlayCounts; // songId -> play count
  final DateTime lastUpdated;
  final DateTime monthYear; // Track which month these stats are for

  ListeningStatsModel({
    required this.id,
    required this.userId,
    required this.totalHoursThisMonth,
    required this.topArtist,
    required this.mostPlayedSong,
    required this.mostPlayedSongCount,
    required this.timePatterns,
    required this.genreStats,
    required this.artistStats,
    required this.songPlayCounts,
    required this.lastUpdated,
    required this.monthYear,
  });

  // Create empty stats for new users
  factory ListeningStatsModel.empty(String userId) {
    final now = DateTime.now();
    return ListeningStatsModel(
      id: '${userId}_${now.year}_${now.month}',
      userId: userId,
      totalHoursThisMonth: 0,
      topArtist: 'No data yet',
      mostPlayedSong: 'No data yet',
      mostPlayedSongCount: 0,
      timePatterns: {},
      genreStats: {},
      artistStats: {},
      songPlayCounts: {},
      lastUpdated: now,
      monthYear: DateTime(now.year, now.month),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalHoursThisMonth': totalHoursThisMonth,
      'topArtist': topArtist,
      'mostPlayedSong': mostPlayedSong,
      'mostPlayedSongCount': mostPlayedSongCount,
      'timePatterns': timePatterns,
      'genreStats': genreStats,
      'artistStats': artistStats,
      'songPlayCounts': songPlayCounts,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'monthYear': Timestamp.fromDate(monthYear),
    };
  }

  // Convert to Map for local storage (SQLite)
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'user_id': userId,
      'month_year': '${monthYear.year}_${monthYear.month}',
      'total_hours_this_month': totalHoursThisMonth,
      'top_artist': topArtist,
      'most_played_song': mostPlayedSong,
      'most_played_song_count': mostPlayedSongCount,
      'time_patterns': jsonEncode(timePatterns),
      'genre_stats': jsonEncode(genreStats),
      'artist_stats': jsonEncode(artistStats),
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'created_at': monthYear.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore data
  factory ListeningStatsModel.fromMap(Map<String, dynamic> map) {
    return ListeningStatsModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      totalHoursThisMonth: map['totalHoursThisMonth'] ?? 0,
      topArtist: map['topArtist'] ?? 'No data yet',
      mostPlayedSong: map['mostPlayedSong'] ?? 'No data yet',
      mostPlayedSongCount: map['mostPlayedSongCount'] ?? 0,
      timePatterns: Map<String, int>.from(map['timePatterns'] ?? {}),
      genreStats: Map<String, int>.from(map['genreStats'] ?? {}),
      artistStats: Map<String, int>.from(map['artistStats'] ?? {}),
      songPlayCounts: Map<String, int>.from(map['songPlayCounts'] ?? {}),
      lastUpdated: map['lastUpdated'] is Timestamp
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] ?? 0),
      monthYear: map['monthYear'] is Timestamp
          ? (map['monthYear'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['monthYear'] ?? 0),
    );
  }

  // Create from local storage data (SQLite)
  factory ListeningStatsModel.fromLocalMap(Map<String, dynamic> map) {
    return ListeningStatsModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      totalHoursThisMonth: map['total_hours_this_month'] ?? 0,
      topArtist: map['top_artist'] ?? 'No data yet',
      mostPlayedSong: map['most_played_song'] ?? 'No data yet',
      mostPlayedSongCount: map['most_played_song_count'] ?? 0,
      timePatterns: _parseJsonMap(map['time_patterns']),
      genreStats: _parseJsonMap(map['genre_stats']),
      artistStats: _parseJsonMap(map['artist_stats']),
      songPlayCounts: {}, // Will be calculated from play history
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(map['last_updated'] ?? 0),
      monthYear: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
    );
  }

  // Helper method to parse JSON maps
  static Map<String, int> _parseJsonMap(dynamic jsonString) {
    if (jsonString == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  // Copy with new values
  ListeningStatsModel copyWith({
    String? id,
    String? userId,
    int? totalHoursThisMonth,
    String? topArtist,
    String? mostPlayedSong,
    int? mostPlayedSongCount,
    Map<String, int>? timePatterns,
    Map<String, int>? genreStats,
    Map<String, int>? artistStats,
    Map<String, int>? songPlayCounts,
    DateTime? lastUpdated,
    DateTime? monthYear,
  }) {
    return ListeningStatsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalHoursThisMonth: totalHoursThisMonth ?? this.totalHoursThisMonth,
      topArtist: topArtist ?? this.topArtist,
      mostPlayedSong: mostPlayedSong ?? this.mostPlayedSong,
      mostPlayedSongCount: mostPlayedSongCount ?? this.mostPlayedSongCount,
      timePatterns: timePatterns ?? this.timePatterns,
      genreStats: genreStats ?? this.genreStats,
      artistStats: artistStats ?? this.artistStats,
      songPlayCounts: songPlayCounts ?? this.songPlayCounts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  // Get listening time pattern description
  String get timePatternDescription {
    if (timePatterns.isEmpty) return 'No listening pattern data';

    // Find peak listening hours
    final sortedHours = timePatterns.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedHours.isEmpty) return 'No listening pattern data';

    final peakHour = sortedHours.first.key;
    final hour = int.tryParse(peakHour) ?? 0;

    if (hour >= 0 && hour < 6) {
      return 'Night Owl - You listen most at night'.tr;
    } else if (hour >= 6 && hour < 12) {
      return 'Morning Person - You start your day with music'.tr;
    } else if (hour >= 12 && hour < 18) {
      return 'Afternoon Listener - You enjoy music during the day'.tr;
    } else {
      return 'Evening Listener - You wind down with music'.tr;
    }
  }

  // Get formatted total hours
  String get formattedTotalHours {
    if (totalHoursThisMonth == 0) return '0 hours';
    if (totalHoursThisMonth == 1) return '1 hour';
    return '$totalHoursThisMonth hours';
  }

  // Get current month/year string
  String get monthYearString {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[monthYear.month - 1]} ${monthYear.year}';
  }
}
