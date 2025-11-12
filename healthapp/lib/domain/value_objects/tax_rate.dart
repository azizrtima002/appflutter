class TaxRate {
  final double rate; // percent, e.g., 19.0
  const TaxRate(this.rate) : assert(rate >= 0);
}

