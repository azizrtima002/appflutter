import 'package:health_billing/domain/entities/invoice.dart';
import 'package:health_billing/domain/entities/line_item.dart';
import 'package:health_billing/domain/entities/payment.dart';
import 'package:health_billing/domain/repositories/invoice_repository.dart';
import 'package:health_billing/domain/repositories/payment_repository.dart';

class FakeInvoiceRepo implements InvoiceRepository {
  final Map<String, Invoice> store = {};
  final Map<String, List<LineItem>> linesStore = {};

  @override
  Future<void> cancelInvoice(String invoiceId) async {
    final inv = store[invoiceId]!;
    store[invoiceId] = Invoice(
      id: inv.id,
      patientId: inv.patientId,
      episode: inv.episode,
      issueDateMs: inv.issueDateMs,
      dueDateMs: inv.dueDateMs,
      status: InvoiceStatus.annulee,
      notes: inv.notes,
      subtotalCents: inv.subtotalCents,
      taxCents: inv.taxCents,
      discountCents: inv.discountCents,
      totalCents: inv.totalCents,
      amountDueCents: inv.amountDueCents,
      qrPayUrl: inv.qrPayUrl,
      createdAtMs: inv.createdAtMs,
      updatedAtMs: inv.updatedAtMs,
      needsSync: 0,
    );
  }

  @override
  Future<Invoice> createInvoice({required Invoice draft, required List<LineItem> lines}) async {
    store[draft.id] = draft;
    linesStore[draft.id] = lines;
    return draft;
  }

  @override
  Future<Invoice> getInvoiceDetails(String id) async => store[id]!;

  @override
  Future<List<Invoice>> listInvoices({String? patientQuery, InvoiceStatus? status, int? fromMs, int? toMs, String? sortBy, bool descending = true}) async {
    var l = store.values.toList();
    if (status != null) {
      l = l.where((e) => e.status == status).toList();
    }
    return l;
  }

  @override
  Future<Invoice> updateInvoice(Invoice invoice, List<LineItem>? lines) async {
    store[invoice.id] = invoice;
    if (lines != null) linesStore[invoice.id] = lines;
    return invoice;
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    store.remove(invoiceId);
    linesStore.remove(invoiceId);
  }
}

class FakePaymentRepo implements PaymentRepository {
  final FakeInvoiceRepo invRepo;
  final Map<String, Payment> payments = {};
  FakePaymentRepo(this.invRepo);

  @override
  Future<Payment> addPayment(Payment payment) async {
    payments[payment.id] = payment;
    final inv = invRepo.store[payment.invoiceId]!;
    final paid = payments.values
        .where((p) => p.invoiceId == inv.id && p.deletedAtMs == null && p.status == PaymentStatus.confirme)
        .fold<int>(0, (s, p) => s + p.amountCents);
    final due = (inv.totalCents - paid).clamp(0, 1 << 31);
    final st = due == 0 ? InvoiceStatus.payee : InvoiceStatus.enAttente;
    invRepo.store[inv.id] = Invoice(
      id: inv.id,
      patientId: inv.patientId,
      episode: inv.episode,
      issueDateMs: inv.issueDateMs,
      dueDateMs: inv.dueDateMs,
      status: st,
      notes: inv.notes,
      subtotalCents: inv.subtotalCents,
      taxCents: inv.taxCents,
      discountCents: inv.discountCents,
      totalCents: inv.totalCents,
      amountDueCents: due,
      qrPayUrl: inv.qrPayUrl,
      createdAtMs: inv.createdAtMs,
      updatedAtMs: inv.updatedAtMs,
      needsSync: 0,
    );
    return payment;
  }

  @override
  Future<void> deletePaymentSoft(String paymentId) async {
    final p = payments[paymentId]!;
    payments[paymentId] = Payment(
      id: p.id,
      invoiceId: p.invoiceId,
      amountCents: p.amountCents,
      method: p.method,
      status: p.status,
      reference: p.reference,
      createdAtMs: p.createdAtMs,
      deletedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final inv = invRepo.store[p.invoiceId]!;
    final paid = payments.values
        .where((pp) => pp.invoiceId == inv.id && pp.deletedAtMs == null && pp.status == PaymentStatus.confirme)
        .fold<int>(0, (s, pp) => s + pp.amountCents);
    final due = (inv.totalCents - paid).clamp(0, 1 << 31);
    final st = due == 0 ? InvoiceStatus.payee : InvoiceStatus.enAttente;
    invRepo.store[inv.id] = Invoice(
      id: inv.id,
      patientId: inv.patientId,
      episode: inv.episode,
      issueDateMs: inv.issueDateMs,
      dueDateMs: inv.dueDateMs,
      status: st,
      notes: inv.notes,
      subtotalCents: inv.subtotalCents,
      taxCents: inv.taxCents,
      discountCents: inv.discountCents,
      totalCents: inv.totalCents,
      amountDueCents: due,
      qrPayUrl: inv.qrPayUrl,
      createdAtMs: inv.createdAtMs,
      updatedAtMs: inv.updatedAtMs,
      needsSync: 0,
    );
  }

  @override
  Future<Payment> updatePaymentStatus(String paymentId, PaymentStatus status) async {
    final p = payments[paymentId]!;
    final updated = Payment(
      id: p.id,
      invoiceId: p.invoiceId,
      amountCents: p.amountCents,
      method: p.method,
      status: status,
      reference: p.reference,
      createdAtMs: p.createdAtMs,
      deletedAtMs: p.deletedAtMs,
    );
    payments[paymentId] = updated;
    await addPayment(updated); // recalcul via same path
    return updated;
  }
}
