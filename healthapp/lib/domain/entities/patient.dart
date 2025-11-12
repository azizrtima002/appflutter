class Patient {
  final String id;
  final String fullName;
  final int? dobMs;
  final String? email;
  final String? phone;
  final String? address;
  final int createdAtMs;

  const Patient({
    required this.id,
    required this.fullName,
    required this.createdAtMs,
    this.dobMs,
    this.email,
    this.phone,
    this.address,
  });
}

