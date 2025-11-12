import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';

class JsonBackupService {
  Future<Map<String, dynamic>> exportAll() async {
    final db = await AppDb.instance();
    Future<List<Map<String, Object?>>> all(String table) => db.query(table);
    final data = <String, dynamic>{
      'patients': await all('patients'),
      'invoices': await all('invoices'),
      'line_items': await all('line_items'),
      'payments': await all('payments'),
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
    };
    return data;
  }

  Future<void> importAll(Map<String, dynamic> json) async {
    final db = await AppDb.instance();
    final batch = db.batch();
    for (final table in ['patients', 'invoices', 'line_items', 'payments']) {
      final rows = (json[table] as List).cast<Map<String, Object?>>();
      for (final row in rows) {
        batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<File> exportToFile() async {
    final data = await exportAll();
    final dir = await _resolveDocsDir();
    final file = File(p.join(dir.path, 'health_billing_export.json'));
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  Future<void> importFromFile() async {
    final dir = await _resolveDocsDir();
    final file = File(p.join(dir.path, 'health_billing_export.json'));
    if (!await file.exists()) return;
    final jsonStr = await file.readAsString();
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    await importAll(map);
  }
}

Future<Directory> _resolveDocsDir() async {
  try {
    return await getApplicationDocumentsDirectory();
  } catch (_) {
    final dbPath = await getDatabasesPath();
    return Directory(dbPath);
  }
}
