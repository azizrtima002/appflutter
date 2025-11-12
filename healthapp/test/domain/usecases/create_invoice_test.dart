import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'fakes/fake_repos.dart';
import 'package:health_billing/domain/usecases/create_invoice.dart';
import 'package:health_billing/domain/entities/line_item.dart';
import 'package:health_billing/domain/entities/invoice.dart';

void main() {
  test('Création facture calcule totaux et reste dû', () async {
    final repo = FakeInvoiceRepo();
    final usecase = CreateInvoice(repo);
    final now = DateTime.now().millisecondsSinceEpoch;
    final lines = [
      LineItem(
        id: const Uuid().v4(),
        invoiceId: 'temp',
        label: 'Consultation',
        qty: 1,
        unitPriceCents: 10000,
        taxRate: 19.0,
        discountCents: 0,
        lineTotalCents: 11900,
      ),
      LineItem(
        id: const Uuid().v4(),
        invoiceId: 'temp',
        label: 'Analyse',
        qty: 2,
        unitPriceCents: 5000,
        taxRate: 19.0,
        discountCents: 0,
        lineTotalCents: 11900,
      ),
    ];

    final inv = await usecase(
      patientId: 'p1',
      issueDateMs: now,
      dueDateMs: now + 86400000,
      lines: lines,
    );

    expect(inv.subtotalCents, 10000 + 10000);
    expect(inv.taxCents, 1900 + 1900);
    expect(inv.totalCents, 10000 + 10000 + 3800);
    expect(inv.amountDueCents, inv.totalCents);
    expect(inv.status, InvoiceStatus.enAttente);
  });
}

