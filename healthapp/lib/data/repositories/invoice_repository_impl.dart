import '../../core/errors/failures.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/line_item.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../dao/invoice_dao.dart';
import '../dao/payment_dao.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceDao invoiceDao;
  final PaymentDao paymentDao;

  InvoiceRepositoryImpl({required this.invoiceDao, required this.paymentDao});

  @override
  Future<Invoice> createInvoice(
      {required Invoice draft, required List<LineItem> lines}) async {
    final im = _toModel(draft);
    final items = lines
        .map((e) => LineItemModel(
              id: e.id,
              invoiceId: draft.id,
              label: e.label,
              qty: e.qty,
              unitPriceCents: e.unitPriceCents,
              taxRate: e.taxRate,
              discountCents: e.discountCents,
              lineTotalCents: e.lineTotalCents,
            ))
        .toList();
    await invoiceDao.insertInvoice(im);
    await invoiceDao.replaceLineItems(draft.id, items);
    return draft;
  }

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final inv = await invoiceDao.getById(invoiceId);
    if (inv == null) throw const NotFoundFailure('Invoice not found');
    final updated = InvoiceModel(
      id: inv.id,
      patientId: inv.patientId,
      episode: inv.episode,
      issueDate: inv.issueDate,
      dueDate: inv.dueDate,
      status: 'annulee',
      notes: inv.notes,
      subtotalCents: inv.subtotalCents,
      taxCents: inv.taxCents,
      discountCents: inv.discountCents,
      totalCents: inv.totalCents,
      amountDueCents: inv.amountDueCents,
      qrPayUrl: inv.qrPayUrl,
      createdAt: inv.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      needsSync: 1,
    );
    await invoiceDao.updateInvoice(updated);
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    final inv = await invoiceDao.getById(invoiceId);
    if (inv == null) throw const NotFoundFailure('Invoice not found');
    await invoiceDao.deleteInvoiceCascade(invoiceId);
  }

  @override
  Future<Invoice> getInvoiceDetails(String id) async {
    final inv = await invoiceDao.getById(id);
    if (inv == null) throw const NotFoundFailure('Invoice not found');
    // recompute status paid if amountDue == 0
    final paidSum = await paymentDao.confirmedPaymentsSum(id);
    final amountDue = (inv.totalCents - paidSum).clamp(0, 1 << 31);
    final status = amountDue == 0 ? 'payee' : inv.status;
    final normalized = InvoiceModel(
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
      updatedAt: inv.updatedAt,
      needsSync: inv.needsSync,
    );
    return _fromModel(normalized);
  }

  @override
  Future<List<Invoice>> listInvoices(
      {String? patientQuery,
      InvoiceStatus? status,
      int? fromMs,
      int? toMs,
      String? sortBy,
      bool descending = true}) async {
    final list = await invoiceDao.list(
      patientQuery: patientQuery,
      status: status == null ? null : _statusToDb(status),
      fromMs: fromMs,
      toMs: toMs,
      sortBy: sortBy,
      descending: descending,
    );
    return list.map(_fromModel).toList();
  }

  @override
  Future<Invoice> updateInvoice(Invoice invoice, List<LineItem>? lines) async {
    final current = await invoiceDao.getById(invoice.id);
    if (current == null) throw const NotFoundFailure('Invoice not found');
    await invoiceDao.updateInvoice(_toModel(invoice));
    if (lines != null) {
      final items = lines
          .map((e) => LineItemModel(
                id: e.id,
                invoiceId: invoice.id,
                label: e.label,
                qty: e.qty,
                unitPriceCents: e.unitPriceCents,
                taxRate: e.taxRate,
                discountCents: e.discountCents,
                lineTotalCents: e.lineTotalCents,
              ))
          .toList();
      await invoiceDao.replaceLineItems(invoice.id, items);
    }
    return invoice;
  }

  static String _statusToDb(InvoiceStatus s) => switch (s) {
        InvoiceStatus.brouillon => 'brouillon',
        InvoiceStatus.enAttente => 'en_attente',
        InvoiceStatus.payee => 'payee',
        InvoiceStatus.annulee => 'annulee',
      };

  static InvoiceStatus _statusFromDb(String s) => switch (s) {
        'brouillon' => InvoiceStatus.brouillon,
        'en_attente' => InvoiceStatus.enAttente,
        'payee' => InvoiceStatus.payee,
        'annulee' => InvoiceStatus.annulee,
        _ => InvoiceStatus.enAttente,
      };

  static Invoice _fromModel(InvoiceModel m) => Invoice(
        id: m.id,
        patientId: m.patientId,
        episode: m.episode,
        issueDateMs: m.issueDate,
        dueDateMs: m.dueDate,
        status: _statusFromDb(m.status),
        notes: m.notes,
        subtotalCents: m.subtotalCents,
        taxCents: m.taxCents,
        discountCents: m.discountCents,
        totalCents: m.totalCents,
        amountDueCents: m.amountDueCents,
        qrPayUrl: m.qrPayUrl,
        createdAtMs: m.createdAt,
        updatedAtMs: m.updatedAt,
        needsSync: m.needsSync,
      );

  static InvoiceModel _toModel(Invoice inv) => InvoiceModel(
        id: inv.id,
        patientId: inv.patientId,
        episode: inv.episode,
        issueDate: inv.issueDateMs,
        dueDate: inv.dueDateMs,
        status: _statusToDb(inv.status),
        notes: inv.notes,
        subtotalCents: inv.subtotalCents,
        taxCents: inv.taxCents,
        discountCents: inv.discountCents,
        totalCents: inv.totalCents,
        amountDueCents: inv.amountDueCents,
        qrPayUrl: inv.qrPayUrl,
        createdAt: inv.createdAtMs,
        updatedAt: inv.updatedAtMs,
        needsSync: inv.needsSync,
      );
}
