import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_haptics.dart';
import '../services/local_storage_service.dart';
import 'auth_provider.dart';

class SettingsState {
  const SettingsState({
    this.darkMode = false,
    this.soundOn = true,
    this.vibrationOn = true,
    this.animationsOn = true,
    this.notificationsOn = true,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.language = 'QAZ',
  });

  final bool darkMode;
  final bool soundOn;
  final bool vibrationOn;
  final bool animationsOn;
  final bool notificationsOn;
  final int reminderHour;
  final int reminderMinute;

  /// 'QAZ' немесе 'RUS' (бірінші нұсқада тек QAZ белсенді).
  final String language;

  SettingsState copyWith({
    bool? darkMode,
    bool? soundOn,
    bool? vibrationOn,
    bool? animationsOn,
    bool? notificationsOn,
    int? reminderHour,
    int? reminderMinute,
    String? language,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      soundOn: soundOn ?? this.soundOn,
      vibrationOn: vibrationOn ?? this.vibrationOn,
      animationsOn: animationsOn ?? this.animationsOn,
      notificationsOn: notificationsOn ?? this.notificationsOn,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      language: language ?? this.language,
    );
  }
}

/// Баптаулар — SharedPreferences-те сақталады.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _load();
  }

  final LocalStorageService _storage;

  void _load() {
    final p = _storage.prefs;
    state = SettingsState(
      darkMode: p.getBool('set_dark') ?? false,
      soundOn: p.getBool('set_sound') ?? true,
      vibrationOn: p.getBool('set_vibration') ?? true,
      animationsOn: p.getBool('set_animations') ?? true,
      notificationsOn: p.getBool('set_notifications') ?? true,
      reminderHour: p.getInt('set_reminder_hour') ?? 18,
      reminderMinute: p.getInt('set_reminder_minute') ?? 0,
      language: p.getString('set_language') ?? 'QAZ',
    );
    AppHaptics.enabled = state.vibrationOn;
  }

  Future<void> _save() async {
    final p = _storage.prefs;
    await p.setBool('set_dark', state.darkMode);
    await p.setBool('set_sound', state.soundOn);
    await p.setBool('set_vibration', state.vibrationOn);
    await p.setBool('set_animations', state.animationsOn);
    await p.setBool('set_notifications', state.notificationsOn);
    await p.setInt('set_reminder_hour', state.reminderHour);
    await p.setInt('set_reminder_minute', state.reminderMinute);
    await p.setString('set_language', state.language);
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _save();
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundOn: value);
    await _save();
  }

  Future<void> toggleVibration(bool value) async {
    state = state.copyWith(vibrationOn: value);
    AppHaptics.enabled = value;
    await _save();
  }

  Future<void> toggleAnimations(bool value) async {
    state = state.copyWith(animationsOn: value);
    await _save();
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsOn: value);
    await _save();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
    await _save();
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _save();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.watch(storageProvider)),
);
