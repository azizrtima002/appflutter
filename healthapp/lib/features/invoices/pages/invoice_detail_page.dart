import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/line_item.dart';
import '../../../domain/entities/patient.dart';
import '../../../domain/entities/payment.dart';
import '../controllers/invoice_detail_controller.dart';
import '../widgets/status_badge.dart';

class InvoiceDetailPage extends ConsumerWidget {
  final String id;
  const InvoiceDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceDetailControllerProvider(id));
    final controller = ref.read(invoiceDetailControllerProvider(id).notifier);
    final invoice = state.invoice;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(invoice != null ? 'Facture #${_shortId(invoice.id)}' : 'Facture'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resume'),
              Tab(text: 'Lignes'),
              Tab(text: 'Paiements'),
              Tab(text: 'Historique'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Exporter PDF',
              onPressed: invoice == null ? null : () => _showPdfOptions(context, controller),
              icon: const Icon(Icons.picture_as_pdf),
            ),
            IconButton(
              tooltip: 'Encaisser en ligne',
              onPressed: invoice == null ? null : () => _startStripe(context, controller),
              icon: const Icon(Icons.payment),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenu(context, value, id, invoice, controller),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editer')),
                PopupMenuItem(value: 'cancel', child: Text('Annuler')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                PopupMenuItem(value: 'refresh', child: Text('Actualiser')),
              ],
            ),
          ],
        ),
        floatingActionButton: invoice == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showAddPaymentSheet(context, controller, invoice),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: const Text('Paiement'),
                icon: const Icon(Icons.add),
              ),
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && invoice == null
                ? _ErrorState(message: state.error!, onRetry: () => controller.load(id))
                : TabBarView(
                    children: [
                      _SummaryTab(
                        invoice: invoice!,
                        patient: state.patient,
                        lines: state.lines,
                        errorMessage: state.error,
                        onRefresh: () => controller.load(invoice.id),
                      ),
                      _LinesTab(lines: state.lines),
                      _PaymentsTab(
                        payments: state.payments,
                        onChangeStatus: (payment, status) => _changePaymentStatus(context, controller, payment, status),
                        onDelete: (payment) => _deletePayment(context, controller, payment),
                      ),
                      _HistoryTab(invoice: invoice, payments: state.payments),
                    ],
                  ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final Invoice invoice;
  final Patient? patient;
  final List<LineItem> lines;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  const _SummaryTab({
    required this.invoice,
    required this.patient,
    required this.lines,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (errorMessage != null)
            _ErrorBanner(
              message: errorMessage!,
              onRetry: onRefresh,
            ),
          _SummaryCard(invoice: invoice, patient: patient),
          const SizedBox(height: 12),
          _TotalsCard(invoice: invoice),
          const SizedBox(height: 12),
          _LinesPreview(lines: lines),
          const SizedBox(height: 12),
          _NotesCard(notes: invoice.notes),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Invoice invoice;
  final Patient? patient;
  const _SummaryCard({required this.invoice, required this.patient});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.health_and_safety,
              size: 96,
              color: colors.onPrimary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(status: invoice.status),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(invoice.totalCents),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Reste ${_money(invoice.amountDueCents)}', style: TextStyle(color: colors.onSecondaryContainer)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Patient',
                value: patient?.fullName ?? invoice.patientId,
                color: colors.onPrimary,
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Emise le',
                value: _formatDate(invoice.issueDateMs),
                color: colors.onPrimary,
              ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Echeance',
                value: _formatDate(invoice.dueDateMs),
                color: colors.onPrimary,
              ),
              if ((invoice.episode ?? '').isNotEmpty)
                _InfoRow(
                  icon: Icons.local_hospital_outlined,
                  label: 'Episode',
                  value: invoice.episode!,
                  color: colors.onPrimary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _InfoRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelSmall?.copyWith(color: color)),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final Invoice invoice;
  const _TotalsCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details montant', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _TotalRow(label: 'Sous-total (HT)', value: _money(invoice.subtotalCents)),
            _TotalRow(label: 'TVA', value: _money(invoice.taxCents)),
            if (invoice.discountCents > 0) _TotalRow(label: 'Remise', value: _money(invoice.discountCents)),
            const Divider(height: 24),
            _TotalRow(label: 'Total (TTC)', value: _money(invoice.totalCents), emphasize: true),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _TotalRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: emphasize ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}

class _LinesPreview extends StatelessWidget {
  final List<LineItem> lines;
  const _LinesPreview({required this.lines});

  @override
  Widget build(BuildContext context) {
    final preview = lines.take(3).toList();
    if (preview.isEmpty) {
      return _EmptyCard(
        icon: Icons.list_alt_outlined,
        title: 'Aucune ligne',
        subtitle: 'Ajoutez des actes ou modifiez la facture pour saisir les lignes.',
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lignes (apercu)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...preview.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(line.label)),
                    Text(_money(line.lineTotalCents), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            if (lines.length > preview.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${lines.length - preview.length} lignes supplementaires', style: Theme.of(context).textTheme.labelSmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String? notes;
  const _NotesCard({this.notes});

  @override
  Widget build(BuildContext context) {
    final hasNotes = (notes ?? '').trim().isNotEmpty;
    if (!hasNotes) {
      return _EmptyCard(
        icon: Icons.note_alt_outlined,
        title: 'Aucune note',
        subtitle: 'Ajoutez des instructions ou des notes patient depuis le formulaire de facture.',
      );
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes facture', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(notes!.trim()),
          ],
        ),
      ),
    );
  }
}

class _LinesTab extends StatelessWidget {
  final List<LineItem> lines;
  const _LinesTab({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.list_alt_outlined,
        title: 'Aucune ligne enregistree',
        subtitle: 'Modifiez la facture pour ajouter des actes ou prestations.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final line = lines[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: CircleAvatar(child: Text('${line.qty.toStringAsFixed(0)}x')),
            title: Text(line.label),
            subtitle: Text('PU ${_money(line.unitPriceCents)} - TVA ${line.taxRate.toStringAsFixed(1)}%'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(line.lineTotalCents), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (line.discountCents > 0) Text('Remise ${_money(line.discountCents)}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final Future<void> Function(Payment payment, PaymentStatus status) onChangeStatus;
  final Future<void> Function(Payment payment) onDelete;
  const _PaymentsTab({
    required this.payments,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.payments_outlined,
        title: 'Aucun paiement',
        subtitle: 'Utilisez le bouton vert pour ajouter un reglement ou encaissez via Stripe.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: CircleAvatar(child: Icon(_methodIcon(payment.method))),
            title: Text(_money(payment.amountCents), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${_methodLabel(payment.method)} - ${_formatDateTime(payment.createdAtMs)}'
              '${payment.reference == null ? '' : '\nRef: ${payment.reference}'}',
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(_statusLabel(payment.status)),
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Actions paiement',
                  onSelected: (value) {
                    switch (value) {
                      case 'confirm':
                        onChangeStatus(payment, PaymentStatus.confirme);
                        break;
                      case 'pending':
                        onChangeStatus(payment, PaymentStatus.enAttente);
                        break;
                      case 'refund':
                        onChangeStatus(payment, PaymentStatus.rembourse);
                        break;
                      case 'delete':
                        onDelete(payment);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'confirm', child: Text('Marquer confirme')),
                    PopupMenuItem(value: 'pending', child: Text('Marquer en attente')),
                    PopupMenuItem(value: 'refund', child: Text('Marquer rembourse')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final Invoice invoice;
  final List<Payment> payments;
  const _HistoryTab({required this.invoice, required this.payments});

  @override
  Widget build(BuildContext context) {
    final events = _buildHistory(invoice, payments);
    if (events.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.history,
        title: 'Aucun evenement',
        subtitle: 'Les modifications apparaitront ici automatiquement.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: CircleAvatar(child: Icon(event.icon)),
            title: Text(event.title),
            subtitle: Text(event.subtitle),
            trailing: Text(_formatDateTime(event.timestamp)),
          ),
        );
      },
    );
  }
}

class _HistoryEvent {
  final String title;
  final String subtitle;
  final int timestamp;
  final IconData icon;
  const _HistoryEvent({required this.title, required this.subtitle, required this.timestamp, required this.icon});
}

List<_HistoryEvent> _buildHistory(Invoice invoice, List<Payment> payments) {
  final events = <_HistoryEvent>[
    _HistoryEvent(
      title: 'Facture creee',
      subtitle: 'ID ${_shortId(invoice.id)}',
      timestamp: invoice.createdAtMs,
      icon: Icons.receipt_long_outlined,
    ),
    _HistoryEvent(
      title: 'Emission',
      subtitle: 'Total ${_money(invoice.totalCents)}',
      timestamp: invoice.issueDateMs,
      icon: Icons.event_available,
    ),
  ];
  for (final payment in payments) {
    events.add(
      _HistoryEvent(
        title: 'Paiement ${_statusLabel(payment.status)}',
        subtitle: '${_methodLabel(payment.method)} ${_money(payment.amountCents)}',
        timestamp: payment.createdAtMs,
        icon: Icons.payments_outlined,
      ),
    );
  }
  if (invoice.status == InvoiceStatus.annulee) {
    events.add(
      _HistoryEvent(
        title: 'Facture annulee',
        subtitle: 'Statut final',
        timestamp: invoice.updatedAtMs,
        icon: Icons.cancel_outlined,
      ),
    );
  } else if (invoice.amountDueCents == 0) {
    events.add(
      _HistoryEvent(
        title: 'Facture soldee',
        subtitle: 'Total regle',
        timestamp: invoice.updatedAtMs,
        icon: Icons.verified_outlined,
      ),
    );
  }
  events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return events;
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CenteredMessage({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colors.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: colors.onErrorContainer))),
          TextButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reessayer')),
        ],
      ),
    );
  }
}

Future<void> _showPdfOptions(BuildContext context, InvoiceDetailController controller) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Exporter PDF'),
            subtitle: Text('Imprimez ou partagez la facture'),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Imprimer'),
            onTap: () => Navigator.pop(ctx, 'print'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Partager'),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
        ],
      ),
    ),
  );
  if (action == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (action == 'print') {
      await controller.printPdf();
      messenger.showSnackBar(const SnackBar(content: Text('PDF envoye a limprimante')));
    } else {
      await controller.sharePdf();
      messenger.showSnackBar(const SnackBar(content: Text('PDF partage')));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
  }
}

