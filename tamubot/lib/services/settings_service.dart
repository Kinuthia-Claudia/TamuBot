// lib/modules/settings/settings_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------
/// Strongly Typed Settings Model
/// ------------------------------------------------------

class SettingsData {
  final int defaultTimer;
  final bool vibrationEnabled;
  final bool dailyInspiration;
  final bool weeklySummary;
  final bool analyticsEnabled;

  const SettingsData({
    required this.defaultTimer,
    required this.vibrationEnabled,
    required this.dailyInspiration,
    required this.weeklySummary,
    required this.analyticsEnabled,
  });

  factory SettingsData.defaultValues() => const SettingsData(
        defaultTimer: 10,
        vibrationEnabled: true,
        dailyInspiration: true,
        weeklySummary: false,
        analyticsEnabled: true,
      );

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      defaultTimer: json['defaultTimer'] ?? 10,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      dailyInspiration: json['dailyInspiration'] ?? true,
      weeklySummary: json['weeklySummary'] ?? false,
      analyticsEnabled: json['analyticsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultTimer': defaultTimer,
        'vibrationEnabled': vibrationEnabled,
        'dailyInspiration': dailyInspiration,
        'weeklySummary': weeklySummary,
        'analyticsEnabled': analyticsEnabled,
      };

  SettingsData copyWith({
    int? defaultTimer,
    bool? vibrationEnabled,
    bool? dailyInspiration,
    bool? weeklySummary,
    bool? analyticsEnabled,
  }) {
    return SettingsData(
      defaultTimer: defaultTimer ?? this.defaultTimer,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyInspiration: dailyInspiration ?? this.dailyInspiration,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

/// ------------------------------------------------------
/// Settings Service (SharedPreferences Backend)
/// ------------------------------------------------------

class SettingsService {
  /// Key format: "settings_{userId}"
  String _getSettingsKey(String? userId) {
    return userId != null ? 'settings_$userId' : 'settings_global';
  }

  /// ------------------------------------------------------
  /// Load Settings
  /// ------------------------------------------------------

  Future<SettingsData> loadSettings({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSettingsKey(userId);

    final raw = prefs.getString(key);
    if (raw == null) return SettingsData.defaultValues();

    try {
      final decoded = jsonDecode(raw);
      return SettingsData.fromJson(decoded);
    } catch (e) {
      print("⚠️ Corrupted settings JSON for $key — resetting. Error: $e");
      return SettingsData.defaultValues();
    }
  }

  /// Save settings atomically
  Future<void> saveSettings(SettingsData data, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSettingsKey(userId);
    await prefs.setString(key, jsonEncode(data.toJson()));
  }

  /// ------------------------------------------------------
  /// Helper for any "setX" modification
  /// ------------------------------------------------------

  Future<void> _update(
    String? userId, 
    SettingsData Function(SettingsData current) updateFn,
  ) async {
    final current = await loadSettings(userId: userId);
    final updated = updateFn(current);
    await saveSettings(updated, userId: userId);
  }

  /// ------------------------------------------------------
  /// Individual setting operations
  /// ------------------------------------------------------

  Future<void> setDefaultTimer(int minutes, {String? userId}) async {
    await _update(userId, (current) => current.copyWith(defaultTimer: minutes));
  }

  Future<void> setVibrationEnabled(bool value, {String? userId}) async {
    await _update(userId, (current) => current.copyWith(vibrationEnabled: value));
  }

  Future<void> setDailyInspiration(bool value, {String? userId}) async {
    await _update(userId, (current) => current.copyWith(dailyInspiration: value));
  }

  Future<void> setWeeklySummary(bool value, {String? userId}) async {
    await _update(userId, (current) => current.copyWith(weeklySummary: value));
  }

  Future<void> setAnalyticsEnabled(bool value, {String? userId}) async {
    await _update(userId, (current) => current.copyWith(analyticsEnabled: value));
  }

  /// ------------------------------------------------------
  /// Clear All for This User
  /// ------------------------------------------------------

  Future<void> clearAll({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSettingsKey(userId);
    await prefs.remove(key);
  }
}
