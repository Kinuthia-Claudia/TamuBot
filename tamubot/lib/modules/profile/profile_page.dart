// lib/modules/profile/profile_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';
import 'package:tamubot/providers/profile_provider.dart';

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

  void _startEditing(ProfileModel profile) {
    setState(() {
      _isEditing = true;
      _usernameCtl.text = profile.username ?? '';
      _bioCtl.text = profile.bio ?? '';
      _prefs = List<String>.from(profile.dietaryPreferences);
      _pickedAvatar = null;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      maxHeight: 900,
    );
    if (result == null) return;

    setState(() => _pickedAvatar = File(result.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final changes = {
        'username': _usernameCtl.text.isEmpty ? null : _usernameCtl.text.trim(),
        'bio': _bioCtl.text.isEmpty ? null : _bioCtl.text.trim(),
        'dietary_preferences': _prefs,
      };

      await ref.read(profileProvider.notifier).updatePartial(changes);

      if (_pickedAvatar != null) {
        await ref.read(profileProvider.notifier).uploadAvatar(_pickedAvatar!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          profileAsync.when(
            data: (p) => (p != null && !_isEditing)
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _startEditing(p),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return _buildNoProfile();
          }

          return _buildProfileView(profile);
        },
      ),
    );
  }

  Widget _buildNoProfile() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("No profile found"),
          const SizedBox(height: 12),
          ElevatedButton(
            child: const Text("Retry"),
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                ref.read(profileProvider.notifier).load(user.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(ProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickAvatar : null,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _pickedAvatar != null
                  ? FileImage(_pickedAvatar!)
                  : (profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null),
              child: (_pickedAvatar == null && profile.avatarUrl == null)
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          // ---------------------------
          // VIEW vs EDIT USERNAME/BIO
          // ---------------------------
          if (!_isEditing) ...[
            Text(
              profile.username ?? "No username",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(profile.email ?? "-", style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(profile.bio ?? "No bio"),
          ] else ...[
            TextField(
              controller: _usernameCtl,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioCtl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Bio"),
            ),
          ],

          const SizedBox(height: 24),

          _buildPreferencesSection(),

          const SizedBox(height: 30),

          // -----------------------------
          // ACTION BUTTONS
          // -----------------------------
          if (_isEditing) _buildEditingButtons() else _buildViewButtons(),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dietary preferences",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
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
                          selected ? _prefs.add(option) : _prefs.remove(option);
                        });
                      }
                    : null,
              ),
            if (_isEditing)
              ActionChip(
                label: const Text("Add custom"),
                onPressed: () async {
                  final custom = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final ctl = TextEditingController();
                      return AlertDialog(
                        title: const Text("Add dietary preference"),
                        content: TextField(
                          controller: ctl,
                          decoration: const InputDecoration(
                            hintText: "e.g. no garlic",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, ctl.text.trim()),
                            child: const Text("Add"),
                          )
                        ],
                      );
                    },
                  );
                  if (custom != null && custom.isNotEmpty) {
                    setState(() => _prefs.add(custom));
                  }
                },
              )
            else if (_prefs.isEmpty)
              const Text("No dietary preferences set."),
          ],
        ),
      ],
    );
  }

  Widget _buildEditingButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator())
                : const Text("Save"),
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
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  Widget _buildViewButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final profile = ref.read(profileProvider).value;
            if (profile != null) _startEditing(profile);
          },
          child: const Text("Edit profile"),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text("Log out"),
        ),
      ],
    );
  }
}
