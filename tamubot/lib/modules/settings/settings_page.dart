import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(),
);

/// 🧩 SETTINGS STATE
class SettingsState {
  final int defaultTimer;
  final bool vibrateOnTimerEnd;
  final bool dailyInspiration;
  final bool weeklySummary;
  final bool analyticsOptIn;

  const SettingsState({
    required this.defaultTimer,
    required this.vibrateOnTimerEnd,
    required this.dailyInspiration,
    required this.weeklySummary,
    required this.analyticsOptIn,
  });

  SettingsState copyWith({
    int? defaultTimer,
    bool? vibrateOnTimerEnd,
    bool? dailyInspiration,
    bool? weeklySummary,
    bool? analyticsOptIn,
  }) {
    return SettingsState(
      defaultTimer: defaultTimer ?? this.defaultTimer,
      vibrateOnTimerEnd: vibrateOnTimerEnd ?? this.vibrateOnTimerEnd,
      dailyInspiration: dailyInspiration ?? this.dailyInspiration,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultTimer': defaultTimer,
        'vibrateOnTimerEnd': vibrateOnTimerEnd,
        'dailyInspiration': dailyInspiration,
        'weeklySummary': weeklySummary,
        'analyticsOptIn': analyticsOptIn,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) => SettingsState(
        defaultTimer: json['defaultTimer'] ?? 10,
        vibrateOnTimerEnd: json['vibrateOnTimerEnd'] ?? true,
        dailyInspiration: json['dailyInspiration'] ?? true,
        weeklySummary: json['weeklySummary'] ?? false,
        analyticsOptIn: json['analyticsOptIn'] ?? true,
      );
}

/// 🧭 CONTROLLER
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController()
      : super(const SettingsState(
          defaultTimer: 10,
          vibrateOnTimerEnd: true,
          dailyInspiration: true,
          weeklySummary: false,
          analyticsOptIn: true,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('settings');
    if (jsonString != null) {
      final data = jsonDecode(jsonString);
      state = SettingsState.fromJson(data);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', jsonEncode(state.toJson()));
  }

  void updateTimer(int minutes) {
    state = state.copyWith(defaultTimer: minutes);
    _saveSettings();
  }

  void toggleVibrate(bool value) {
    state = state.copyWith(vibrateOnTimerEnd: value);
    _saveSettings();
  }

  void toggleDailyInspiration(bool value) {
    state = state.copyWith(dailyInspiration: value);
    _saveSettings();
  }

  void toggleWeeklySummary(bool value) {
    state = state.copyWith(weeklySummary: value);
    _saveSettings();
  }

  void toggleAnalyticsOptIn(bool value) {
    state = state.copyWith(analyticsOptIn: value);
    _saveSettings();
  }

  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const SettingsState(
      defaultTimer: 10,
      vibrateOnTimerEnd: true,
      dailyInspiration: true,
      weeklySummary: false,
      analyticsOptIn: true,
    );
  }

  /// 🚨 Delete account via Supabase Edge Function
  Future<String?> deleteAccount() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) return "No user logged in";

      const functionUrl =
          'https://gnkvcfoatmbpuoonyxeu.supabase.co/functions/v1/delete-user'; // 🔧 Replace with your real function URL

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${client.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({'user_id': user.id}),
      );

      if (response.statusCode == 200) {
        await client.auth.signOut();
        await clearLocalData();
        return null; // success
      } else {
        final msg = response.body.isNotEmpty ? response.body : 'Unknown error';
        return "Failed to delete account: $msg";
      }
    } catch (e) {
      return e.toString();
    }
  }
}

/// 🧱 SETTINGS PAGE UI
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.brown,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: "Timers"),
          ListTile(
            title: const Text("Default Timer Duration"),
            subtitle: Text("${settings.defaultTimer} minutes"),
            trailing: DropdownButton<int>(
              value: settings.defaultTimer,
              items: [5, 10, 15, 20, 30]
                  .map((v) => DropdownMenuItem(value: v, child: Text("$v min")))
                  .toList(),
              onChanged: (val) {
                if (val != null) controller.updateTimer(val);
              },
            ),
          ),
          SwitchListTile(
            title: const Text("Vibrate when timer ends"),
            value: settings.vibrateOnTimerEnd,
            onChanged: controller.toggleVibrate,
          ),

          const _SectionHeader(title: "Notifications"),
          SwitchListTile(
            title: const Text("Daily cooking inspiration"),
            value: settings.dailyInspiration,
            onChanged: controller.toggleDailyInspiration,
          ),
          SwitchListTile(
            title: const Text("Weekly grocery summary"),
            value: settings.weeklySummary,
            onChanged: controller.toggleWeeklySummary,
          ),

          const _SectionHeader(title: "Privacy & Data"),
          SwitchListTile(
            title: const Text("Analytics opt-in"),
            value: settings.analyticsOptIn,
            onChanged: controller.toggleAnalyticsOptIn,
          ),
          ListTile(
            title: const Text("Clear local data"),
            trailing: const Icon(Icons.cleaning_services_outlined),
            onTap: () async {
              final confirm = await _confirmDialog(context,
                  "Are you sure you want to clear local data?");
              if (confirm) {
                await controller.clearLocalData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Local data cleared")),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text("Delete account"),
            textColor: Colors.red,
            trailing: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () async {
              final confirm = await _confirmDialog(
                  context, "This will permanently delete your account.");
              if (confirm) {
                final msg = await controller.deleteAccount();
                if (msg == null && context.mounted) {
                  // ✅ Navigate to login screen
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg ?? 'Error deleting account')),
                  );
                }
              }
            },
          ),

          const _SectionHeader(title: "About"),
          ListTile(
            title: const Text("App Version"),
            subtitle: const Text("1.0.0"),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text("Developed by"),
            subtitle: const Text("Kinuthia Claudia"),
            leading: const Icon(Icons.code),
          ),
          ListTile(
            title: const Text("Contact Support"),
            subtitle: const Text("support@tamubot.com"),
            leading: const Icon(Icons.email_outlined),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// 🪶 Simple section title widget
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 16)),
    );
  }
}
