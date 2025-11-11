import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _timerKey = 'default_timer';
  static const _vibrationKey = 'vibration_enabled';
  static const _dailyInspirationKey = 'daily_inspiration';
  static const _weeklySummaryKey = 'weekly_summary';
  static const _analyticsKey = 'analytics_enabled';

  // Load all settings
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'defaultTimer': prefs.getInt(_timerKey) ?? 10,
      'vibrationEnabled': prefs.getBool(_vibrationKey) ?? true,
      'dailyInspiration': prefs.getBool(_dailyInspirationKey) ?? true,
      'weeklySummary': prefs.getBool(_weeklySummaryKey) ?? false,
      'analyticsEnabled': prefs.getBool(_analyticsKey) ?? true,
    };
  }

  // Individual setters
  Future<void> setDefaultTimer(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerKey, minutes);
  }

  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  Future<void> setDailyInspiration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyInspirationKey, value);
  }

  Future<void> setWeeklySummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklySummaryKey, value);
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, value);
  }

  // Clear all settings
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
