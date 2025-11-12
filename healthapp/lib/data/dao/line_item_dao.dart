import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';
import '../models/line_item_model.dart';

class LineItemDao {
  Future<Database> get _db async => AppDb.instance();

  Future<void> insertAll(List<LineItemModel> items) async {
    final db = await _db;
    final batch = db.batch();
    for (final it in items) {
      batch.insert('line_items', it.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}

