import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../data/dao/invoice_dao.dart';
import '../../domain/entities/payment.dart' as domain;
import '../../data/repositories/payment_repository_impl.dart';

const String _envPublishableKey =
    String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: 'pk_test_51_mock');
const String _envBackendUrl =
    String.fromEnvironment('STRIPE_BACKEND_URL', defaultValue: 'http://10.0.2.2:4242');
const String _envMerchantId =
    String.fromEnvironment('STRIPE_MERCHANT_ID', defaultValue: 'merchant.com.health.billing');
const String _envUrlScheme =
    String.fromEnvironment('STRIPE_URL_SCHEME', defaultValue: 'flutterstripe');

class StripeConfigException implements Exception {
  final String message;
  const StripeConfigException(this.message);
  @override
  String toString() => message;
}

class StripeService {
  final InvoiceDao invoiceDao;
  final PaymentRepositoryImpl paymentRepo;
  StripeService({required this.invoiceDao, required this.paymentRepo});

  static bool _stripeConfigured = false;

  Future<void> _ensureStripeConfigured() async {
    if (_stripeConfigured) return;
    final key = _envPublishableKey.trim();
    if (key.isEmpty || key == 'pk_test_51_mock') {
      throw const StripeConfigException(
        'Stripe non configure. Lancez flutter run avec --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx '
        'et --dart-define=STRIPE_BACKEND_URL=http://<serveur>:4242',
      );
    }
    Stripe.publishableKey = key;
    if (_envMerchantId.trim().isNotEmpty) {
      Stripe.merchantIdentifier = _envMerchantId.trim();
    }
    if (_envUrlScheme.trim().isNotEmpty) {
      Stripe.urlScheme = _envUrlScheme.trim();
    }
    _stripeConfigured = true;
  }

  Future<bool> startPayment(
    String invoiceId, {
    String currency = 'TND',
    Uri? serverUrl,
    Uri? fallbackPaymentLink,
  }) async {
    await _ensureStripeConfigured();
    final invoice = await invoiceDao.getById(invoiceId);
    if (invoice == null) return false;
    final amount = invoice.amountDueCents;
    if (amount <= 0) return true;

    try {
      final base = serverUrl ?? Uri.parse(_envBackendUrl);
      final url = base.resolve('/create-payment-intent');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount_cents': amount, 'currency': currency, 'metadata': {'invoiceId': invoiceId}}),
      );
      if (resp.statusCode != 200) throw Exception('Server error');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Healthcare Clinic',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // Record payment
      await paymentRepo.addPayment(domain.Payment(
        id: const Uuid().v4(),
        invoiceId: invoiceId,
        amountCents: amount,
        method: domain.PaymentMethod.stripe,
        status: domain.PaymentStatus.confirme,
        reference: 'stripe',
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ));
      return true;
    } on StripeConfigException {
      rethrow;
    } catch (err) {
      final fallback = fallbackPaymentLink ??
          (invoice.qrPayUrl != null ? Uri.parse(invoice.qrPayUrl!) : null);
      if (fallback != null) {
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
      throw Exception('Stripe error: $err');
    }
  }
}
