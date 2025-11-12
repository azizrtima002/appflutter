import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/invoice.dart';
import '../../../domain/usecases/list_invoices.dart';
import '../../providers.dart';

class InvoiceListState {
  final List<Invoice> items;
  final String? query;
  final InvoiceStatus? status;
  const InvoiceListState({this.items = const [], this.query, this.status});

  InvoiceListState copyWith({List<Invoice>? items, String? query, InvoiceStatus? status}) =>
      InvoiceListState(items: items ?? this.items, query: query ?? this.query, status: status ?? this.status);
}

class InvoiceListController extends StateNotifier<InvoiceListState> {
  final ListInvoices listInvoices;
  InvoiceListController(this.listInvoices) : super(const InvoiceListState());

  Future<void> refresh() async {
    final data = await listInvoices(patientQuery: state.query, status: state.status, sortBy: 'date');
    state = state.copyWith(items: data);
  }

  void setQuery(String? q) {
    state = state.copyWith(query: q);
  }

  void setStatus(InvoiceStatus? s) {
    state = state.copyWith(status: s);
  }
}

final invoiceListControllerProvider = StateNotifierProvider<InvoiceListController, InvoiceListState>((ref) {
  final repo = ref.read(invoiceRepositoryProvider);
  return InvoiceListController(ListInvoices(repo));
});

