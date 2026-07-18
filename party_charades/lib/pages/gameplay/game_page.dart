import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/models/answer.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_recap_page.dart';
import 'package:party_charades/services/audio_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Shared brand colors, kept consistent with the recap and ready screens.
const _kCorrectColor = Color(0xFF1FB874);
const _kPassedColor = Color(0xFFE84855);
const _kUrgentColor = Color(0xFFE53935);
const _kWarningColor = Color(0xFFFF8F00);
const _kNormalTimerColor = Color(0xFF241C3D);

class GamePage extends StatefulWidget {
  final Deck deck;
  final int roundLength;

  const GamePage({super.key, required this.deck, required this.roundLength});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
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

  // Visual pulse synced to the haptic urgency feedback in the final
  // seconds of the round. Purely cosmetic — does not affect timing logic.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    words = List<String>.from(widget.deck.words)..shuffle();

    timeRemaining = widget.roundLength;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimer();
    _startTiltDetection();
  }

  @override
  void dispose() {
    timer?.cancel();
    urgencyTimer?.cancel();
    accelerometerSubscription?.cancel();
    _pulseController.dispose();

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
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
      return;
    }

    urgencyTimer?.cancel();

    int interval;

    if (timeRemaining <= 3) {
      interval = 150;
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (timeRemaining <= 6) {
      interval = 350;
    } else {
      interval = 700;
    }

    urgencyTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      HapticFeedback.lightImpact();
    });
  }

  void _finishGame() async {
    timer?.cancel();

    if (!mounted) return;

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

  Color get _timerColor {
    if (timeRemaining <= 3) return _kUrgentColor;
    if (timeRemaining <= 10) return _kWarningColor;
    return _kNormalTimerColor;
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
          top: false,
          bottom: false,
          left: true,
          right: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: .92,
                          child: Opacity(
                            opacity: .9,
                            child: _wordCard(
                              words[(currentIndex + 1) % words.length],
                            ),
                          ),
                        ),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (showingSwipeHint)
                              Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 120),
                                  scale: (0.9 + (dragX.abs() / 120) * 0.3)
                                      .clamp(0.9, 1.2),
                                  child: AnimatedOpacity(
                                    duration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    opacity: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 30,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dragX > 0
                                            ? _kCorrectColor.withValues(
                                                alpha: .92,
                                              )
                                            : _kPassedColor.withValues(
                                                alpha: .92,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          30,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: .2,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        dragX > 0 ? "✓ CORRECT" : "✕ PASS",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
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
    final timerColor = _timerColor;

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _LiveScoreChip(correct: correct, passed: passed),
              ),
              ScaleTransition(
                scale: _pulseScale,
                child: Text(
                  timerText,
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TimerProgressBar(
            value: widget.roundLength == 0
                ? 0
                : timeRemaining / widget.roundLength,
            color: timerColor,
          ),

          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF241C3D),
                  ),
                ),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                "← Pass",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kPassedColor,
                ),
              ),

              const Text(
                "Correct →",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kCorrectColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slim countdown bar under the timer digits, color-matched to the
/// current urgency state.
class _TimerProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _TimerProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: const Color(0xFFEDEAF5),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

/// Small, unobtrusive running tally so players can glance at the score
/// mid-round without it competing with the word itself.
class _LiveScoreChip extends StatelessWidget {
  final int correct;
  final int passed;

  const _LiveScoreChip({required this.correct, required this.passed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: _kCorrectColor),
          const SizedBox(width: 3),
          Text(
            '$correct',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kCorrectColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.close_rounded, size: 14, color: _kPassedColor),
          const SizedBox(width: 3),
          Text(
            '$passed',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kPassedColor,
            ),
          ),
        ],
      ),
    );
  }
}