import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class ListInvoices {
  final InvoiceRepository repo;
  ListInvoices(this.repo);

  Future<List<Invoice>> call({
    String? patientQuery,
    InvoiceStatus? status,
    int? fromMs,
    int? toMs,
    String? sortBy,
    bool descending = true,
  }) {
    return repo.listInvoices(
      patientQuery: patientQuery,
      status: status,
      fromMs: fromMs,
      toMs: toMs,
      sortBy: sortBy,
      descending: descending,
    );
  }
}

