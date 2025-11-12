import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';

class InvoiceDao {
  Future<Database> get _db async => AppDb.instance();

  Future<void> insertInvoice(InvoiceModel model) async {
    final db = await _db;
    await db.insert('invoices', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateInvoice(InvoiceModel model) async {
    final db = await _db;
    await db.update('invoices', model.toMap(), where: 'id=?', whereArgs: [model.id]);
  }

  Future<InvoiceModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('invoices', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return InvoiceModel.fromMap(rows.first);
  }

  Future<List<LineItemModel>> getLineItems(String invoiceId) async {
    final db = await _db;
    final rows = await db.query('line_items', where: 'invoice_id=?', whereArgs: [invoiceId]);
    return rows.map(LineItemModel.fromMap).toList();
  }

  Future<void> replaceLineItems(String invoiceId, List<LineItemModel> items) async {
    final db = await _db;
    final batch = db.batch();
    batch.delete('line_items', where: 'invoice_id=?', whereArgs: [invoiceId]);
    for (final it in items) {
      batch.insert('line_items', it.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteInvoiceCascade(String invoiceId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('line_items', where: 'invoice_id=?', whereArgs: [invoiceId]);
      await txn.delete('payments', where: 'invoice_id=?', whereArgs: [invoiceId]);
      await txn.delete('invoices', where: 'id=?', whereArgs: [invoiceId]);
    });
  }

  Future<List<InvoiceModel>> list({
    String? patientQuery,
    String? status,
    int? fromMs,
    int? toMs,
    String? sortBy,
    bool descending = true,
  }) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (status != null) {
      where.add('i.status=?');
      args.add(status);
    }
    if (fromMs != null) {
      where.add('i.issue_date>=?');
      args.add(fromMs);
    }
    if (toMs != null) {
      where.add('i.issue_date<=?');
      args.add(toMs);
    }
    if (patientQuery != null && patientQuery.trim().isNotEmpty) {
      where.add('(p.full_name LIKE ? OR i.id LIKE ?)');
      final pattern = '%${patientQuery.trim()}%';
      args..add(pattern)..add(pattern);
    }
    final orderBy = switch (sortBy) {
      'total' => 'i.total_cents ${descending ? 'DESC' : 'ASC'}',
      _ => 'i.issue_date ${descending ? 'DESC' : 'ASC'}',
    };
    final sql = StringBuffer('SELECT i.* FROM invoices i LEFT JOIN patients p ON p.id=i.patient_id');
    if (where.isNotEmpty) {
      sql.write(' WHERE ');
      sql.write(where.join(' AND '));
    }
    sql.write(' ORDER BY ');
    sql.write(orderBy);
    final rows = await db.rawQuery(sql.toString(), args);
    return rows.map(InvoiceModel.fromMap).toList();
  }
}
