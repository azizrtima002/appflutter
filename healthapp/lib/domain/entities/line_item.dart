class LineItem {
  final String id;
  final String invoiceId;
  final String label;
  final double qty;
  final int unitPriceCents;
  final double taxRate;
  final int discountCents;
  final int lineTotalCents; // stored after calc

  const LineItem({
    required this.id,
    required this.invoiceId,
    required this.label,
    required this.qty,
    required this.unitPriceCents,
    required this.taxRate,
    required this.discountCents,
    required this.lineTotalCents,
  });
}

