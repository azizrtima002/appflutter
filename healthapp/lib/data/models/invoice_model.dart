class InvoiceModel {
  final String id;
  final String patientId;
  final String? episode;
  final int issueDate;
  final int dueDate;
  final String status;
  final String? notes;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final int amountDueCents;
  final String? qrPayUrl;
  final int createdAt;
  final int updatedAt;
  final int needsSync;

  const InvoiceModel({
    required this.id,
    required this.patientId,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.amountDueCents,
    required this.createdAt,
    required this.updatedAt,
    this.episode,
    this.notes,
    this.qrPayUrl,
    this.needsSync = 0,
  });

  factory InvoiceModel.fromMap(Map<String, Object?> m) => InvoiceModel(
        id: m['id'] as String,
        patientId: m['patient_id'] as String,
        episode: m['episode'] as String?,
        issueDate: m['issue_date'] as int,
        dueDate: m['due_date'] as int,
        status: m['status'] as String,
        notes: m['notes'] as String?,
        subtotalCents: m['subtotal_cents'] as int,
        taxCents: m['tax_cents'] as int,
        discountCents: m['discount_cents'] as int,
        totalCents: m['total_cents'] as int,
        amountDueCents: m['amount_due_cents'] as int,
        qrPayUrl: m['qr_pay_url'] as String?,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
        needsSync: (m['needs_sync'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'patient_id': patientId,
        'episode': episode,
        'issue_date': issueDate,
        'due_date': dueDate,
        'status': status,
        'notes': notes,
        'subtotal_cents': subtotalCents,
        'tax_cents': taxCents,
        'discount_cents': discountCents,
        'total_cents': totalCents,
        'amount_due_cents': amountDueCents,
        'qr_pay_url': qrPayUrl,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'needs_sync': needsSync,
      };
}

