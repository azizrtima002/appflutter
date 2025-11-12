import 'package:flutter/material.dart';

class PaymentFormSheet extends StatefulWidget {
  const PaymentFormSheet({super.key});

  @override
  State<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends State<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String _method = 'cash';
  final _refCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Montant (centimes)'),
              validator: (v) =>
                  (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Montant invalide',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                DropdownMenuItem(value: 'card', child: Text('Carte')),
                DropdownMenuItem(value: 'bank', child: Text('Virement')),
                DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
              decoration: const InputDecoration(labelText: 'Méthode'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(labelText: 'Référence'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'amount': int.parse(_amountCtrl.text),
                    'method': _method,
                    'ref': _refCtrl.text
                  });
                }
              },
              child: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }
}
