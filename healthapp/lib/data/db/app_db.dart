import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;
  static const _dbName = 'health_billing.db';
  static const _dbVersion = 1;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final Directory dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        final v1 = await _loadAssetSql('lib/data/migrations/v1.sql');
        await _executeBatch(db, v1);
      },
    );
    return _db!;
  }

  static Future<void> _executeBatch(Database db, String sql) async {
    final batch = db.batch();
    final statements =
        sql.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final st in statements) {
      batch.execute(st);
    }
    await batch.commit(noResult: true);
  }

  static Future<String> _loadAssetSql(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      if (kIsWeb) rethrow;
      final file = File(assetPath);
      if (await file.exists()) {
        return file.readAsString();
      }
      rethrow;
    }
  }
}
