import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/models/answer.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_page_components/cancel_round_button.dart';
import 'package:party_charades/pages/gameplay/game_page_components/game_theme.dart';
import 'package:party_charades/pages/gameplay/game_page_components/live_score_chip.dart';
import 'package:party_charades/pages/gameplay/game_page_components/timer_progress_bar.dart';
import 'package:party_charades/pages/gameplay/game_recap_page.dart';
import 'package:party_charades/services/audio_service.dart';
import 'package:party_charades/services/settings_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

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

  // Pre-round 3-2-1 countdown state. Nothing in the round (timer, tilt
  // detection, swipes) is active until this finishes.
  bool showCountdown = true;
  int countdownValue = 3;
  Timer? countdownTimer;

  // Visual pulse synced to the haptic urgency feedback in the final
  // seconds of the round. Purely cosmetic — does not affect timing logic.
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  bool tiltControl = SettingsService.defaultTiltControl;

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

    _startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    urgencyTimer?.cancel();
    countdownTimer?.cancel();
    accelerometerSubscription?.cancel();
    _pulseController.dispose();

    super.dispose();
  }

  void _startCountdown() async {
    HapticFeedback.mediumImpact();
    bool tilt = await SettingsService.getTiltControl();

    setState(() {
      tiltControl = tilt;
    });

    countdownTimer = Timer.periodic(const Duration(milliseconds: 1250), (t) {
      if (!mounted) return;

      if (countdownValue <= 1) {
        t.cancel();

        setState(() {
          showCountdown = false;
        });

        _startTimer();
        if (!tiltControl) {
          // only start if tilt controls enabled
          _startTiltDetection();
        }
        return;
      }

      setState(() {
        countdownValue--;
      });

      HapticFeedback.mediumImpact();
    });
  }

  void _startTiltDetection() {
    accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (showCountdown) return;

      // Reset once phone is back near center.
      if (!canAnswer) {
        if (event.z > -6 && event.z < 6) {
          canAnswer = true;
        }
        return;
      }

      if (event.z > 6.25) {
        _answer(false);
      } else if (event.z < -6.25) {
        _answer(true);
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

  void _confirmQuit() async {
    urgencyTimer?.cancel();
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('End round?'),
        content: const Text('Your progress in this round will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('End round', style: TextStyle(color: GameTheme().passedColor)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldQuit == true) {
      timer?.cancel();
      accelerometerSubscription?.cancel();
      Navigator.pop(context); // back to whatever screen launched GamePage
    } else {
      _handleUrgency(); // resume urgency ticking if round is still going
    }
  }

  void _answer(bool wasCorrect) {
    if (!canAnswer || showCountdown) return;

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

    return '$minutes:$seconds';
  }

  Color get _timerColor {
    if (timeRemaining <= 3) return GameTheme().urgentColor;
    if (timeRemaining <= 10) return GameTheme().warningColor;
    return GameTheme().normalTimerColor;
  }

  String get _countdownText => countdownValue > 0 ? '$countdownValue' : 'GO!';

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
                            if (showingSwipeHint && !showCountdown)
                              Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 120),
                                  scale: (0.9 + (dragX.abs() / 120) * 0.3)
                                      .clamp(0.9, 1.2),
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
                                            ? GameTheme().correctColor.withValues(
                                                alpha: .92,
                                              )
                                            : GameTheme().passedColor.withValues(
                                                alpha: .92,
                                              ),
                                        borderRadius: BorderRadius.circular(30),
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
                                        dragX > 0 ? '✓ CORRECT' : '✕ PASS',
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
                                if (tiltControl) return;
                                if (!canAnswer || showCountdown) return;

                                setState(() {
                                  dragX += details.delta.dx;
                                });
                              },

                              onHorizontalDragEnd: (_) {
                                if (tiltControl) return;
                                if (!canAnswer || showCountdown) return;

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
                                        canAnswer = true;
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

                              child: tiltControl
                                  ? _wordCard(currentWord)
                                  : AnimatedContainer(
                                      duration: isAnimating
                                          ? const Duration(milliseconds: 250)
                                          : Duration.zero,

                                      transform: Matrix4.identity()
                                        ..translate(dragX)
                                        ..rotateZ(dragX / 700),

                                      child: _wordCard(currentWord),
                                    ),
                            ),

                            if (showCountdown) _countdownOverlay(),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CancelRoundButton(onTap: _confirmQuit),
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

  Widget _countdownOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              _countdownText,
              key: ValueKey(_countdownText),
              style: TextStyle(
                color: Colors.white,
                fontSize: countdownValue > 0 ? 120 : 96,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
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
                child: LiveScoreChip(correct: correct, passed: passed),
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
          TimerProgressBar(
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
              Text(
                tiltControl ? '↑ Pass' : '← Pass',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GameTheme().passedColor,
                ),
              ),

              Text(
                tiltControl ? '↓ Correct' : 'Correct →',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: GameTheme().correctColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}