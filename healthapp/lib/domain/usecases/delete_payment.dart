import '../repositories/payment_repository.dart';

class DeletePayment {
  final PaymentRepository repo;
  DeletePayment(this.repo);

  Future<void> call(String paymentId) => repo.deletePaymentSoft(paymentId);
}

