import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/models/answer.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_recap_page.dart';
import 'package:party_charades/services/audio_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GamePage extends StatefulWidget {
  final Deck deck;
  final int roundLength;

  const GamePage({super.key, required this.deck, required this.roundLength});

  @override
  State<GamePage> createState() => _GamePageState();
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

  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  bool canAnswer = true;

  bool get showingSwipeHint => dragX.abs() > 80;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    words = List<String>.from(widget.deck.words)..shuffle();

    timeRemaining = widget.roundLength;

    _startTimer();
    _startTiltDetection();
  }

  @override
  void dispose() {
    timer?.cancel();
    urgencyTimer?.cancel();
    accelerometerSubscription?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _startTiltDetection() {
    accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!canAnswer) return;

      /*
        Device held landscape right:
        
        X axis:
        - positive = tilted one direction
        - negative = tilted opposite direction

        Y axis:
        - positive = top going down
        - negative = lifting up
      */

      // Phone tilted upward = correct
      if (event.y < -6) {
        _answer(true);
      } else if (event.y > 6) {
        _answer(false);
      }
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (timeRemaining <= 1) {
        t.cancel();
        urgencyTimer?.cancel();
        _finishGame();
        return;
      }

      setState(() {
        timeRemaining--;
      });

      _handleUrgency();
    });
  }

  void _handleUrgency() {
    if (timeRemaining > 10) {
      return;
    }

    urgencyTimer?.cancel();

    int interval;

    if (timeRemaining <= 3) {
      interval = 150;
    } else if (timeRemaining <= 6) {
      interval = 350;
    } else {
      interval = 700;
    }

    urgencyTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      HapticFeedback.lightImpact();
    });
  }

  void _finishGame() {
    timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameRecapPage(
          answers: answers,
          deckName: widget.deck.name,
          deck: widget.deck,
          roundLength: widget.roundLength,
        ),
      ),
    );
  }

  void _answer(bool wasCorrect) {
    if (!canAnswer) return;

    canAnswer = false;

    if (wasCorrect) {
      HapticFeedback.mediumImpact();
      AudioService().playCorrect();
    } else {
      HapticFeedback.heavyImpact();
      AudioService().playWrong();
    }

    answers.add(Answer(correct: wasCorrect, word: currentWord));

    _nextWord();

    Future.delayed(const Duration(milliseconds: 600), () {
      canAnswer = true;
    });
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
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (showingSwipeHint)
                              Positioned(
                                top: 40,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dragX > 0
                                          ? Colors.green.withOpacity(.85)
                                          : Colors.red.withOpacity(.85),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      dragX > 0 ? "✓ CORRECT" : "✕ PASS",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                if (!canAnswer) return;

                                setState(() {
                                  dragX += details.delta.dx;
                                });
                              },

                              onHorizontalDragEnd: (_) {
                                if (!canAnswer) return;

                                if (dragX.abs() > 120) {
                                  final correct = dragX > 0;

                                  setState(() {
                                    isAnimating = true;

                                    // fling card completely off screen
                                    dragX = correct
                                        ? MediaQuery.of(context).size.width *
                                              1.5
                                        : -MediaQuery.of(context).size.width *
                                              1.5;
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

                                transform: Matrix4.identity()
                                  ..translate(dragX)
                                  ..rotateZ(dragX / 700),

                                child: _wordCard(currentWord),
                              ),
                            ),
                          ],
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
            color: Colors.black.withValues(alpha: .25),
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
