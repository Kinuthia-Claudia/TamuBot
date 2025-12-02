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
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
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
          Text(
            "No profile found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                ref.read(profileProvider.notifier).load(user.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
            ),
            child: const Text(
              "Retry",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(ProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickAvatar : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: _pickedAvatar != null
                        ? FileImage(_pickedAvatar!)
                        : (profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null),
                    child: (_pickedAvatar == null && profile.avatarUrl == null)
                        ? Icon(Icons.person, size: 50, color: Colors.green.shade600)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                if (!_isEditing) ...[
                  Text(
                    profile.username ?? "No username",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.email ?? "-",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.bio ?? "No bio",
                    style: TextStyle(
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  TextField(
                    controller: _usernameCtl,
                    decoration: InputDecoration(
                      labelText: "Username",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioCtl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // DIETARY PREFERENCES SECTION
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildPreferencesSection(),
          ),

          const SizedBox(height: 30),

          // ACTION BUTTONS
          if (_isEditing) _buildEditingButtons() else _buildViewButtons(),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dietary Preferences",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in kCommonDietaryOptions)
              FilterChip(
                label: Text(option),
                selected: _prefs.contains(option),
                selectedColor: Colors.green.shade200,
                checkmarkColor: Colors.green.shade800,
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
                label: Text(
                  "Add custom",
                  style: TextStyle(color: Colors.green.shade700),
                ),
                backgroundColor: Colors.green.shade50,
                onPressed: () async {
                  final custom = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final ctl = TextEditingController();
                      return AlertDialog(
                        backgroundColor: Colors.green.shade50,
                        title: Text(
                          "Add Dietary Preference",
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                        content: TextField(
                          controller: ctl,
                          decoration: InputDecoration(
                            hintText: "e.g. no garlic",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, ctl.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Add",
                              style: TextStyle(color: Colors.white),
                            ),
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
              Text(
                "No dietary preferences set.",
                style: TextStyle(color: Colors.green.shade700),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditingButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 55,
          child: OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _isEditing = false;
                      _pickedAvatar = null;
                    });
                  },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.green.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              final profile = ref.read(profileProvider).value;
              if (profile != null) _startEditing(profile);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
            ),
            child: const Text(
              "Edit Profile",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
          },
          icon: Icon(Icons.logout, color: Colors.green.shade700),
          label: Text(
            "Log out",
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}