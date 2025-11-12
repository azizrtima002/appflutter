import '../entities/invoice.dart';
import '../entities/line_item.dart';
import '../repositories/invoice_repository.dart';

class UpdateInvoice {
  final InvoiceRepository repo;
  UpdateInvoice(this.repo);

  Future<Invoice> call(Invoice invoice, {List<LineItem>? lines}) async {
    return repo.updateInvoice(invoice, lines);
  }
}

