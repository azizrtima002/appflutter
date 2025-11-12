import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/line_item.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/add_payment.dart';
import '../../../domain/usecases/cancel_invoice.dart';
import '../../../domain/usecases/delete_invoice.dart';
import '../../../domain/usecases/delete_payment.dart';
import '../../../domain/usecases/update_payment_status.dart';
import '../../../features/providers.dart';
import '../../../features/stripe/stripe_service.dart';
import '../../../data/dao/invoice_dao.dart';
import '../../../data/dao/payment_dao.dart';
import '../../../data/dao/patient_dao.dart';
import '../../pdf/pdf_service.dart';

class InvoiceDetailState {
  final bool loading;
  final Invoice? invoice;
  final List<LineItem> lines;
  final List<Payment> payments;
  final Patient? patient;
  final String? error;
  const InvoiceDetailState({
    this.loading = true,
    this.invoice,
    this.lines = const [],
    this.payments = const [],
    this.patient,
    this.error,
  });

  InvoiceDetailState copyWith({
    bool? loading,
    Invoice? invoice,
    List<LineItem>? lines,
    List<Payment>? payments,
    Patient? patient,
    String? error,
  }) =>
      InvoiceDetailState(
        loading: loading ?? this.loading,
        invoice: invoice ?? this.invoice,
        lines: lines ?? this.lines,
        payments: payments ?? this.payments,
        patient: patient ?? this.patient,
        error: error,
      );
}

class InvoiceDetailController extends StateNotifier<InvoiceDetailState> {
  final InvoiceDao invoiceDao;
  final PaymentDao paymentDao;
  final PatientDao patientDao;
  final StripeService stripeService;
  final AddPayment addPayment;
  final CancelInvoice cancelInvoice;
  final DeleteInvoice deleteInvoice;
  final UpdatePaymentStatusUseCase updatePaymentStatus;
  final PdfService pdfService;
  final DeletePayment deletePayment;

