// lib/modules/profile/profile_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  /// Fetch profile for a given user id. Returns null if not found.
  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final resp = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (resp == null) return null;
      return ProfileModel.fromMap(resp as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a profile (insert) - safe to call if not existing
  Future<void> createProfileIfNotExists(ProfileModel profile) async {
    try {
      await _client.from('profiles').upsert(profile.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Update profile fields (partial update supported)
  Future<ProfileModel> updateProfile(String userId, Map<String, dynamic> changes) async {
    try {
      changes['updated_at'] = DateTime.now().toIso8601String();
      final resp = await _client
          .from('profiles')
          .update(changes)
          .eq('id', userId)
          .select()
          .maybeSingle();

      if (resp == null) {
        throw Exception('Profile update returned null');
      }
      return ProfileModel.fromMap(resp as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Optional: upload avatar image to Supabase Storage and return public URL.
  /// Requires a storage bucket (e.g. 'avatars') and public or signed URLs enabled.
  Future<String?> uploadAvatar(String userId, File file, {String bucket = 'avatars'}) async {
    try {
      final ext = file.path.split('.').last;
      final path = 'avatars/$userId/avatar.${ext}';

      // upload
      final res = await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(upsert: true),
          );

      // get public URL (if your bucket is public) or get signed URL
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }
}
