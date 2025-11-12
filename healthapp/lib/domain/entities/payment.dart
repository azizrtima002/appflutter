enum PaymentMethod { cash, card, bank, stripe }
enum PaymentStatus { enAttente, confirme, rembourse }

class Payment {
  final String id;
  final String invoiceId;
  final int amountCents;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final int createdAtMs;
  final int? deletedAtMs; // soft delete

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amountCents,
    required this.method,
    required this.status,
    required this.createdAtMs,
    this.reference,
    this.deletedAtMs,
  });
}

