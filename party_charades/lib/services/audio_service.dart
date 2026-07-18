import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playCorrect() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/correct.mp3'));

    HapticFeedback.mediumImpact();
  }

  Future<void> playWrong() async {
    await audioPlayer.stop();
    await audioPlayer.play(AssetSource('sounds/wrong.mp3'));

    HapticFeedback.heavyImpact();
  }
}
