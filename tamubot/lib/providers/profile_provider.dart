// lib/providers/profile_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/authentication/auth_controller.dart';

import 'package:tamubot/modules/profile/profile_service.dart';
import 'package:tamubot/modules/profile/profile_model.dart';

/// Profile service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Profile Notifier
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final Ref ref;
  final ProfileService service;

  ProfileNotifier(this.ref, this.service)
      : super(const AsyncValue.data(null));

  // -----------------------------------
  // CLEAR PROFILE (on logout)
  // -----------------------------------
  void clear() {
    state = const AsyncValue.data(null);
  }

  // -----------------------------------
  // LOAD PROFILE
  // -----------------------------------
  Future<void> load(String userId) async {
    state = const AsyncValue.loading();

    try {
      final profile = await service.fetchProfile(userId);

      if (profile != null) {
        state = AsyncValue.data(profile);
        return;
      }

      // Create default row if missing
      final user = Supabase.instance.client.auth.currentUser;

      final defaultProfile = ProfileModel(
        id: userId,
        username: null,
        email: user?.email,
        bio: null,
        avatarUrl: null,
        dietaryPreferences: const [],
      );

      await service.createProfileIfNotExists(defaultProfile);
      state = AsyncValue.data(defaultProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // -----------------------------------
  // UPDATE PARTIAL
  // -----------------------------------
  Future<void> updatePartial(Map<String, dynamic> changes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final updated = await service.updateProfile(user.id, changes);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // -----------------------------------
  // UPLOAD AVATAR
  // -----------------------------------
  Future<void> uploadAvatar(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();

    try {
      final url = await service.uploadAvatar(user.id, file);

      if (url != null) {
        final updated = await service.updateProfile(user.id, {
          'avatar_url': url,
        });

        state = AsyncValue.data(updated);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Profile provider that reacts to auth changes
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final service = ref.watch(profileServiceProvider);

  final notifier = ProfileNotifier(ref, service);

  if (!auth.isAuthenticated) {
    notifier.clear();
    return notifier;
  }

  if (auth.user != null) {
    notifier.load(auth.user!.id);
  }

  return notifier;
});