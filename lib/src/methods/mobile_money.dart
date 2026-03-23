import '../models/payment_request.dart';
import '../models/payment_response.dart';

/// Legacy simulated mobile money payment processing.
///
/// SECURITY: This method previously simulated mobile money payment processing.
/// It is now disabled to prevent unsafe usage.
@Deprecated('MobileMoney is disabled. Use PesaPal redirect flow via WebView.')
class MobileMoney {
  /// Supported mobile money providers in Uganda (informational only).
  static const List<String> supportedProviders = [
    'MTN_MOBILE_MONEY',
    'AIRTEL_MONEY',
    'MPESA',
  ];

  /// Disabled runtime behavior.
  Future<PaymentResponse> processPayment(PaymentRequest request) {
    throw UnimplementedError(
      'MobileMoney is disabled. Payments must be initiated via PesaPal (redirect flow) in this package.',
    );
  }
}
