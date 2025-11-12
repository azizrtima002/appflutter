import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/payment_model.dart';
import 'package:intl/intl.dart';
import '../../providers.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  String? _method;
  String? _status;
  List<PaymentModel> _rows = const <PaymentModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final dao = ref.read(paymentDaoProvider);
    final rows = await dao.list(method: _method, status: _status);
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique paiements')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: ChoiceChip(
                label: Text(_method == null ? 'Toutes méthodes' : _method!.toUpperCase()),
                selected: _method != null,
                avatar: const Icon(Icons.payments_outlined, size: 18),
                onSelected: (_) => _showMethodPicker(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: Text(_status == null ? 'Tous statuts' : _status!.replaceAll('_', ' ')),
                selected: _status != null,
                avatar: const Icon(Icons.filter_list, size: 18),
                onSelected: (_) => _showStatusPicker(context),
              ),
            ),
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    final amount = r.amountCents / 100;
                    final icon = switch (r.method) {
                      'card' => Icons.credit_card,
                      'bank' => Icons.account_balance,
                      'stripe' => Icons.online_prediction,
                      _ => Icons.payments_outlined,
                    };
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(icon)),
                        title: Text('${amount.toStringAsFixed(2)} TND'),
                        subtitle: Text('${r.method} • ${DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(r.createdAt))}'),
                        trailing: Chip(label: Text(r.status)),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _showMethodPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Méthode',
        options: const [
          ('cash', 'Espèces'),
          ('card', 'Carte'),
          ('bank', 'Virement'),
          ('stripe', 'Stripe'),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _method = selected);
      _refresh();
    }
  }

  void _showStatusPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _PickerSheet(
        title: 'Statut',
        options: const [
          ('en_attente', 'En attente'),
          ('confirme', 'Confirmé'),
          ('rembourse', 'Remboursé'),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _status = selected);
      _refresh();
    }
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  const _PickerSheet({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...options.map((opt) => ListTile(
                title: Text(opt.$2),
                onTap: () => Navigator.pop(context, opt.$1),
              )),
        ],
      ),
    );
  }
}
