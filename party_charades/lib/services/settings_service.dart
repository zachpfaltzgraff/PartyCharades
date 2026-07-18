import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _roundLengthKey = 'round_length';
  static const _audioKey = 'audio';
  static const _hapticKey = 'haptic';

  static const int defaultRoundLength = 60;
  static const bool defaultAudio = true;
  static const bool defaultHaptic = true;

  static Future<int> getRoundLength() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_roundLengthKey) ?? defaultRoundLength;
  }

  static Future<void> setRoundLength(int seconds) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_roundLengthKey, seconds);
  }

  static Future<bool> getAudio() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_audioKey) ?? defaultAudio;
  }

  static Future<void> setAudio(bool audio) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_audioKey, audio);
  }

  static Future<bool> getHaptic() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_hapticKey) ?? defaultHaptic;
  }

  static Future<void> setHaptic(bool audio) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_hapticKey, audio);
  }
}
