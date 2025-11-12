import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'fakes/fake_repos.dart';
import 'package:health_billing/domain/entities/invoice.dart';
import 'package:health_billing/domain/entities/payment.dart';

void main() {
  test('Suppression soft paiement — recalcul amount_due', () async {
    final invRepo = FakeInvoiceRepo();
    final payRepo = FakePaymentRepo(invRepo);
    final inv = Invoice(
      id: const Uuid().v4(),
      patientId: 'p1',
      episode: 'Consultation',
      issueDateMs: DateTime.now().millisecondsSinceEpoch,
      dueDateMs: DateTime.now().millisecondsSinceEpoch + 86400000,
      status: InvoiceStatus.enAttente,
      notes: null,
      subtotalCents: 10000,
      taxCents: 1900,
      discountCents: 0,
      totalCents: 11900,
      amountDueCents: 11900,
      qrPayUrl: null,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      needsSync: 0,
    );
    await invRepo.createInvoice(draft: inv, lines: const []);
    final p1 = Payment(
      id: const Uuid().v4(),
      invoiceId: inv.id,
      amountCents: 5000,
      method: PaymentMethod.cash,
      status: PaymentStatus.confirme,
      reference: 'R1',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await payRepo.addPayment(p1);
    final p2 = Payment(
      id: const Uuid().v4(),
      invoiceId: inv.id,
      amountCents: 6900,
      method: PaymentMethod.bank,
      status: PaymentStatus.confirme,
      reference: 'R2',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await payRepo.addPayment(p2);
    var invAfterFull = await invRepo.getInvoiceDetails(inv.id);
    expect(invAfterFull.amountDueCents, 0);

    await payRepo.deletePaymentSoft(p2.id);
    invAfterFull = await invRepo.getInvoiceDetails(inv.id);
    expect(invAfterFull.amountDueCents, 11900 - 5000);
    expect(invAfterFull.status, InvoiceStatus.enAttente);
  });
}

