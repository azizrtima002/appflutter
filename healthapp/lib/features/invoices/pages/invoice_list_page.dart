import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/invoice.dart';
import '../controllers/invoice_list_controller.dart';
import '../widgets/status_badge.dart';

class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({super.key});

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(invoiceListControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Factures')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/invoices/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: 'Recherche patient, numero...',
              leading: const Icon(Icons.search),
              onChanged: (v) => ref.read(invoiceListControllerProvider.notifier).setQuery(v),
              onSubmitted: (_) => ref.read(invoiceListControllerProvider.notifier).refresh(),
            ),
          ),
          Wrap(spacing: 8, children: [
            FilterChip(
              label: const Text('Tous'),
              selected: state.status == null,
              onSelected: (_) {
                ref.read(invoiceListControllerProvider.notifier).setStatus(null);
                ref.read(invoiceListControllerProvider.notifier).refresh();
              },
            ),
            FilterChip(
              label: const Text('En attente'),
              selected: state.status == InvoiceStatus.enAttente,
              onSelected: (_) {
                ref.read(invoiceListControllerProvider.notifier).setStatus(InvoiceStatus.enAttente);
                ref.read(invoiceListControllerProvider.notifier).refresh();
              },
            ),
            FilterChip(
              label: const Text('Payees'),
              selected: state.status == InvoiceStatus.payee,
              onSelected: (_) {
                ref.read(invoiceListControllerProvider.notifier).setStatus(InvoiceStatus.payee);
                ref.read(invoiceListControllerProvider.notifier).refresh();
              },
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(invoiceListControllerProvider.notifier).refresh(),
              child: state.items.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      _EmptyState(),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final inv = state.items[i];
                        final due = inv.amountDueCents / 100;
                        final dueDate = DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(inv.dueDateMs));
                        return GestureDetector(
                          onTap: () => context.go('/invoices/${inv.id}'),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Facture #${_shortId(inv.id)}', style: Theme.of(context).textTheme.titleMedium)),
                                    StatusBadge(status: inv.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${(inv.totalCents / 100).toStringAsFixed(2)} TND', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Reste du ${due.toStringAsFixed(2)} TND • Echeance $dueDate', style: Theme.of(context).textTheme.bodySmall),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 72, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Text('Aucune facture', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Creez votre premiere facture pour suivre les reglements patients.', textAlign: TextAlign.center),
      ],
    );
  }
}

String _shortId(String value) => value.length <= 8 ? value : value.substring(0, 8);
