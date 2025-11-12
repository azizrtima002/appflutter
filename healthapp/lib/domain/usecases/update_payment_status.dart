import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class UpdatePaymentStatusUseCase {
  final PaymentRepository repo;
  UpdatePaymentStatusUseCase(this.repo);

  Future<Payment> call(String paymentId, PaymentStatus status) {
    return repo.updatePaymentStatus(paymentId, status);
  }
}

