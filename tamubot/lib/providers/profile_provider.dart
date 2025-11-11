// lib/providers/profile_provider.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/profile/profile_model.dart';
import 'package:tamubot/modules/profile/profile_service.dart';

/// Profile service provider (so it can be overridden in tests)
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// The profile notifier manages loading/saving the current user's profile.
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final Ref ref;
  final ProfileService _service;

  ProfileNotifier(this.ref, this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }
      await loadProfile(user.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.fetchProfile(userId);
      if (profile == null) {
        // Create default profile record so RLS allows future updates
        final defaultProfile = ProfileModel(
          id: userId,
          username: null,
          email: Supabase.instance.client.auth.currentUser?.email,
          bio: null,
          avatarUrl: null,
          dietaryPreferences: [],
        );
        await _service.createProfileIfNotExists(defaultProfile);
        state = AsyncValue.data(defaultProfile);
      } else {
        state = AsyncValue.data(profile);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update profile fields (partial)
  Future<void> updateProfilePartial(Map<String, dynamic> changes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No logged in user.');

    state = AsyncValue.loading();
    try {
      final updated = await _service.updateProfile(user.id, changes);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Optional: upload avatar and update avatar_url
  Future<void> uploadAvatarAndSave(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No logged in user.');

    state = AsyncValue.loading();
    try {
      final url = await _service.uploadAvatar(user.id, file);
      if (url != null) {
        final updated = await _service.updateProfile(user.id, {'avatar_url': url});
        state = AsyncValue.data(updated);
      } else {
        // If upload returns null, just reload profile
        await loadProfile(user.id);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Public provider for profile state
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileNotifier(ref, service);
});
