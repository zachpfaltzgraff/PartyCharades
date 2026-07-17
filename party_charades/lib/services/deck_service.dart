import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:party_charades/models/deck.dart';

import 'database_service.dart';

class DeckService {
  static const starterDecks = [
    'animals',
    'movies',
    'disney',
    'food',
  ];

  static Future<void> loadStarterDecks() async {
    final existing = await DatabaseService.isar.decks.count();

    if (existing > 0) {
      return;
    }

    final decks = <Deck>[];

    for (final file in starterDecks) {
      final jsonString =
          await rootBundle.loadString('assets/decks/$file.json');

      final json = jsonDecode(jsonString);

      final deck = Deck()
        ..name = json["name"]
        ..builtIn = true
        ..words = List<String>.from(json["words"]);

      decks.add(deck);
    }

    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.decks.putAll(decks);
    });
  }

  static Future<List<Deck>> getAllDecks() async {
    final decks = await DatabaseService.isar.decks.where().findAll();

    return decks;
  }

  static Future<void> saveDeck(Deck deck) async {
    await DatabaseService.isar.writeTxn(() async {
      await DatabaseService.isar.decks.put(deck);
    });
  }
}