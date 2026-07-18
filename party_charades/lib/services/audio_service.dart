import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/services/settings_service.dart';

class AudioService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playCorrect() async {
    playHapticCorrect();
    if (!await SettingsService.getAudio()) return;

    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/correct.mp3'));
  }

  Future<void> playWrong() async {
    playHapticWrong();
    if (!await SettingsService.getAudio()) return;

    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/wrong.mp3'));

    HapticFeedback.heavyImpact();
  }

  Future<void> playHapticCorrect() async {
    if (!await SettingsService.getHaptic()) return;

    HapticFeedback.mediumImpact();
  }

  Future<void> playHapticWrong() async {
    if (!await SettingsService.getHaptic()) return;

    HapticFeedback.heavyImpact();
  }
}
