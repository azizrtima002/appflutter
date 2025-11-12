enum InvoiceStatus { brouillon, enAttente, payee, annulee }

class Invoice {
  final String id;
  final String patientId;
  final String? episode;
  final int issueDateMs;
  final int dueDateMs;
  final InvoiceStatus status;
  final String? notes;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final int amountDueCents;
  final String? qrPayUrl;
  final int createdAtMs;
  final int updatedAtMs;
  final int needsSync; // 0/1

  const Invoice({
    required this.id,
    required this.patientId,
    required this.issueDateMs,
    required this.dueDateMs,
    required this.status,
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.amountDueCents,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.episode,
    this.notes,
    this.qrPayUrl,
    this.needsSync = 0,
  });

  bool get isPaid => amountDueCents == 0 && status == InvoiceStatus.payee;
}

