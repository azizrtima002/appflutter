import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Payment> addPayment(Payment payment);

  Future<Payment> updatePaymentStatus(String paymentId, PaymentStatus status);

  Future<void> deletePaymentSoft(String paymentId);
}

