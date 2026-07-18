import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/create_new_deck.dart';
import 'package:party_charades/pages/deck_card.dart';
import 'package:party_charades/pages/settings/settings_page.dart';
import 'package:party_charades/services/deck_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Deck> decks = [];
  bool loading = true;
  BannerAd? bannerAd;

  bool loadedAdProperly = false;

  @override
  void initState() {
    super.initState();
    loadDecks();

    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-5936113316990256/9315245635',
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
    bannerAd?.dispose();
    super.dispose();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Party Charades",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => const CreateNewDeck(),
          );

          if (created == true) {
            loadDecks();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("New Deck"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.secondary, colors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadDecks,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: 8,
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          itemCount: decks.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            return DeckCard(
                              deck: decks[index],
                              onEdited: loadDecks,
                            );
                          },
                        ),
                ),
              ),
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
    );
  }
}
