import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/deck.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open([DeckSchema], directory: dir.path);
  }
}
