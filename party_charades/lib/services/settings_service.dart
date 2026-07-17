import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _roundLengthKey = 'round_length';

  static const int defaultRoundLength = 60;

  static Future<int> getRoundLength() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_roundLengthKey) ?? defaultRoundLength;
  }

  static Future<void> setRoundLength(int seconds) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_roundLengthKey, seconds);
  }
}