Future<void> _startStripe(BuildContext context, InvoiceDetailController controller) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await controller.startStripe();
    messenger.showSnackBar(const SnackBar(content: Text('Paiement Stripe initialise')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur Stripe: $e')));
  }
}

Future<void> _handleMenu(
  BuildContext context,
  String value,
  String pageId,
  Invoice? invoice,
  InvoiceDetailController controller,
) async {
  switch (value) {
    case 'edit':
      if (invoice != null) context.go('/invoices/${invoice.id}/edit');
      break;
    case 'cancel':
      if (invoice == null) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Annuler la facture'),
          content: const Text('Cette action marque la facture comme annulee. Continuer ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
          ],
        ),
      );
      if (confirm == true) {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await controller.doCancelInvoice();
          messenger.showSnackBar(const SnackBar(content: Text('Facture annulee')));
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
      break;
    case 'delete':
      await _deleteInvoice(context, controller);
      break;
    case 'refresh':
      await controller.load(invoice?.id ?? pageId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facture actualisee')));
      break;
  }
}

Future<void> _showAddPaymentSheet(
  BuildContext context,
  InvoiceDetailController controller,
  Invoice invoice,
) async {
  final result = await _AddPaymentSheet.show(context, invoice.amountDueCents);
  if (result == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await controller.addLocalPayment(
      amountCents: result.amountCents,
      method: result.method,
      reference: result.reference,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Paiement ajoute')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur paiement: $e')));
  }
}

