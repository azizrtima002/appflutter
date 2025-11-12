import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currency = 'TND';
  double _defaultTva = 19.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Qualité & Confidentialité',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Les données médicales ne sont pas stockées.'),
          const Divider(height: 32),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Devise'),
            items: const [
              DropdownMenuItem(value: 'TND', child: Text('TND (par défaut)')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? 'TND'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _defaultTva.toStringAsFixed(2),
            decoration: const InputDecoration(labelText: 'TVA par défaut (%)'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                setState(() => _defaultTva = double.tryParse(v) ?? 19.0),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Exporter JSON'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Importer JSON'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Confidentialité'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
