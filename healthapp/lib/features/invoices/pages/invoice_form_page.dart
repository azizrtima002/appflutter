import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/line_item.dart';
import '../../../domain/usecases/create_invoice.dart';
import '../../../domain/usecases/update_invoice.dart';
import '../../providers.dart';

class InvoiceFormPage extends ConsumerStatefulWidget {
  final String? invoiceId;
  const InvoiceFormPage({super.key, this.invoiceId});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientCtrl = TextEditingController(text: 'p1');
  final _episodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;
  bool _saving = false;
  Invoice? _editingInvoice;
  final List<_LineForm> _lines = [];

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId == null) {
      _lines.add(_LineForm());
    } else {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final dao = ref.read(invoiceDaoProvider);
    final inv = await dao.getById(widget.invoiceId!);
    final lines = await dao.getLineItems(widget.invoiceId!);
    if (inv != null) {
      _editingInvoice = Invoice(
        id: inv.id,
        patientId: inv.patientId,
        episode: inv.episode,
        issueDateMs: inv.issueDate,
        dueDateMs: inv.dueDate,
        status: switch (inv.status) {
          'payee' => InvoiceStatus.payee,
          'annulee' => InvoiceStatus.annulee,
          'brouillon' => InvoiceStatus.brouillon,
          _ => InvoiceStatus.enAttente
        },
        notes: inv.notes,
        subtotalCents: inv.subtotalCents,
        taxCents: inv.taxCents,
        discountCents: inv.discountCents,
        totalCents: inv.totalCents,
        amountDueCents: inv.amountDueCents,
        qrPayUrl: inv.qrPayUrl,
        createdAtMs: inv.createdAt,
        updatedAtMs: inv.updatedAt,
        needsSync: inv.needsSync,
      );
      _patientCtrl.text = inv.patientId;
      _episodeCtrl.text = inv.episode ?? '';
      _notesCtrl.text = inv.notes ?? '';
      _issueDate = DateTime.fromMillisecondsSinceEpoch(inv.issueDate);
      _dueDate = DateTime.fromMillisecondsSinceEpoch(inv.dueDate);
      _lines
        ..clear()
        ..addAll(lines
            .map((l) => _LineForm(
                  lineId: l.id,
                  label: l.label,
                  qty: l.qty.toString(),
                  unitPrice: l.unitPriceCents.toString(),
                  tax: l.taxRate.toString(),
                  discount: l.discountCents.toString(),
                )));
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _patientCtrl.dispose();
    _episodeCtrl.dispose();
    _notesCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headline = widget.invoiceId == null ? 'Nouvelle facture' : 'Modifier la facture';
    return Scaffold(
      appBar: AppBar(
        title: Text(headline),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _saving ? null : _handleSubmit,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoBanner(editing: widget.invoiceId != null),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientCtrl,
                    decoration: const InputDecoration(labelText: 'Patient ID'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _episodeCtrl,
                    decoration: const InputDecoration(labelText: 'Episode / Acte'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _DateField(label: 'Emission', date: _issueDate, onTap: () => _pickDate(isIssue: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _DateField(label: 'Echeance', date: _dueDate, onTap: () => _pickDate(isIssue: false))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Lignes de facturation', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._lines.asMap().entries.map((entry) => _LineCard(
                        index: entry.key,
                        line: entry.value,
                        onRemove: _lines.length == 1 ? null : () => setState(() => _lines.removeAt(entry.key)),
                      )),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _lines.add(_LineForm());
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Ajouter une ligne'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes patient'),
                  ),
                  const SizedBox(height: 24),
                  _SummaryPreview(lines: _lines),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _handleSubmit,
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                    label: Text(widget.invoiceId == null ? 'Créer la facture' : 'Mettre à jour'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate({required bool isIssue}) async {
    final initial = isIssue ? _issueDate : _dueDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) {
      setState(() {
        if (isIssue) {
          _issueDate = result;
          if (_dueDate.isBefore(result)) {
            _dueDate = result.add(const Duration(days: 7));
          }
        } else {
          _dueDate = result;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une ligne.')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(invoiceRepositoryProvider);
    final create = CreateInvoice(repo);
    final update = UpdateInvoice(repo);
    final paymentDao = ref.read(paymentDaoProvider);

    final lineEntities = _lines.map((line) => line.toEntity(widget.invoiceId)).toList();
    final totals = _computeTotals(lineEntities);

    try {
      if (widget.invoiceId == null) {
        await create(
          patientId: _patientCtrl.text.trim(),
          episode: _episodeCtrl.text.trim().isEmpty ? null : _episodeCtrl.text.trim(),
          issueDateMs: _issueDate.millisecondsSinceEpoch,
          dueDateMs: _dueDate.millisecondsSinceEpoch,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          lines: lineEntities,
        );
        if (!mounted) return;
        context.go('/invoices');
      } else {
        final paid = await paymentDao.confirmedPaymentsSum(widget.invoiceId!);
        final amountDue = (totals.total - paid).clamp(0, 1 << 31);
        final status = amountDue == 0 ? InvoiceStatus.payee : InvoiceStatus.enAttente;
        final base = _editingInvoice;
        final invoice = Invoice(
          id: widget.invoiceId!,
          patientId: _patientCtrl.text.trim(),
          episode: _episodeCtrl.text.trim().isEmpty ? null : _episodeCtrl.text.trim(),
          issueDateMs: _issueDate.millisecondsSinceEpoch,
          dueDateMs: _dueDate.millisecondsSinceEpoch,
          status: status,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          subtotalCents: totals.subtotal,
          taxCents: totals.tax,
          discountCents: 0,
          totalCents: totals.total,
          amountDueCents: amountDue,
          qrPayUrl: base?.qrPayUrl,
          createdAtMs: base?.createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          needsSync: 1,
        );
        await update(invoice, lines: lineEntities);
        if (!mounted) return;
        context.go('/invoices/${widget.invoiceId}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  _Totals _computeTotals(List<LineItem> lines) {
    int subtotal = 0;
    int tax = 0;
    for (final line in lines) {
      final base = (line.qty * line.unitPriceCents).round() - line.discountCents;
      final t = ((base * line.taxRate) / 100).round();
      subtotal += base;
      tax += t;
    }
    return _Totals(subtotal, tax, subtotal + tax);
  }
}

class _LineForm {
  final String? lineId;
  final TextEditingController labelCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  final TextEditingController taxCtrl;
  final TextEditingController discountCtrl;

  _LineForm({
    this.lineId,
    String label = '',
    String qty = '1',
    String unitPrice = '0',
    String tax = '19',
    String discount = '0',
  })  : labelCtrl = TextEditingController(text: label),
        qtyCtrl = TextEditingController(text: qty),
        unitCtrl = TextEditingController(text: unitPrice),
        taxCtrl = TextEditingController(text: tax),
        discountCtrl = TextEditingController(text: discount);

  LineItem toEntity(String? invoiceId) {
    final qty = double.tryParse(qtyCtrl.text) ?? 1;
    final unit = int.tryParse(unitCtrl.text) ?? 0;
    final tax = double.tryParse(taxCtrl.text) ?? 0;
    final discount = int.tryParse(discountCtrl.text) ?? 0;
    final base = (qty * unit).round() - discount;
    final taxAmount = ((base * tax) / 100).round();
    return LineItem(
      id: lineId ?? const Uuid().v4(),
      invoiceId: invoiceId ?? 'temp',
      label: labelCtrl.text.trim(),
      qty: qty,
      unitPriceCents: unit,
      taxRate: tax,
      discountCents: discount,
      lineTotalCents: base + taxAmount,
    );
  }

  void dispose() {
    labelCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    taxCtrl.dispose();
    discountCtrl.dispose();
  }
}

class _LineCard extends StatelessWidget {
  final int index;
  final _LineForm line;
  final VoidCallback? onRemove;
  const _LineCard({required this.index, required this.line, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Ligne ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: line.labelCtrl,
              decoration: const InputDecoration(labelText: 'Libellé'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.unitCtrl,
                    decoration: const InputDecoration(labelText: 'Prix unitaire (centimes)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.taxCtrl,
                    decoration: const InputDecoration(labelText: 'TVA %'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.discountCtrl,
                    decoration: const InputDecoration(labelText: 'Remise (centimes)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPreview extends StatelessWidget {
  final List<_LineForm> lines;
  const _SummaryPreview({required this.lines});

  @override
  Widget build(BuildContext context) {
    int subtotal = 0;
    int tax = 0;
    for (final line in lines) {
      final qty = double.tryParse(line.qtyCtrl.text) ?? 1;
      final unit = int.tryParse(line.unitCtrl.text) ?? 0;
      final discount = int.tryParse(line.discountCtrl.text) ?? 0;
      final base = (qty * unit).round() - discount;
      final t = ((base * (double.tryParse(line.taxCtrl.text) ?? 0)) / 100).round();
      subtotal += base;
      tax += t;
    }
    final total = subtotal + tax;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Résumé', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Sous-total (HT)', value: _format(subtotal)),
            _SummaryRow(label: 'TVA', value: _format(tax)),
            _SummaryRow(label: 'Total (TTC)', value: _format(total), emphasize: true),
          ],
        ),
      ),
    );
  }

  String _format(int cents) => 'TND ${(cents / 100).toStringAsFixed(2)}';
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: emphasize ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMM yyyy').format(date)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool editing;
  const _InfoBanner({required this.editing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              editing ? 'Mettez à jour les lignes, notes ou dates. Les données médicales ne sont pas stockées.' : 'Créez une facture patient, même hors connexion. Les données médicales ne sont pas stockées.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Totals {
  final int subtotal;
  final int tax;
  final int total;
  _Totals(this.subtotal, this.tax, this.total);
}
