import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/deck_card.dart';
import 'package:party_charades/services/deck_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Deck> decks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDecks();
  }

  Future<void> loadDecks() async {
    final result = await DeckService.getAllDecks();

    setState(() {
      decks = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: create deck
        },
        icon: const Icon(Icons.add),
        label: const Text("New Deck"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.secondary,
              colors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: loadDecks,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : GridView.builder(
                    itemCount: decks.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: .85,
                    ),
                    itemBuilder: (context, index) {
                      return DeckCard(deck: decks[index]);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}