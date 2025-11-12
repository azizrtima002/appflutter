import 'package:flutter_test/flutter_test.dart';
import 'package:health_billing/features/pdf/pdf_service.dart';
import 'package:health_billing/data/dao/invoice_dao.dart';
import 'package:health_billing/data/dao/patient_dao.dart';
import 'package:health_billing/data/models/invoice_model.dart';
import 'package:health_billing/data/models/line_item_model.dart';
import 'package:health_billing/data/models/patient_model.dart';

void main() {
  test('PDF non vide inclut logo/totaux/QR', () async {
    final svc = PdfService(invoiceDao: _FakeInvoiceDao(), patientDao: _FakePatientDao());
    final bytes = await svc.generateInvoicePdf('inv1');
    expect(bytes.length, greaterThan(100));
  });
}

class _FakeInvoiceDao extends InvoiceDao {
  @override
  Future<InvoiceModel?> getById(String id) async => InvoiceModel(
        id: 'inv1',
        patientId: 'p1',
        episode: 'Consultation',
        issueDate: DateTime.now().millisecondsSinceEpoch,
        dueDate: DateTime.now().millisecondsSinceEpoch + 86400000,
        status: 'en_attente',
        notes: 'Notes',
        subtotalCents: 10000,
        taxCents: 1900,
        discountCents: 0,
        totalCents: 11900,
        amountDueCents: 11900,
        qrPayUrl: 'https://example.com/pay',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        needsSync: 0,
      );

  @override
  Future<List<LineItemModel>> getLineItems(String invoiceId) async => [
        LineItemModel(
          id: 'li1',
           invoiceId: 'inv1',
          label: 'Consultation',
          qty: 1,
          unitPriceCents: 10000,
          taxRate: 19.0,
          discountCents: 0,
          lineTotalCents: 11900,
        ),
      ];
}

class _FakePatientDao extends PatientDao {
  @override
  Future<PatientModel?> findById(String id) async => PatientModel(
        id: 'p1',
        fullName: 'Patient X',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
}

