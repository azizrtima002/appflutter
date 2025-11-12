import '../repositories/invoice_repository.dart';

class CancelInvoice {
  final InvoiceRepository repo;
  CancelInvoice(this.repo);

  Future<void> call(String invoiceId) => repo.cancelInvoice(invoiceId);
}

