import 'package:uuid/uuid.dart';
import '../entities/invoice.dart';
import '../entities/line_item.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoice {
  final InvoiceRepository repo;
  CreateInvoice(this.repo);

  Future<Invoice> call({
    required String patientId,
    String? episode,
    required int issueDateMs,
    required int dueDateMs,
    String? notes,
    required List<LineItem> lines,
  }) async {
    // Calculate subtotal, tax, total
    int subtotal = 0;
    int tax = 0;
    for (final li in lines) {
      final base = (li.qty * li.unitPriceCents).round() - li.discountCents;
      final t = ((base * li.taxRate) / 100).round();
      subtotal += base;
      tax += t;
    }
    final total = subtotal + tax;
    final draft = Invoice(
      id: const Uuid().v4(),
      patientId: patientId,
      episode: episode,
      issueDateMs: issueDateMs,
      dueDateMs: dueDateMs,
      status: InvoiceStatus.enAttente,
      notes: notes,
      subtotalCents: subtotal,
      taxCents: tax,
      discountCents: 0,
      totalCents: total,
      amountDueCents: total,
      qrPayUrl: null,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      needsSync: 0,
    );
    return repo.createInvoice(draft: draft, lines: lines);
  }
}

