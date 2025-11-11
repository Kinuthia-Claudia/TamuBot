import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tamubot/modules/settings/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

class SettingsState {
  final int defaultTimer;
  final bool vibrationEnabled;
  final bool dailyInspiration;
  final bool weeklySummary;
  final bool analyticsEnabled;

  SettingsState({
    required this.defaultTimer,
    required this.vibrationEnabled,
    required this.dailyInspiration,
    required this.weeklySummary,
    required this.analyticsEnabled,
  });

  SettingsState copyWith({
    int? defaultTimer,
    bool? vibrationEnabled,
    bool? dailyInspiration,
    bool? weeklySummary,
    bool? analyticsEnabled,
  }) {
    return SettingsState(
      defaultTimer: defaultTimer ?? this.defaultTimer,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyInspiration: dailyInspiration ?? this.dailyInspiration,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;

  SettingsNotifier(this._service)
      : super(SettingsState(
          defaultTimer: 10,
          vibrationEnabled: true,
          dailyInspiration: true,
          weeklySummary: false,
          analyticsEnabled: true,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await _service.loadSettings();
    state = SettingsState(
      defaultTimer: data['defaultTimer'],
      vibrationEnabled: data['vibrationEnabled'],
      dailyInspiration: data['dailyInspiration'],
      weeklySummary: data['weeklySummary'],
      analyticsEnabled: data['analyticsEnabled'],
    );
  }

  void setDefaultTimer(int minutes) {
    state = state.copyWith(defaultTimer: minutes);
    _service.setDefaultTimer(minutes);
  }

  void toggleVibration(bool value) {
    state = state.copyWith(vibrationEnabled: value);
    _service.setVibrationEnabled(value);
  }

  void toggleDailyInspiration(bool value) {
    state = state.copyWith(dailyInspiration: value);
    _service.setDailyInspiration(value);
  }

  void toggleWeeklySummary(bool value) {
    state = state.copyWith(weeklySummary: value);
    _service.setWeeklySummary(value);
  }

  void toggleAnalytics(bool value) {
    state = state.copyWith(analyticsEnabled: value);
    _service.setAnalyticsEnabled(value);
  }

  Future<void> clearSettings() async {
    await _service.clearAll();
    _loadSettings();
  }
}
