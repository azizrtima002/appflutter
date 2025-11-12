class PatientModel {
  final String id;
  final String fullName;
  final int? dob;
  final String? email;
  final String? phone;
  final String? address;
  final int createdAt;

  const PatientModel({
    required this.id,
    required this.fullName,
    required this.createdAt,
    this.dob,
    this.email,
    this.phone,
    this.address,
  });

  factory PatientModel.fromMap(Map<String, Object?> m) => PatientModel(
        id: m['id'] as String,
        fullName: m['full_name'] as String,
        dob: m['dob'] as int?,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        createdAt: m['created_at'] as int,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'full_name': fullName,
        'dob': dob,
        'email': email,
        'phone': phone,
        'address': address,
        'created_at': createdAt,
      };
}

