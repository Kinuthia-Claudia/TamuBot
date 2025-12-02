import 'dart:convert';

class ProfileModel {
  final String id;
  final String? username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final List<String> dietaryPreferences;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    this.username,
    this.email,
    this.bio,
    this.avatarUrl,
    List<String>? dietaryPreferences,
    this.updatedAt,
  }) : dietaryPreferences = dietaryPreferences ?? [];

  ProfileModel copyWith({
    String? username,
    String? email,
    String? bio,
    String? avatarUrl,
    List<String>? dietaryPreferences,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    final dp = map['dietary_preferences'];
    List<String> prefs = [];
    if (dp is List) {
      prefs = dp.map((e) => e.toString()).toList();
    } else if (dp is String) {
      // if stored as JSON string
      try {
        final parsed = jsonDecode(dp) as List;
        prefs = parsed.map((e) => e.toString()).toList();
      } catch (_) {
        prefs = [];
      }
    } else if (dp == null) {
      prefs = [];
    }

    return ProfileModel(
      id: map['id'] as String,
      username: map['username'] as String?,
      email: map['email'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      dietaryPreferences: prefs,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      // store as JSON array
      'dietary_preferences': dietaryPreferences,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
