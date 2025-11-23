// lib/providers/settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tamubot/modules/authentication/auth_controller.dart';
import 'package:tamubot/services/settings_service.dart' as settings_service;

/// ------------------------------------------------------
/// Service Provider
/// ------------------------------------------------------

final settingsServiceProvider =
    Provider<settings_service.SettingsService>((ref) {
  return settings_service.SettingsService();
});

/// ------------------------------------------------------
/// Settings State
/// ------------------------------------------------------

class SettingsState {
  final int defaultTimer;
  final bool vibrationEnabled;
  final bool dailyInspiration;
  final bool weeklySummary;
  final bool analyticsEnabled;

  /// Currently authenticated user these settings belong to
  final String? currentUserId;

  const SettingsState({
    required this.defaultTimer,
    required this.vibrationEnabled,
    required this.dailyInspiration,
    required this.weeklySummary,
    required this.analyticsEnabled,
    this.currentUserId,
  });

  SettingsState copyWith({
    int? defaultTimer,
    bool? vibrationEnabled,
    bool? dailyInspiration,
    bool? weeklySummary,
    bool? analyticsEnabled,
    String? currentUserId,
  }) {
    return SettingsState(
      defaultTimer: defaultTimer ?? this.defaultTimer,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyInspiration: dailyInspiration ?? this.dailyInspiration,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

/// Default settings used for guests and after logout
const _defaultSettings = SettingsState(
  defaultTimer: 10,
  vibrationEnabled: true,
  dailyInspiration: true,
  weeklySummary: false,
  analyticsEnabled: true,
  currentUserId: null,
);

/// ------------------------------------------------------
/// Settings Provider (session-aware)
/// ------------------------------------------------------

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  final auth = ref.watch(authControllerProvider);

  final notifier = SettingsNotifier(service);

  /// User logged in
  if (auth.isAuthenticated && auth.user != null) {
    final userId = auth.user!.id;

    // Only reload if user changed
    if (notifier.state.currentUserId != userId) {
      notifier.loadSettingsForUser(userId);
    }
  }

  /// User logged out → reset settings
  else {
    notifier.resetToDefaults();
  }

  return notifier;
});

/// ------------------------------------------------------
/// Settings Notifier
/// ------------------------------------------------------

class SettingsNotifier extends StateNotifier<SettingsState> {
  final settings_service.SettingsService _service;

  SettingsNotifier(this._service) : super(_defaultSettings);

  /// Loads saved settings from Supabase
  Future<void> loadSettingsForUser(String userId) async {
    try {
      final loaded = await _service.loadSettings(userId: userId);

      state = SettingsState(
        defaultTimer: loaded.defaultTimer,
        vibrationEnabled: loaded.vibrationEnabled,
        dailyInspiration: loaded.dailyInspiration,
        weeklySummary: loaded.weeklySummary,
        analyticsEnabled: loaded.analyticsEnabled,
        currentUserId: userId,
      );
    } catch (e) {
      // Fallback to defaults but keep the user ID
      state = _defaultSettings.copyWith(currentUserId: userId);
      print("⚠️ Error loading settings: $e");
    }
  }

  /// Reset to defaults when user signs out
  void resetToDefaults() {
    state = _defaultSettings;
  }

  /// ------------------------------------------------------
  /// Update Settings
  /// ------------------------------------------------------

  void setDefaultTimer(int minutes) {
    state = state.copyWith(defaultTimer: minutes);

    if (state.currentUserId != null) {
      _service.setDefaultTimer(minutes, userId: state.currentUserId!);
    }
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibrationEnabled: value);

    if (state.currentUserId != null) {
      _service.setVibrationEnabled(value, userId: state.currentUserId!);
    }
  }

  void toggleDailyInspiration(bool value) {
    state = state.copyWith(dailyInspiration: value);

    if (state.currentUserId != null) {
      _service.setDailyInspiration(value, userId: state.currentUserId!);
    }
  }

  void toggleWeeklySummary(bool value) {
    state = state.copyWith(weeklySummary: value);

    if (state.currentUserId != null) {
      _service.setWeeklySummary(value, userId: state.currentUserId!);
    }
  }

  void toggleAnalytics(bool value) {
    state = state.copyWith(analyticsEnabled: value);

    if (state.currentUserId != null) {
      _service.setAnalyticsEnabled(value, userId: state.currentUserId!);
    }
  }

  /// ------------------------------------------------------
  /// Clear settings from database
  /// ------------------------------------------------------

  Future<void> clearSettings() async {
    final userId = state.currentUserId;
    if (userId == null) return;

    await _service.clearAll(userId: userId);
    await loadSettingsForUser(userId);
  }
}
