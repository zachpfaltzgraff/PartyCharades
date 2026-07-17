import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_charades/models/deck.dart';

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
                    child: Dismissible(
                      key: ValueKey("$currentWord-$currentIndex"),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          _answer(true);
                        } else {
                          _answer(false);
                        }
                      },
                      child: Container(
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
                                  currentWord,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                Text(
                                  "← Pass",
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  "Correct →",
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
