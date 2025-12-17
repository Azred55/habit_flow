import 'package:flutter/material.dart';
import 'package:habit_flow/features/settings/data/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> loadSettings() async {
    _themeMode = await _service.loadThemeMode();
    _notificationsEnabled = await _service.loadNotificationsEnabled();
    _reminderTime = await _service.loadReminderTime();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _service.updateThemeMode(mode);
  }

  Future<void> updateNotificationsEnabled(bool isEnabled) async {
    if (isEnabled == _notificationsEnabled) {
      return;
    }
    _notificationsEnabled = isEnabled;
    notifyListeners();
    await _service.updateNotificationsEnabled(isEnabled);
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    if (time == _reminderTime) {
      return;
    }
    _reminderTime = time;
    notifyListeners();
    await _service.updateReminderTime(time);
  }
}
