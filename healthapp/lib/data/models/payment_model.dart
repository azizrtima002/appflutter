class PaymentModel {
  final String id;
  final String invoiceId;
  final int amountCents;
  final String method;
  final String status;
  final String? reference;
  final int createdAt;
  final int? deletedAt;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amountCents,
    required this.method,
    required this.status,
    required this.createdAt,
    this.reference,
    this.deletedAt,
  });

  factory PaymentModel.fromMap(Map<String, Object?> m) => PaymentModel(
        id: m['id'] as String,
        invoiceId: m['invoice_id'] as String,
        amountCents: m['amount_cents'] as int,
        method: m['method'] as String,
        status: m['status'] as String,
        reference: m['reference'] as String?,
        createdAt: m['created_at'] as int,
        deletedAt: m['deleted_at'] as int?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'amount_cents': amountCents,
        'method': method,
        'status': status,
        'reference': reference,
        'created_at': createdAt,
        'deleted_at': deletedAt,
      };
}

