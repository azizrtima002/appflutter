import '../entities/invoice.dart';
import '../entities/line_item.dart';

abstract class InvoiceRepository {
  Future<Invoice> createInvoice({
    required Invoice draft,
    required List<LineItem> lines,
  });

  Future<Invoice> updateInvoice(Invoice invoice, List<LineItem>? lines);

  Future<void> cancelInvoice(String invoiceId);
  Future<void> deleteInvoice(String invoiceId);

  Future<List<Invoice>> listInvoices({
    String? patientQuery,
    InvoiceStatus? status,
    int? fromMs,
    int? toMs,
    String? sortBy, // 'date'|'total'
    bool descending = true,
  });

  Future<Invoice> getInvoiceDetails(String id);
}
