import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/services/audio_service.dart';

class GamePage extends StatefulWidget {
  final Deck deck;
  final int roundLength;

  const GamePage({super.key, required this.deck, required this.roundLength});

  @override
  State<GamePage> createState() => _GamePageState();
}

class Answer {
  bool correct;
  String word;

  Answer({required this.correct, required this.word});
}

class _GamePageState extends State<GamePage> {
  late List<String> words;

  late int timeRemaining;
  Timer? timer;

  int currentIndex = 0;
  final List<Answer> answers = [];
  int get correct => answers.where((answer) => answer.correct).length;
  int get passed => answers.where((answer) => !answer.correct).length;

  double dragX = 0;
  bool isAnimating = false;

  Timer? urgencyTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    words = List<String>.from(widget.deck.words)..shuffle();

    timeRemaining = widget.roundLength;

    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (timeRemaining <= 1) {
        t.cancel();
        _finishGame();
        return;
      }

      setState(() {
        timeRemaining--;
      });
    });
  }

  void _finishGame() {
    timer?.cancel();

    // Results page comes in Part 2
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Time's Up!"),
        content: Text("Correct: $correct \nPassed: $passed"),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _answer(bool wasCorrect) {
    if (wasCorrect) {
      AudioService().playCorrect();
    } else {
      AudioService().playWrong();
    }

    answers.add(
      Answer(
        correct: wasCorrect,
        word: currentWord,
      ),
    );

    _nextWord();
  }

  void _nextWord() {
    currentIndex++;

    if (currentIndex >= words.length) {
      words.shuffle();
      currentIndex = 0;
    }

    setState(() {});
  }

  String get currentWord => words[currentIndex];

  String get timerText {
    final minutes = (timeRemaining ~/ 60).toString().padLeft(2, '0');

    final seconds = (timeRemaining % 60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.secondary, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              children: [
                Text(
                  timerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Next card underneath
                        Transform.scale(
                          scale: .92,
                          child: _wordCard(
                            words[(currentIndex + 1) % words.length],
                          ),
                        ),

                        // Current draggable card
                        GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              dragX += details.delta.dx;
                            });
                          },

                          onHorizontalDragEnd: (_) {
                            if (dragX.abs() > 120) {
                              final correct = dragX > 0;

                              setState(() {
                                isAnimating = true;

                                // fling card completely off screen
                                dragX = correct
                                    ? MediaQuery.of(context).size.width * 1.5
                                    : -MediaQuery.of(context).size.width * 1.5;
                              });

                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  _answer(correct);

                                  setState(() {
                                    dragX = 0;
                                    isAnimating = false;
                                  });
                                },
                              );
                            } else {
                              setState(() {
                                isAnimating = true;
                                dragX = 0;
                              });

                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  setState(() {
                                    isAnimating = false;
                                  });
                                },
                              );
                            }
                          },

                          child: AnimatedContainer(
                            duration: isAnimating
                                ? const Duration(milliseconds: 250)
                                : Duration.zero,

                            transform: Matrix4.translationValues(dragX, 0, 0),

                            child: _wordCard(currentWord),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordCard(String word) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(.25),
          ),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                word,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "← Pass",
                style: TextStyle(fontSize: 22, color: Colors.black54),
              ),

              Text(
                "Correct →",
                style: TextStyle(fontSize: 22, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
