import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../core/engine/lorentz_engine.dart';
import '../core/utils/database_factory.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  final DatabaseHelperInterface _db = DatabaseFactory.create();

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    _settings = await _db.getSettings();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _db.saveSettings(settings);
    notifyListeners();
  }

  Future<void> acceptPrivacy() async {
    _settings = _settings.copyWith(privacyAccepted: true);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _settings = _settings.copyWith(enableNotifications: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleSoundEffects(bool value) async {
    _settings = _settings.copyWith(enableSoundEffects: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleWhiteNoise(bool value) async {
    _settings = _settings.copyWith(enableWhiteNoise: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleScreenMonitoring(bool value) async {
    _settings = _settings.copyWith(enableScreenMonitoring: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleCameraMonitoring(bool value) async {
    _settings = _settings.copyWith(enableCameraMonitoring: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleMicrophoneMonitoring(bool value) async {
    _settings = _settings.copyWith(enableMicrophoneMonitoring: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleMotionMonitoring(bool value) async {
    _settings = _settings.copyWith(enableMotionMonitoring: value);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDefaultV0(double v0) async {
    _settings = _settings.copyWith(defaultV0: v0);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDefaultC(double c) async {
    _settings = _settings.copyWith(defaultC: c);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setDefaultFlowMode(FlowMode mode) async {
    _settings = _settings.copyWith(defaultFlowMode: mode);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setPomodoroDuration(int minutes) async {
    _settings = _settings.copyWith(pomodoroDuration: minutes);
    await _db.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();
    _settings = AppSettings();
    notifyListeners();
  }
}
