import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(dashboardControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.go('/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroCard(onNewInvoice: () => context.go('/invoices/new'), onViewPayments: () => context.go('/payments')),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(label: 'Total factures', value: s.loading ? '—' : '${s.totalInvoices}', icon: Icons.receipt_long_outlined),
                _KpiCard(label: 'En attente', value: s.loading ? '—' : '${s.pendingInvoices}', icon: Icons.schedule_outlined),
                _KpiCard(label: 'Payées', value: s.loading ? '—' : '${s.paidInvoices}', icon: Icons.verified_outlined),
                _KpiCard(label: 'Impayées', value: s.loading ? '—' : '${s.unpaidInvoices}', icon: Icons.warning_amber_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onNewInvoice;
  final VoidCallback onViewPayments;
  const _HeroCard({required this.onNewInvoice, required this.onViewPayments});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        boxShadow: const [BoxShadow(blurRadius: 24, color: Colors.black26, offset: Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Facturation empathique', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Suivez les règlements patients, imprimez les PDF et encaissez en ligne, même hors connexion.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onPrimary)),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(onPressed: onNewInvoice, icon: const Icon(Icons.add), label: const Text('Nouvelle facture')),
          const SizedBox(width: 12),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: colors.onPrimary), onPressed: onViewPayments, icon: const Icon(Icons.payments_outlined), label: const Text('Paiements récents')),
        ]),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 0,
        color: colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}
