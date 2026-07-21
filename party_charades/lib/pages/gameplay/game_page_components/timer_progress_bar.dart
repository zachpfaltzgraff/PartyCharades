import 'package:flutter/material.dart';

class TimerProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const TimerProgressBar({super.key, required this.value, required this.color});

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