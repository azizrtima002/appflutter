import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'fakes/fake_repos.dart';
import 'package:health_billing/domain/entities/invoice.dart';

void main() {
  test('Filtres: en_attente fonctionne', () async {
    final invRepo = FakeInvoiceRepo();
    final inv1 = Invoice(
      id: const Uuid().v4(),
      patientId: 'p1',
      episode: 'Consultation',
      issueDateMs: 1,
      dueDateMs: 2,
      status: InvoiceStatus.enAttente,
      notes: null,
      subtotalCents: 100,
      taxCents: 19,
      discountCents: 0,
      totalCents: 119,
      amountDueCents: 119,
      qrPayUrl: null,
      createdAtMs: 1,
      updatedAtMs: 1,
      needsSync: 0,
    );
    final inv2 = Invoice(
      id: const Uuid().v4(),
      patientId: 'p2',
      episode: 'Analyse',
      issueDateMs: 1,
      dueDateMs: 2,
      status: InvoiceStatus.payee,
      notes: null,
      subtotalCents: 100,
      taxCents: 19,
      discountCents: 0,
      totalCents: 119,
      amountDueCents: 0,
      qrPayUrl: null,
      createdAtMs: 1,
      updatedAtMs: 1,
      needsSync: 0,
    );
    await invRepo.createInvoice(draft: inv1, lines: const []);
    await invRepo.createInvoice(draft: inv2, lines: const []);

    final filtered = await invRepo.listInvoices(status: InvoiceStatus.enAttente);
    expect(filtered.length, 1);
    expect(filtered.first.status, InvoiceStatus.enAttente);
  });
}

