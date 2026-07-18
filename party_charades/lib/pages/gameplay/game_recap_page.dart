import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:party_charades/models/answer.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_page.dart';

class GameRecapPage extends StatefulWidget {
  final List<Answer> answers;
  final String deckName;
  final Deck deck;
  final int roundLength;

  const GameRecapPage({
    super.key,
    required this.answers,
    required this.deckName,
    required this.deck,
    required this.roundLength,
  });

  @override
  State<GameRecapPage> createState() => _GameRecapPageState();
}

class _GameRecapPageState extends State<GameRecapPage> {
  late ConfettiController confettiController;

  int get correct => widget.answers.where((a) => a.correct).length;

  int get passed => widget.answers.where((a) => !a.correct).length;

  @override
  void initState() {
    super.initState();

    confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    confettiController.play();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.secondary, colors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🎉 Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: .3,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Round Complete!",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.deckName,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Score(
                        title: "Correct",
                        value: correct,
                        color: Colors.green,
                      ),

                      _Score(title: "Passed", value: passed, color: Colors.red),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),

                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),

                        itemCount: widget.answers.length,

                        separatorBuilder: (_, _) => const Divider(),

                        itemBuilder: (context, index) {
                          final answer = widget.answers[index];

                          return ListTile(
                            leading: Icon(
                              answer.correct
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: answer.correct ? Colors.green : Colors.red,
                            ),

                            title: Text(
                              answer.word,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: answer.correct
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),

                            trailing: Text(
                              answer.correct ? "Correct" : "Passed",
                              style: TextStyle(
                                color: answer.correct
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.replay),
                              label: const Text("Play Again"),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GamePage(
                                      deck: widget.deck,
                                      roundLength: widget.roundLength,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Back to Decks",
                                style: TextStyle(color: Colors.white),
                              ),
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
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _Score({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}
