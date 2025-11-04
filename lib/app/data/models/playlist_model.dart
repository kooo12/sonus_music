import 'song_model.dart';

class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<SongModel> songs;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImagePath;
  final bool
      isDefault; // For system playlists like "Liked Songs", "Recently Played"
  final String? colorHex; // Color in hex format for custom playlists

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
    this.coverImagePath,
    this.isDefault = false,
    this.colorHex,
  });

  // Create default playlists
  factory PlaylistModel.likedSongs() {
    return PlaylistModel(
      id: 'liked_songs',
      name: 'Liked Songs',
      description: 'Your favorite tracks',
      songs: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );
  }

  factory PlaylistModel.recentlyPlayed() {
    return PlaylistModel(
      id: 'recently_played',
      name: 'Recently Played',
      description: 'Your recently played tracks',
      songs: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );
  }

  factory PlaylistModel.mostPlayed() {
    return PlaylistModel(
      id: 'most_played',
      name: 'Most Played',
      description: 'Your most played tracks',
      songs: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImagePath': coverImagePath,
      'isDefault': isDefault,
      'colorHex': colorHex,
    };
  }

  // Create from JSON
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Playlist',
      description: json['description'],
      songs: (json['songs'] as List<dynamic>?)
              ?.map((songJson) => SongModel.fromJson(songJson))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      coverImagePath: json['coverImagePath'],
      isDefault: json['isDefault'] ?? false,
      colorHex: json['colorHex'],
    );
  }

  // Copy with new values
  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<SongModel>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImagePath,
    bool? isDefault,
    String? colorHex,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      isDefault: isDefault ?? this.isDefault,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  // Add song to playlist
  PlaylistModel addSong(SongModel song) {
    if (!songs.contains(song)) {
      final newSongs = List<SongModel>.from(songs)..add(song);
      return copyWith(
        songs: newSongs,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Remove song from playlist
  PlaylistModel removeSong(SongModel song) {
    final newSongs = List<SongModel>.from(songs)..remove(song);
    return copyWith(
      songs: newSongs,
      updatedAt: DateTime.now(),
    );
  }

  // Get total duration of all songs
  int get totalDuration {
    return songs.fold(0, (total, song) => total + song.duration);
  }

  // Get formatted total duration
  String get formattedTotalDuration {
    final totalMinutes = (totalDuration / 60000).floor();
    final hours = (totalMinutes / 60).floor();
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get song count
  int get songCount => songs.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlaylistModel{id: $id, name: $name, songCount: $songCount}';
  }
}
