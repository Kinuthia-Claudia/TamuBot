import 'dart:async';
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

///  SETTINGS STATE
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

/// CONTROLLER
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

  ///  Delete account via Supabase Edge Function
  Future<String?> deleteAccount() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) return "No user logged in";

      const functionUrl =
          'https://gnkvcfoatmbpuoonyxeu.supabase.co/functions/v1/delete-user';

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

///  SETTINGS PAGE UI
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: "Timers"),
          
          // Timer Card with Countdown
          _TimerCard(settings: settings, controller: controller),

          const _SectionHeader(title: "Notifications"),
          _SettingsCard(
            children: [
              SwitchListTile(
                title: Text(
                  "Daily cooking inspiration",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                value: settings.dailyInspiration,
                onChanged: controller.toggleDailyInspiration,
                activeColor: Colors.green.shade600,
              ),
              SwitchListTile(
                title: Text(
                  "Weekly grocery summary",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                value: settings.weeklySummary,
                onChanged: controller.toggleWeeklySummary,
                activeColor: Colors.green.shade600,
              ),
            ],
          ),

          const _SectionHeader(title: "Privacy & Data"),
          _SettingsCard(
            children: [
              SwitchListTile(
                title: Text(
                  "Analytics opt-in",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                value: settings.analyticsOptIn,
                onChanged: controller.toggleAnalyticsOptIn,
                activeColor: Colors.green.shade600,
              ),
              ListTile(
                title: Text(
                  "Clear local data",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                trailing: Icon(Icons.cleaning_services_outlined, color: Colors.green.shade600),
                onTap: () async {
                  final confirm = await _confirmDialog(context,
                      "Are you sure you want to clear local data?");
                  if (confirm) {
                    await controller.clearLocalData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Local data cleared"),
                          backgroundColor: Colors.green.shade600,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                title: const Text(
                  "Delete account",
                  style: TextStyle(color: Colors.red),
                ),
                trailing: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () async {
                  final confirm = await _confirmDialog(
                      context, "This will permanently delete your account.");
                  if (confirm) {
                    final msg = await controller.deleteAccount();
                    if (msg == null && context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (r) => false);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg ?? 'Error deleting account'),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const _SectionHeader(title: "About"),
          _SettingsCard(
            children: [
              ListTile(
                title: Text(
                  "App Version",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                subtitle: const Text("1.0.0"),
                leading: Icon(Icons.info_outline, color: Colors.green.shade600),
              ),
              ListTile(
                title: Text(
                  "Developed by",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                subtitle: const Text("Kinuthia Claudia"),
                leading: Icon(Icons.code, color: Colors.green.shade600),
              ),
              ListTile(
                title: Text(
                  "Contact Support",
                  style: TextStyle(color: Colors.green.shade800),
                ),
                subtitle: const Text("support@tamubot.com"),
                leading: Icon(Icons.email_outlined, color: Colors.green.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog(BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.green.shade50,
            title: Text(
              "Confirm",
              style: TextStyle(color: Colors.green.shade800),
            ),
            content: Text(
              message,
              style: TextStyle(color: Colors.green.shade700),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// 🕐 Timer Card with Countdown Display
class _TimerCard extends ConsumerStatefulWidget {
  final SettingsState settings;
  final SettingsController controller;

  const _TimerCard({
    required this.settings,
    required this.controller,
  });

  @override
  ConsumerState<_TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends ConsumerState<_TimerCard> {
  Duration _remainingTime = Duration.zero;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = Duration(minutes: widget.settings.defaultTimer);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else {
          _timerCompleted();
          timer.cancel();
        }
      });
    });
  }

  void _timerCompleted() {
    setState(() {
      _isRunning = false;
      _remainingTime = Duration.zero;
    });
    
    // Trigger vibration if enabled
    if (widget.settings.vibrateOnTimerEnd) {
      // You can add vibration logic here using HapticFeedback
      // HapticFeedback.vibrate();
    }
    
    // Show completion notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Timer completed!'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _remainingTime = Duration(minutes: widget.settings.defaultTimer);
    });
    _timer?.cancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        // Timer Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Text(
                _isRunning ? 'Timer Running' : 'Set Timer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),
              // Countdown Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRunning ? Colors.green.shade400 : Colors.green.shade300,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _formatDuration(_remainingTime),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isRunning ? Colors.green.shade700 : Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isRunning)
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'Start',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _stopTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.stop, color: Colors.white),
                      label: const Text(
                        'Stop',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: Icon(Icons.refresh, color: Colors.green.shade600),
                    label: Text(
                      'Reset',
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Timer Settings
        ListTile(
          title: Text(
            "Default Timer Duration",
            style: TextStyle(color: Colors.green.shade800),
          ),
          subtitle: Text(
            "${widget.settings.defaultTimer} minutes",
            style: TextStyle(color: Colors.green.shade700),
          ),
          trailing: DropdownButton<int>(
            value: widget.settings.defaultTimer,
            items: [5, 10, 15, 20, 30]
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        "$v min",
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                widget.controller.updateTimer(val);
                _resetTimer(); // Reset to new duration
              }
            },
          ),
        ),
        SwitchListTile(
          title: Text(
            "Vibrate when timer ends",
            style: TextStyle(color: Colors.green.shade800),
          ),
          value: widget.settings.vibrateOnTimerEnd,
          onChanged: widget.controller.toggleVibrate,
          activeColor: Colors.green.shade600,
        ),
      ],
    );
  }
}

/// 🪶 Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// 🎴 Settings Card Container
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        children: children,
      ),
    );
  }
}