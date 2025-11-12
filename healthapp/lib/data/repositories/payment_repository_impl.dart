import 'package:health_billing/data/models/invoice_model.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../dao/invoice_dao.dart';
import '../dao/payment_dao.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDao paymentDao;
  final InvoiceDao invoiceDao;

  PaymentRepositoryImpl({required this.paymentDao, required this.invoiceDao});

  String _methodToDb(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.card => 'card',
        PaymentMethod.bank => 'bank',
        PaymentMethod.stripe => 'stripe',
      };

  String _statusToDb(PaymentStatus s) => switch (s) {
        PaymentStatus.enAttente => 'en_attente',
        PaymentStatus.confirme => 'confirme',
        PaymentStatus.rembourse => 'rembourse',
      };

  @override
  Future<Payment> addPayment(Payment payment) async {
    final im = await invoiceDao.getById(payment.invoiceId);
    if (im == null) throw const NotFoundFailure('Invoice not found');
    final model = PaymentModel(
      id: payment.id,
      invoiceId: payment.invoiceId,
      amountCents: payment.amountCents,
      method: _methodToDb(payment.method),
      status: _statusToDb(payment.status),
      reference: payment.reference,
      createdAt: payment.createdAtMs,
      deletedAt: payment.deletedAtMs,
    );
    await paymentDao.insertPayment(model);
    // Update invoice amount_due and status atomically (simplified)
    final paid = await paymentDao.confirmedPaymentsSum(payment.invoiceId);
    final amountDue = (im.totalCents - paid).clamp(0, 1 << 31);
    final status = amountDue == 0 ? 'payee' : im.status;
    await invoiceDao.updateInvoice(
      PaymentRepositoryImpl._copyInvoice(im, amountDue, status),
    );
    return payment;
  }

  @override
  Future<void> deletePaymentSoft(String paymentId) async {
    final p = await paymentDao.getById(paymentId);
    if (p == null) return;
    await paymentDao.softDelete(paymentId);
    final inv = await invoiceDao.getById(p.invoiceId);
    if (inv == null) return;
    final paid = await paymentDao.confirmedPaymentsSum(p.invoiceId);
    final amountDue = (inv.totalCents - paid).clamp(0, 1 << 31);
    final status = amountDue == 0 ? 'payee' : inv.status;
    await invoiceDao.updateInvoice(
      PaymentRepositoryImpl._copyInvoice(inv, amountDue, status),
    );
  }

  @override
  Future<Payment> updatePaymentStatus(
      String paymentId, PaymentStatus status) async {
    final p = await paymentDao.getById(paymentId);
    if (p == null) throw const NotFoundFailure('Payment not found');
    await paymentDao.updatePaymentStatus(paymentId, _statusToDb(status));
    final inv = await invoiceDao.getById(p.invoiceId);
    if (inv != null) {
      final paid = await paymentDao.confirmedPaymentsSum(p.invoiceId);
      final amountDue = (inv.totalCents - paid).clamp(0, 1 << 31);
      final statusInv = amountDue == 0 ? 'payee' : inv.status;
      await invoiceDao.updateInvoice(
        PaymentRepositoryImpl._copyInvoice(inv, amountDue, statusInv),
      );
    }
    return Payment(
      id: p.id,
      invoiceId: p.invoiceId,
      amountCents: p.amountCents,
      method: PaymentMethod.values.firstWhere((e) => _methodToDb(e) == p.method,
          orElse: () => PaymentMethod.cash),
      status: status,
      reference: p.reference,
      createdAtMs: p.createdAt,
      deletedAtMs: p.deletedAt,
    );
  }

  static InvoiceModel _copyInvoice(InvoiceModel inv, int amountDue, String status) => InvoiceModel(
        id: inv.id,
        patientId: inv.patientId,
        episode: inv.episode,
        issueDate: inv.issueDate,
        dueDate: inv.dueDate,
        status: status,
        notes: inv.notes,
        subtotalCents: inv.subtotalCents,
        taxCents: inv.taxCents,
        discountCents: inv.discountCents,
        totalCents: inv.totalCents,
        amountDueCents: amountDue,
        qrPayUrl: inv.qrPayUrl,
        createdAt: inv.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        needsSync: 1,
      );
}
