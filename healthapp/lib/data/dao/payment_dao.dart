import 'package:sqflite/sqflite.dart';

import '../db/app_db.dart';
import '../models/payment_model.dart';

class PaymentDao {
  Future<Database> get _db async => AppDb.instance();

  Future<void> insertPayment(PaymentModel model) async {
    final db = await _db;
    await db.insert('payments', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<PaymentModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('payments', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return PaymentModel.fromMap(rows.first);
  }

  Future<void> updatePaymentStatus(String id, String status) async {
    final db = await _db;
    await db.update('payments', {'status': status}, where: 'id=?', whereArgs: [id]);
  }

  Future<void> softDelete(String id) async {
    final db = await _db;
    await db.update('payments', {'deleted_at': DateTime.now().millisecondsSinceEpoch}, where: 'id=?', whereArgs: [id]);
  }

  Future<int> confirmedPaymentsSum(String invoiceId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount_cents),0) as s FROM payments WHERE invoice_id=? AND status='confirme' AND (deleted_at IS NULL)",
      [invoiceId],
    );
    return (rows.first['s'] as int?) ?? 0;
  }

  Future<List<PaymentModel>> listByInvoice(String invoiceId) async {
    final db = await _db;
    final rows = await db.query('payments', where: 'invoice_id=? AND (deleted_at IS NULL)', whereArgs: [invoiceId], orderBy: 'created_at DESC');
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<List<PaymentModel>> list({int? fromMs, int? toMs, String? method, String? status}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];
    if (fromMs != null) {
      where.add('created_at>=?');
      args.add(fromMs);
    }
    if (toMs != null) {
      where.add('created_at<=?');
      args.add(toMs);
    }
    if (method != null) {
      where.add('method=?');
      args.add(method);
    }
    if (status != null) {
      where.add('status=?');
      args.add(status);
    }
    where.add('(deleted_at IS NULL)');
    final rows = await db.query('payments', where: where.join(' AND '), whereArgs: args, orderBy: 'created_at DESC');
    return rows.map(PaymentModel.fromMap).toList();
  }
}
