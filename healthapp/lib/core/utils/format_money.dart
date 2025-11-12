import 'package:intl/intl.dart';

class MoneyFormat {
  MoneyFormat(this.currencyCode, {this.decimals = 2});
  final String currencyCode; // e.g., 'TND'
  final int decimals;

  String formatCents(int cents) {
    final value = cents / 100.0;
    final formatter = NumberFormat.currency(name: currencyCode, decimalDigits: decimals);
    return formatter.format(value);
  }
}
