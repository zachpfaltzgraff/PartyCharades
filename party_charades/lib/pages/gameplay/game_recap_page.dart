import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:party_charades/models/answer.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/gameplay/game_page.dart';
import 'package:party_charades/services/in_app_review_service.dart';

class _RecapPalette {
  final Color correct;
  final Color passed;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color chip;

  const _RecapPalette({
    required this.correct,
    required this.passed,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.chip,
  });

  factory _RecapPalette.of(BuildContext context) {
    return const _RecapPalette(
      correct: Color(0xFF1FB874),
      passed: Color(0xFFE84855),
      surface: Colors.white,
      onSurface: Color(0xFF241C3D),
      onSurfaceMuted: Color(0xFF7A7291),
      chip: Color(0x33FFFFFF),
    );
  }
}

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

class _GameRecapPageState extends State<GameRecapPage>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  int get correct => widget.answers.where((a) => a.correct).length;
  int get passed => widget.answers.where((a) => !a.correct).length;

  BannerAd? bannerAd;
  bool loadedAdProperly = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
    _confettiController.play();

    InAppReviewService().requestReview();

    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5936113316990256/5545903895',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            loadedAdProperly = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = _RecapPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              gravity: 0.3,
              colors: [
                palette.correct,
                palette.passed,
                Colors.white,
                colors.primary,
              ],
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _entranceFade,
              child: SlideTransition(
                position: _entranceSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    children: [
                      _Header(
                        deckName: widget.deckName,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 20),
                      _ScorePanel(correct: correct, passed: passed),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _AnswerListCard(
                          answers: widget.answers,
                          palette: palette,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ActionButtons(
                        palette: palette,
                        onPlayAgain: () {
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
                        onBackToDecks: () => Navigator.pop(context),
                      ),
                      if (loadedAdProperly)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          height: bannerAd!.size.height.toDouble(),
                          width: bannerAd!.size.width.toDouble(),
                          child: AdWidget(ad: bannerAd!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String deckName;
  final _RecapPalette palette;
  final TextTheme textTheme;

  const _Header({
    required this.deckName,
    required this.palette,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: palette.chip,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Text(
            deckName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  final int correct;
  final int passed;

  const _ScorePanel({required this.correct, required this.passed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreboardStat(
              label: 'CORRECT',
              value: correct,
              color: const Color(0xFF34E28A),
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: Colors.white.withOpacity(0.25),
          ),
          Expanded(
            child: _ScoreboardStat(
              label: 'PASSED',
              value: passed,
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreboardStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreboardStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, count, _) => Text(
            '${count.round()}',
            style: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _AnswerListCard extends StatelessWidget {
  final List<Answer> answers;
  final _RecapPalette palette;

  const _AnswerListCard({required this.answers, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: answers.isEmpty
          ? Center(
              child: Text(
                'No words this round',
                style: TextStyle(color: palette.onSurfaceMuted, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: answers.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: palette.onSurfaceMuted.withOpacity(0.15),
              ),
              itemBuilder: (context, index) =>
                  _AnswerTile(answer: answers[index], palette: palette),
            ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final Answer answer;
  final _RecapPalette palette;

  const _AnswerTile({required this.answer, required this.palette});

  @override
  Widget build(BuildContext context) {
    final color = answer.correct ? palette.correct : palette.passed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              answer.correct ? Icons.check_rounded : Icons.close_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              answer.word,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.onSurface,
              ),
            ),
          ),
          Text(
            answer.correct ? 'Correct' : 'Passed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final _RecapPalette palette;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToDecks;

  const _ActionButtons({
    required this.palette,
    required this.onPlayAgain,
    required this.onBackToDecks,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Play Again'),
            onPressed: onPlayAgain,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: onBackToDecks,
            child: const Text('Back to Decks'),
          ),
        ),
      ],
    );
  }
}
