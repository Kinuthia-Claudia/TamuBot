import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final resp = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (resp == null) return null;
      return ProfileModel.fromMap(resp);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createProfileIfNotExists(ProfileModel profile) async {
    try {
      await _client.from('profiles').upsert(profile.toMap());
    } catch (e) {
      rethrow;
    }
  }

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
      return ProfileModel.fromMap(resp);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadAvatar(String userId, File file, {String bucket = 'avatars'}) async {
    try {
      final ext = file.path.split('.').last;
      final path = 'avatars/$userId/avatar.${ext}';

      // upload
      // ignore: unused_local_variable
      final res = await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(upsert: true),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }
}
