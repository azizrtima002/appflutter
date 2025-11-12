import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dao/invoice_dao.dart';
import '../data/dao/payment_dao.dart';
import '../data/dao/patient_dao.dart';
import '../data/repositories/invoice_repository_impl.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../features/pdf/pdf_service.dart';
import '../data/services/json_backup_service.dart';

final invoiceDaoProvider = Provider((ref) => InvoiceDao());
final paymentDaoProvider = Provider((ref) => PaymentDao());
final patientDaoProvider = Provider((ref) => PatientDao());

final invoiceRepositoryProvider = Provider((ref) =>
    InvoiceRepositoryImpl(invoiceDao: ref.read(invoiceDaoProvider), paymentDao: ref.read(paymentDaoProvider)));

final paymentRepositoryProvider = Provider((ref) =>
    PaymentRepositoryImpl(paymentDao: ref.read(paymentDaoProvider), invoiceDao: ref.read(invoiceDaoProvider)));

final pdfServiceProvider = Provider((ref) => PdfService(
      invoiceDao: ref.read(invoiceDaoProvider),
      patientDao: ref.read(patientDaoProvider),
    ));

final backupServiceProvider = Provider((ref) => JsonBackupService());
