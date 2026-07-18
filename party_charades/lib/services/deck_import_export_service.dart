import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:party_charades/models/deck.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thrown when a deck file can't be read or doesn't match the expected
/// format. The [message] is safe to show directly to the user.
class DeckImportException implements Exception {
  final String message;
  DeckImportException(this.message);

  @override
  String toString() => message;
}

class DeckImportExportService {
  /// Writes [deck] out as a formatted .json file and opens the native
  /// share sheet (Messages, Email, AirDrop, Google Drive, etc).
  static Future<void> shareDeck(Deck deck) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'name': deck.name,
      'words': deck.words,
    });

    final sanitizedName = _sanitizeFileName(deck.name);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$sanitizedName.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: '${deck.name} — Party Charades Deck',
      text: 'Check out this word list for Party Charades!',
    );
  }

  /// Opens a file picker restricted to .json files, validates the
  /// contents, and returns a [Deck]. Throws [DeckImportException] with a
  /// user-friendly message on any problem.
  static Future<Deck> importDeck() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw DeckImportException('No file was selected.');
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw DeckImportException('Could not read the selected file.');
    }

    final String rawContent;
    try {
      rawContent = utf8.decode(bytes);
    } catch (_) {
      throw DeckImportException("That file doesn't look like text/JSON.");
    }

    return parseDeckJson(rawContent);
  }

  /// Parses and validates a raw JSON string into a [Deck]. Kept separate
  /// from [importDeck] so it can also power deep links, clipboard paste,
  /// or unit tests.
  static Deck parseDeckJson(String rawContent) {
    dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } catch (_) {
      throw DeckImportException(
        "That file isn't valid JSON — it may have been edited incorrectly.",
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw DeckImportException("This file isn't in the right deck format.");
    }

    final nameValue = decoded['name'];
    final wordsValue = decoded['words'];

    if (nameValue is! String || nameValue.trim().isEmpty) {
      throw DeckImportException('The deck is missing a valid "name".');
    }

    if (wordsValue is! List || wordsValue.isEmpty) {
      throw DeckImportException(
        'The deck is missing a "words" list, or it\'s empty.',
      );
    }

    final words = <String>[];
    for (final entry in wordsValue) {
      if (entry is! String || entry.trim().isEmpty) {
        throw DeckImportException(
          'Every word in the list needs to be non-empty text.',
        );
      }
      words.add(entry.trim());
    }

    // Preserve order while dropping duplicates.
    final uniqueWords = LinkedHashSet<String>.from(words).toList();

    if (uniqueWords.length < 4) {
      throw DeckImportException(
        'A deck needs at least 4 words to be worth playing.',
      );
    }

    return Deck()
        ..name = nameValue.trim()
        ..words = uniqueWords;
  }

  static String _sanitizeFileName(String name) {
    final sanitized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'party_charades_deck' : sanitized;
  }
}