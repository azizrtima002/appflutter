import '../repositories/invoice_repository.dart';

class DeleteInvoice {
  final InvoiceRepository repo;
  DeleteInvoice(this.repo);

  Future<void> call(String invoiceId) => repo.deleteInvoice(invoiceId);
}
