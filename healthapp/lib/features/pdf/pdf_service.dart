import 'dart:typed_data';

import 'package:barcode/barcode.dart' as bc;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/dao/invoice_dao.dart';
import '../../data/dao/patient_dao.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/line_item_model.dart';

class PdfService {
  final InvoiceDao invoiceDao;
  final PatientDao patientDao;
  PdfService({required this.invoiceDao, required this.patientDao});

  Future<List<int>> generateInvoicePdf(String invoiceId) async {
    final inv = await invoiceDao.getById(invoiceId);
    if (inv == null) throw Exception('Invoice not found');
    final patient = await patientDao.findById(inv.patientId);
    final items = await invoiceDao.getLineItems(invoiceId);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(inv, patient?.fullName ?? ''),
          pw.SizedBox(height: 12),
          _linesTable(items),
          pw.SizedBox(height: 12),
          _totals(inv),
          pw.SizedBox(height: 12),
          if ((inv.notes ?? '').isNotEmpty) _notes(inv.notes!),
          pw.SizedBox(height: 16),
          _qr(inv.qrPayUrl ?? 'https://example.com/pay'),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> printPdf(String invoiceId) async {
    final bytes = await generateInvoicePdf(invoiceId);
    await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
  }

  Future<void> sharePdf(String invoiceId) async {
    final bytes = await generateInvoicePdf(invoiceId);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'invoice_$invoiceId.pdf',
    );
  }

  pw.Widget _header(InvoiceModel inv, String patientName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0xFF4CAF50),
            PdfColor.fromInt(0xFF2E7D32),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 54,
            height: 54,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'HB',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  color: PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Health Billing',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Facture patient',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Patient: $patientName',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Facture #${inv.id.substring(0, 8)}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Emise le ${_formatDate(inv.issueDate)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
              pw.Text(
                'Echeance ${_formatDate(inv.dueDate)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _linesTable(List<LineItemModel> items) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Acte / Libelle', 'Quantite', 'PU HT', 'TVA %', 'Total'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      data: [
        for (final it in items)
          [
            it.label,
            it.qty.toStringAsFixed(2),
            _money(it.unitPriceCents),
            it.taxRate.toStringAsFixed(2),
            _money(it.lineTotalCents),
          ]
      ],
      cellAlignment: pw.Alignment.centerLeft,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    );
  }

  pw.Widget _totals(InvoiceModel inv) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _kv('Sous-total (HT)', _money(inv.subtotalCents)),
          _kv('TVA', _money(inv.taxCents)),
          _kv('Total (TTC)', _money(inv.totalCents)),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFF4CAF50)),
            ),
            child: _kv('Reste du', _money(inv.amountDueCents), emphasize: true),
          ),
        ],
      ),
    );
  }

  pw.Widget _notes(String notes) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(notes),
        ],
      );

  pw.Widget _qr(String url) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('QR Paiement'),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.BarcodeWidget(
            data: url,
            barcode: bc.Barcode.qrCode(),
            width: 80,
            height: 80,
          ),
        ),
      ],
    );
  }

  pw.Widget _kv(String k, String v, {bool emphasize = false}) => pw.Row(
        children: [
          pw.Text(
            k,
            style: pw.TextStyle(
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            v,
            style: pw.TextStyle(
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      );

  String _money(int cents) => 'TND ${(cents / 100).toStringAsFixed(2)}';

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
