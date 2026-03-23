import '../models/payment_request.dart';
import '../models/payment_response.dart';

/// Legacy simulated bank transfer payment processing.
///
/// SECURITY: Previously simulated bank transfer processing and validated
/// account details locally. It is now disabled to prevent unsafe usage.
@Deprecated('BankTransfer is disabled. Initiate payments via PesaPal redirect flow.')
class BankTransfer {
  /// Supported banks (informational only).
  static const List<String> supportedBanks = [
    'STANBIC_BANK',
    'CENTENARY_BANK',
    'DFCU_BANK',
    'BARCLAYS_BANK',
    'STANDARD_CHARTERED',
    'BANK_OF_AFRICA',
  ];

  /// Disabled runtime behavior.
  Future<PaymentResponse> processPayment(PaymentRequest request) {
    throw UnimplementedError(
      'BankTransfer is disabled. Payments must be initiated via PesaPal redirect flow.',
    );
  }
}
