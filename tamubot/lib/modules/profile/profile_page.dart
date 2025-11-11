// lib/modules/profile/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // add to pubspec if you want avatar upload
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';
import 'package:tamubot/providers/profile_provider.dart';

/// A simple set of common dietary options to show as chips.
const List<String> kCommonDietaryOptions = [
  'vegetarian',
  'vegan',
  'gluten-free',
  'dairy-free',
  'nut-free',
  'halal',
  'kosher',
  'low-sugar',
];

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _usernameCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  List<String> _prefs = [];
  bool _isEditing = false;
  bool _saving = false;
  File? _pickedAvatar;

  @override
  void dispose() {
    _usernameCtl.dispose();
    _bioCtl.dispose();
    super.dispose();
  }

  void _startEditing(ProfileModel? profile) {
    setState(() {
      _isEditing = true;
      _usernameCtl.text = profile?.username ?? '';
      _bioCtl.text = profile?.bio ?? '';
      _prefs = List.from(profile?.dietaryPreferences ?? []);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final changes = <String, dynamic>{};
    changes['username'] = _usernameCtl.text.isEmpty ? null : _usernameCtl.text;
    changes['bio'] = _bioCtl.text.isEmpty ? null : _bioCtl.text;
    changes['dietary_preferences'] = _prefs;
    try {
      await ref.read(profileProvider.notifier).updateProfilePartial(changes);

      if (_pickedAvatar != null) {
        // Optional avatar upload
        await ref.read(profileProvider.notifier).uploadAvatarAndSave(_pickedAvatar!);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (result == null) return;
    setState(() => _pickedAvatar = File(result.path));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          profileAsync.when(
            data: (p) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: p == null ? null : () => _startEditing(p),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading profile: $e')),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No profile found'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // trigger load (typically done automatically)
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        ref.read(profileProvider.notifier).loadProfile(user.id);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _isEditing ? _pickAvatar : null,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _pickedAvatar != null
                        ? FileImage(_pickedAvatar!)
                        : (profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) as ImageProvider : null),
                    child: (profile.avatarUrl == null && _pickedAvatar == null)
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Basic info
                if (!_isEditing) ...[
                  Text(
                    profile.username ?? 'No username',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(profile.email ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Text(profile.bio ?? 'No bio', style: Theme.of(context).textTheme.bodyMedium),
                ] else ...[
                  TextField(
                    controller: _usernameCtl,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtl,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 20),
                // Dietary preferences
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Dietary preferences', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in kCommonDietaryOptions)
                      FilterChip(
                        label: Text(option),
                        selected: _prefs.contains(option),
                        onSelected: _isEditing
                            ? (selected) {
                                setState(() {
                                  if (selected) {
                                    _prefs.add(option);
                                  } else {
                                    _prefs.remove(option);
                                  }
                                });
                              }
                            : null,
                      ),
                    // custom entry chip
                    if (_isEditing)
                      ActionChip(
                        label: const Text('Add custom'),
                        onPressed: () async {
                          final custom = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final ctl = TextEditingController();
                              return AlertDialog(
                                title: const Text('Add dietary preference'),
                                content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'e.g. no garlic')),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, ctl.text.trim()), child: const Text('Add')),
                                ],
                              );
                            },
                          );
                          if (custom != null && custom.isNotEmpty) {
                            setState(() => _prefs.add(custom));
                          }
                        },
                      )
                    else if (profile.dietaryPreferences.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No dietary preferences set.'),
                      )
                  ],
                ),
                const SizedBox(height: 24),
                // Save / Cancel / Logout area
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _isEditing = false;
                                  _pickedAvatar = null;
                                });
                              },
                        child: const Text('Cancel'),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      // Open edit
                      _startEditing(profile);
                    },
                    child: const Text('Edit profile'),
                  ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    // navigation after sign-out is handled by your auth listener/main routing
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