Future<void> _changePaymentStatus(
  BuildContext context,
  InvoiceDetailController controller,
  Payment payment,
  PaymentStatus status,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await controller.changePaymentStatus(payment.id, status);
    messenger.showSnackBar(const SnackBar(content: Text('Paiement mis a jour')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur statut: $e')));
  }
}

Future<void> _deletePayment(
  BuildContext context,
  InvoiceDetailController controller,
  Payment payment,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer le paiement'),
      content: Text('Supprimer ${_money(payment.amountCents)} ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
      ],
    ),
  );
  if (confirm != true) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await controller.removePayment(payment.id);
    messenger.showSnackBar(const SnackBar(content: Text('Paiement supprime')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
  }
}

Future<void> _deleteInvoice(
  BuildContext context,
  InvoiceDetailController controller,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer la facture'),
      content: const Text('Cette action efface definitivement la facture et ses paiements. Continuer ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
      ],
    ),
  );
  if (confirm != true) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await controller.deleteCurrentInvoice();
    messenger.showSnackBar(const SnackBar(content: Text('Facture supprimee')));
    if (Navigator.canPop(context)) {
      context.pop();
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
  }
}

class _AddPaymentResult {
  final int amountCents;
  final PaymentMethod method;
  final String? reference;
  const _AddPaymentResult({required this.amountCents, required this.method, this.reference});
}