  InvoiceDetailController({
    required this.invoiceDao,
    required this.paymentDao,
    required this.patientDao,
    required this.stripeService,
    required this.addPayment,
    required this.cancelInvoice,
    required this.deleteInvoice,
    required this.updatePaymentStatus,
    required this.pdfService,
    required this.deletePayment,
  }) : super(const InvoiceDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final invModel = await invoiceDao.getById(id);
      if (invModel == null) throw const NotFoundFailure('Invoice not found');
      final paid = await paymentDao.confirmedPaymentsSum(id);
      final amountDue = (invModel.totalCents - paid).clamp(0, 1 << 31);
      final status = amountDue == 0 ? 'payee' : invModel.status;
      final inv = Invoice(
        id: invModel.id,
        patientId: invModel.patientId,
        episode: invModel.episode,
        issueDateMs: invModel.issueDate,
        dueDateMs: invModel.dueDate,
        status: switch (status) { 'payee' => InvoiceStatus.payee, 'annulee' => InvoiceStatus.annulee, 'brouillon' => InvoiceStatus.brouillon, _ => InvoiceStatus.enAttente },
        notes: invModel.notes,
        subtotalCents: invModel.subtotalCents,
        taxCents: invModel.taxCents,
        discountCents: invModel.discountCents,
        totalCents: invModel.totalCents,
        amountDueCents: amountDue,
        qrPayUrl: invModel.qrPayUrl,
        createdAtMs: invModel.createdAt,
        updatedAtMs: invModel.updatedAt,
        needsSync: invModel.needsSync,
      );
      final lineModels = await invoiceDao.getLineItems(id);
      final lines = lineModels
          .map((m) => LineItem(
                id: m.id,
                invoiceId: m.invoiceId,
                label: m.label,
                qty: m.qty,
                unitPriceCents: m.unitPriceCents,
                taxRate: m.taxRate,
                discountCents: m.discountCents,
                lineTotalCents: m.lineTotalCents,
              ))
          .toList();
      final patientModel = await patientDao.findById(invModel.patientId);
      final patient = patientModel == null
          ? null
          : Patient(
              id: patientModel.id,
              fullName: patientModel.fullName,
              dobMs: patientModel.dob,
              email: patientModel.email,
              phone: patientModel.phone,
              address: patientModel.address,
              createdAtMs: patientModel.createdAt,
            );
      final paymentModels = await paymentDao.listByInvoice(id);
      final payments = paymentModels
          .map((p) => Payment(
                id: p.id,
                invoiceId: p.invoiceId,
                amountCents: p.amountCents,
                method: switch (p.method) { 'cash' => PaymentMethod.cash, 'card' => PaymentMethod.card, 'bank' => PaymentMethod.bank, _ => PaymentMethod.stripe },
                status: switch (p.status) { 'confirme' => PaymentStatus.confirme, 'rembourse' => PaymentStatus.rembourse, _ => PaymentStatus.enAttente },
                reference: p.reference,
                createdAtMs: p.createdAt,
                deletedAtMs: p.deletedAt,
              ))
          .toList();
      state = state.copyWith(
        loading: false,
        invoice: inv,
        lines: lines,
        payments: payments,
        patient: patient,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> addLocalPayment({required int amountCents, required PaymentMethod method, String? reference}) async {
    final inv = state.invoice;
    if (inv == null) return;
    await addPayment(invoiceId: inv.id, amountCents: amountCents, method: method, reference: reference);
    await load(inv.id);
  }

  Future<void> startStripe() async {
    final inv = state.invoice;
    if (inv == null) return;
    await stripeService.startPayment(inv.id);
    await load(inv.id);
  }

  Future<void> doCancelInvoice() async {
    final inv = state.invoice;
    if (inv == null) return;
    await cancelInvoice(inv.id);
    await load(inv.id);
  }

  Future<void> deleteCurrentInvoice() async {
    final inv = state.invoice;
    if (inv == null) return;
    await deleteInvoice(inv.id);
    state = const InvoiceDetailState(loading: false);
  }

  Future<void> changePaymentStatus(String paymentId, PaymentStatus status) async {
    await updatePaymentStatus(paymentId, status);
    final inv = state.invoice;
    if (inv != null) await load(inv.id);
  }

  Future<void> printPdf() async {
    final inv = state.invoice;
    if (inv == null) return;
    await pdfService.printPdf(inv.id);
  }

  Future<void> sharePdf() async {
    final inv = state.invoice;
    if (inv == null) return;
    await pdfService.sharePdf(inv.id);
  }

  Future<void> removePayment(String paymentId) async {
    await deletePayment(paymentId);
    final inv = state.invoice;
    if (inv != null) await load(inv.id);
  }
}

final invoiceDetailControllerProvider = StateNotifierProvider.family<InvoiceDetailController, InvoiceDetailState, String>((ref, id) {
  final invoiceDao = ref.read(invoiceDaoProvider);
  final paymentDao = ref.read(paymentDaoProvider);
  final patientDao = ref.read(patientDaoProvider);
  final stripe = StripeService(invoiceDao: invoiceDao, paymentRepo: ref.read(paymentRepositoryProvider));
  return InvoiceDetailController(
    invoiceDao: invoiceDao,
    paymentDao: paymentDao,
    patientDao: patientDao,
    stripeService: stripe,
    addPayment: AddPayment(ref.read(paymentRepositoryProvider)),
    cancelInvoice: CancelInvoice(ref.read(invoiceRepositoryProvider)),
    deleteInvoice: DeleteInvoice(ref.read(invoiceRepositoryProvider)),
    updatePaymentStatus: UpdatePaymentStatusUseCase(ref.read(paymentRepositoryProvider)),
    pdfService: ref.read(pdfServiceProvider),
    deletePayment: DeletePayment(ref.read(paymentRepositoryProvider)),
  )..load(id);
});
