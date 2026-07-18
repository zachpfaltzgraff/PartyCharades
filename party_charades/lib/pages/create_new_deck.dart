import 'package:flutter/material.dart';
import 'package:party_charades/models/deck.dart';
import 'package:party_charades/services/deck_service.dart';

class CreateNewDeck extends StatefulWidget {
  final Deck? deck;

  const CreateNewDeck({super.key, this.deck});

  @override
  State<CreateNewDeck> createState() => _CreateNewDeckState();
}

class _CreateNewDeckState extends State<CreateNewDeck> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();

  final List<String> words = [];

  bool saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.deck != null) {
      _nameController.text = widget.deck!.name;
      words.addAll(widget.deck!.words);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wordController.dispose();
    super.dispose();
  }

  void addWord() {
    final word = _wordController.text.trim();

    if (word.isEmpty) return;

    if (words.contains(word)) {
      _wordController.clear();
      return;
    }

    setState(() {
      words.add(word);
    });

    _wordController.clear();
  }

  Future<void> saveDeck() async {
    if (!_formKey.currentState!.validate()) return;

    if (words.isEmpty) {
      return;
    }

    setState(() {
      saving = true;
    });

    final deck = widget.deck ?? Deck();

    deck.name = _nameController.text.trim();
    deck.words = List.from(words);

    await DeckService.saveDeck(deck);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> _deleteDeck() async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Deck?"),
          content: Text(
            'Are you sure you want to delete "${widget.deck!.name}"?\n\nThis cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (delete != true) return;

    await DeckService.deleteDeck(widget.deck!);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.deck == null ? "Create Deck" : "Edit Deck",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Deck Name",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Enter a deck name.";
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: "Add Word",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addWord(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(onPressed: addWord, child: const Icon(Icons.add)),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: words.isEmpty
                  ? const Center(
                      child: Text(
                        "No words yet.\nAdd your first word above!",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: words.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final word = words[index];

                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(child: Text("${index + 1}")),
                            title: Text(word),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  words.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 30),

            if (widget.deck != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    "Delete Deck",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: _deleteDeck,
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : saveDeck,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
