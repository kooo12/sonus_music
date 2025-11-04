import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final String? provider;
  final DateTime? createdAt;
  final bool isGuest;
  final bool isAdmin;
  final Map<String, dynamic>? preferences;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.profileImageUrl,
    this.phone,
    this.provider,
    this.createdAt,
    this.isGuest = true,
    this.isAdmin = false,
    this.preferences,
  });

  // Create guest user
  factory UserModel.guest() {
    return UserModel(
      id: '',
      name: 'SONUS',
      email: null,
      profileImageUrl: null,
      createdAt: DateTime.now(),
      isGuest: true,
      isAdmin: false,
      preferences: {
        'theme': 'system',
        'autoPlay': true,
        'shuffleMode': false,
        'repeatMode': 'off',
      },
    );
  }

  // Create authenticated user
  factory UserModel.authenticated({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
    String? phone,
    String? provider,
    bool isAdmin = false,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      phone: phone,
      provider: provider,
      createdAt: DateTime.now(),
      isGuest: false,
      isAdmin: isAdmin,
      preferences: preferences ??
          {
            'theme': 'system',
            'autoPlay': true,
            'shuffleMode': false,
            'repeatMode': 'off',
          },
    );
  }

  // Create admin user
  factory UserModel.admin({
    required String id,
    required String name,
    required String email,
    String? profileImageUrl,
    String? phone,
    String? provider,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
      phone: phone,
      provider: provider,
      createdAt: DateTime.now(),
      isGuest: false,
      isAdmin: true,
      preferences: preferences ??
          {
            'theme': 'system',
            'autoPlay': true,
            'shuffleMode': false,
            'repeatMode': 'off',
          },
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'provider': provider,
      'createdAt': createdAt?.toIso8601String(),
      'isGuest': isGuest,
      'isAdmin': isAdmin,
      'preferences': preferences,
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['uid'],
      name: json['displayName'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profileImageUrl'],
      provider: json['provider'],
      createdAt: json['createdAt'] != null && json['createdAt'] is Timestamp
          ? json['createdAt'].toDate()
          : null,
      isGuest: json['isGuest'] ?? true,
      isAdmin: json['isAdmin'] ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  // Copy with new values
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? provider,
    DateTime? createdAt,
    bool? isGuest,
    bool? isAdmin,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      isAdmin: isAdmin ?? this.isAdmin,
      preferences: preferences ?? this.preferences,
    );
  }

  // Update preferences
  UserModel updatePreferences(Map<String, dynamic> newPreferences) {
    final updatedPreferences = Map<String, dynamic>.from(preferences ?? {});
    updatedPreferences.addAll(newPreferences);
    return copyWith(preferences: updatedPreferences);
  }

  // Get preference value
  T? getPreference<T>(String key, [T? defaultValue]) {
    return preferences?[key] as T? ?? defaultValue;
  }

  // Get display name
  String get displayName => name ?? (isGuest ? 'SONUS' : 'User');

  // Get initials for avatar
  String get initials {
    if (name == null || name!.isEmpty) return 'UN';
    final words = name!.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, isGuest: $isGuest}';
  }
}
