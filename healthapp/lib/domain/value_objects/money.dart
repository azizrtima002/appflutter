class Money {
  final int cents;
  const Money(this.cents) : assert(cents >= 0, 'Money cannot be negative');

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money((cents - other.cents).clamp(0, 1 << 31));
}

