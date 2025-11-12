import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_db.dart';

class DashboardState {
  final bool loading;
  final int totalInvoices;
  final int pendingInvoices;
  final int paidInvoices;
  final int unpaidInvoices;
  const DashboardState({this.loading = true, this.totalInvoices = 0, this.pendingInvoices = 0, this.paidInvoices = 0, this.unpaidInvoices = 0});
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController() : super(const DashboardState());

  Future<void> refresh() async {
    state = const DashboardState(loading: true);
    final db = await AppDb.instance();
    Future<int> count(String where) async {
      final rows = await db.rawQuery('SELECT COUNT(*) as c FROM invoices WHERE $where');
      return (rows.first['c'] as int?) ?? 0;
    }
    final total = await count('1=1');
    final pending = await count("status='en_attente'");
    final paid = await count("status='payee'");
    final unpaid = await count("status!='payee'");
    state = DashboardState(loading: false, totalInvoices: total, pendingInvoices: pending, paidInvoices: paid, unpaidInvoices: unpaid);
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) => DashboardController()..refresh());
