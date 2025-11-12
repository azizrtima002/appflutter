import '../../features/pdf/pdf_service.dart';

class GenerateInvoicePdf {
  final PdfService pdfService;
  GenerateInvoicePdf(this.pdfService);

  Future<List<int>> call(String invoiceId) => pdfService.generateInvoicePdf(invoiceId);
}

