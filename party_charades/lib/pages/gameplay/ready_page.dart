import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_page.dart';
import 'package:party_charades/services/settings_service.dart';

class ReadyPage extends StatefulWidget {
  final Deck deck;

  const ReadyPage({super.key, required this.deck});

  @override
  State<ReadyPage> createState() => _ReadyPageState();
}

class _ReadyPageState extends State<ReadyPage> {
  int roundLength = SettingsService.defaultRoundLength;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    roundLength = await SettingsService.getRoundLength();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.secondary, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const Spacer(),

                const Icon(Icons.celebration, size: 90, color: Colors.white),

                const SizedBox(height: 24),

                Text(
                  widget.deck.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "${widget.deck.words.length} words",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "$roundLength second round",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.phone_iphone, color: Colors.white, size: 40),
                      SizedBox(height: 16),
                      Text(
                        "Pass the phone to the player.\nTap START when everyone is ready!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colors.primary,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "START",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GamePage(
                            deck: widget.deck,
                            roundLength: roundLength,
                          ),
                        ),
                      );
                    },
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
