import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';
import '../models/patient_model.dart';

class PatientDao {
  Future<Database> get _db async => AppDb.instance();

  Future<PatientModel?> findById(String id) async {
    final db = await _db;
    final rows = await db.query('patients', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return PatientModel.fromMap(rows.first);
  }
}