class _AddPaymentSheet extends StatefulWidget {
  final int initialAmountCents;
  const _AddPaymentSheet({required this.initialAmountCents});

  static Future<_AddPaymentResult?> show(BuildContext context, int initialAmountCents) {
    return showModalBottomSheet<_AddPaymentResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddPaymentSheet(initialAmountCents: initialAmountCents),
      ),
    );
  }

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _refCtrl;
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _formatAmountInput(widget.initialAmountCents));
    _refCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ajouter un paiement', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Montant (TND)'),
                  validator: (value) {
                    final cents = _parseAmount(value);
                    if (cents == null || cents <= 0) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Methode', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: PaymentMethod.values
                      .map(
                        (method) => ChoiceChip(
                          label: Text(_methodLabel(method)),
                          selected: method == _method,
                          onSelected: (_) => setState(() => _method = method),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(labelText: 'Reference (optionnel)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Ajouter'),
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      final cents = _parseAmount(_amountCtrl.text)!;
                      final reference = _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim();
                      Navigator.pop(
                        context,
                        _AddPaymentResult(amountCents: cents, method: _method, reference: reference),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatAmountInput(int cents) => (cents <= 0 ? 0 : cents / 100).toStringAsFixed(2);

int? _parseAmount(String? input) {
  final sanitized = input?.replaceAll(',', '.');
  if (sanitized == null) return null;
  final value = double.tryParse(sanitized);
  if (value == null) return null;
  return (value * 100).round();
}

String _shortId(String value) => value.length <= 8 ? value : value.substring(0, 8);

String _money(int cents) => 'TND ${(cents / 100).toStringAsFixed(2)}';

String _formatDate(int ms) => DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(ms));

String _formatDateTime(int ms) => DateFormat('dd MMM yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(ms));

String _methodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.cash => 'Especes',
      PaymentMethod.card => 'Carte',
      PaymentMethod.bank => 'Virement',
      PaymentMethod.stripe => 'Stripe',
    };

IconData _methodIcon(PaymentMethod method) => switch (method) {
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.bank => Icons.account_balance,
      PaymentMethod.stripe => Icons.online_prediction,
      PaymentMethod.cash => Icons.payments_outlined,
    };

String _statusLabel(PaymentStatus status) => switch (status) {
      PaymentStatus.enAttente => 'En attente',
      PaymentStatus.confirme => 'Confirme',
      PaymentStatus.rembourse => 'Rembourse',
    };
