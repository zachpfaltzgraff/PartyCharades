import 'package:flutter/material.dart';
import 'package:party_charades/pages/gameplay/game_page_components/game_theme.dart';

class LiveScoreChip extends StatelessWidget {
  final int correct;
  final int passed;

  const LiveScoreChip({super.key, required this.correct, required this.passed});

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
          Icon(Icons.check_rounded, size: 14, color: GameTheme().correctColor),
          const SizedBox(width: 3),
          Text(
            '$correct',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GameTheme().correctColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.close_rounded, size: 14, color: GameTheme().passedColor),
          const SizedBox(width: 3),
          Text(
            '$passed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GameTheme().passedColor,
            ),
          ),
        ],
      ),
    );
  }
}