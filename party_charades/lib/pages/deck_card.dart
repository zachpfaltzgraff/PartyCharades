
import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;

  const DeckCard({
    super.key,
    required this.deck,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        // TODO: open deck
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              colors.primary,
              colors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(.15),
            )
          ],
        ),

        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.style_rounded,
              size: 42,
              color: Colors.white,
            ),

            const Spacer(),

            Text(
              deck.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "${deck.words.length} words",
              style: TextStyle(
                color: Colors.white.withOpacity(.8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}