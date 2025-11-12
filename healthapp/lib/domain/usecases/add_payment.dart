import 'package:uuid/uuid.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class AddPayment {
  final PaymentRepository repo;
  AddPayment(this.repo);

  Future<Payment> call({
    required String invoiceId,
    required int amountCents,
    required PaymentMethod method,
    String? reference,
  }) async {
    final p = Payment(
      id: const Uuid().v4(),
      invoiceId: invoiceId,
      amountCents: amountCents,
      method: method,
      status: PaymentStatus.confirme,
      reference: reference,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    return repo.addPayment(p);
  }
}

