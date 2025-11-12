class LineItemModel {
  final String id;
  final String invoiceId;
  final String label;
  final double qty;
  final int unitPriceCents;
  final double taxRate;
  final int discountCents;
  final int lineTotalCents;

  const LineItemModel({
    required this.id,
    required this.invoiceId,
    required this.label,
    required this.qty,
    required this.unitPriceCents,
    required this.taxRate,
    required this.discountCents,
    required this.lineTotalCents,
  });

  factory LineItemModel.fromMap(Map<String, Object?> m) => LineItemModel(
        id: m['id'] as String,
        invoiceId: m['invoice_id'] as String,
        label: m['label'] as String,
        qty: (m['qty'] as num).toDouble(),
        unitPriceCents: m['unit_price_cents'] as int,
        taxRate: (m['tax_rate'] as num).toDouble(),
        discountCents: m['discount_cents'] as int,
        lineTotalCents: m['line_total_cents'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'label': label,
        'qty': qty,
        'unit_price_cents': unitPriceCents,
        'tax_rate': taxRate,
        'discount_cents': discountCents,
        'line_total_cents': lineTotalCents,
      };
}

