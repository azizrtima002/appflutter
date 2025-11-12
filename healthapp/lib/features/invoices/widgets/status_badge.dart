import 'package:flutter/material.dart';
import '../../../domain/entities/invoice.dart';

class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case InvoiceStatus.payee:
        bg = colors.secondaryContainer;
        fg = colors.onSecondaryContainer;
        label = 'Payee';
        break;
      case InvoiceStatus.annulee:
        bg = colors.errorContainer;
        fg = colors.onErrorContainer;
        label = 'Annulee';
        break;
      case InvoiceStatus.brouillon:
        bg = colors.surfaceContainerHighest;
        fg = colors.onSurfaceVariant;
        label = 'Brouillon';
        break;
      case InvoiceStatus.enAttente:
        bg = colors.tertiaryContainer;
        fg = colors.onTertiaryContainer;
        label = 'En attente';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
