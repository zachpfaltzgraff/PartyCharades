import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/pages/create_new_deck.dart';
import 'package:party_charades/pages/gameplay/ready_page.dart';
import 'package:party_charades/services/audio_service.dart';
import 'package:party_charades/services/deck_import_export_service.dart';

class DeckCard extends StatelessWidget {
  final Deck deck;

  final VoidCallback? onEdited;

  const DeckCard({super.key, required this.deck, this.onEdited});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        AudioService().playHapticCorrect();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReadyPage(deck: deck)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [colors.primary, colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: .15),
            ),
          ],
        ),

        padding: const EdgeInsets.all(20),

        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.style_rounded, size: 42, color: Colors.white),

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
                  style: TextStyle(color: Colors.white.withValues(alpha: .8)),
                ),
              ],
            ),

            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () async {
                    AudioService().playHapticCorrect();
                    final edited = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => CreateNewDeck(deck: deck),
                    );

                    if (edited == true && context.mounted) {
                      onEdited?.call();
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Builder(
                  builder: (iconContext) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () async {
                        AudioService().playHapticCorrect();
                        final box =
                            iconContext.findRenderObject() as RenderBox?;
                        final origin = box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null;

                        await DeckImportExportService.shareDeck(
                          deck,
                          sharePositionOrigin: origin,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.file_upload_outlined,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
