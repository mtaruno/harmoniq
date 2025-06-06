import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  // Settings keys
  static const String _confidenceThresholdKey = 'confidence_threshold';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _audioInputDeviceKey = 'audio_input_device';
  static const String _showRomanNumeralsKey = 'show_roman_numerals';
  static const String _autoSaveSessionsKey = 'auto_save_sessions';

  // Default values
  double _confidenceThreshold = 0.7;
  bool _isDarkMode = false;
  String _audioInputDevice = 'default';
  bool _showRomanNumerals = true;
  bool _autoSaveSessions = true;

  // Getters
  double get confidenceThreshold => _confidenceThreshold;
  bool get isDarkMode => _isDarkMode;
  String get audioInputDevice => _audioInputDevice;
  bool get showRomanNumerals => _showRomanNumerals;
  bool get autoSaveSessions => _autoSaveSessions;

  // Load settings from SharedPreferences
  void _loadSettings() {
    _confidenceThreshold = _prefs.getDouble(_confidenceThresholdKey) ?? 0.7;
    _isDarkMode = _prefs.getBool(_isDarkModeKey) ?? false;
    _audioInputDevice = _prefs.getString(_audioInputDeviceKey) ?? 'default';
    _showRomanNumerals = _prefs.getBool(_showRomanNumeralsKey) ?? true;
    _autoSaveSessions = _prefs.getBool(_autoSaveSessionsKey) ?? true;
    notifyListeners();
  }

  // Setters with persistence
  Future<void> setConfidenceThreshold(double value) async {
    _confidenceThreshold = value.clamp(0.5, 0.95);
    await _prefs.setDouble(_confidenceThresholdKey, _confidenceThreshold);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool(_isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setAudioInputDevice(String device) async {
    _audioInputDevice = device;
    await _prefs.setString(_audioInputDeviceKey, _audioInputDevice);
    notifyListeners();
  }

  Future<void> setShowRomanNumerals(bool value) async {
    _showRomanNumerals = value;
    await _prefs.setBool(_showRomanNumeralsKey, _showRomanNumerals);
    notifyListeners();
  }

  Future<void> setAutoSaveSessions(bool value) async {
    _autoSaveSessions = value;
    await _prefs.setBool(_autoSaveSessionsKey, _autoSaveSessions);
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await setConfidenceThreshold(0.7);
    await setDarkMode(false);
    await setAudioInputDevice('default');
    await setShowRomanNumerals(true);
    await setAutoSaveSessions(true);
  }

  // Confidence threshold helpers
  String get confidenceThresholdLabel {
    if (_confidenceThreshold >= 0.9) return 'Very High';
    if (_confidenceThreshold >= 0.8) return 'High';
    if (_confidenceThreshold >= 0.7) return 'Medium';
    if (_confidenceThreshold >= 0.6) return 'Low';
    return 'Very Low';
  }

  Color get confidenceThresholdColor {
    if (_confidenceThreshold >= 0.8) return Colors.green;
    if (_confidenceThreshold >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
