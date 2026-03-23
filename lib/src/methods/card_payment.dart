import '../models/payment_request.dart';
import '../models/payment_response.dart';

/// Legacy simulated card payment processing.
///
/// SECURITY: This method previously simulated card payment processing and
/// validated card data locally. It is now disabled to prevent unsafe usage.
@Deprecated('CardPayment is disabled. Use PesaPal redirect flow via WebView.')
class CardPayment {
  /// Supported card types (informational only).
  static const List<String> supportedCardTypes = ['VISA', 'MASTERCARD', 'AMEX'];

  /// Disabled runtime behavior.
  Future<PaymentResponse> processPayment(PaymentRequest request) {
    throw UnimplementedError(
      'CardPayment is disabled. Cards must be handled inside Pesapal checkout using the PesaPal `redirect_url` flow.',
    );
  }
}
