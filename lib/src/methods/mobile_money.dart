import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../core/payment_exception.dart';

/// Handles mobile money payment processing.
class MobileMoney {
  /// Supported mobile money providers in Uganda.
  static const List<String> supportedProviders = [
    'MTN_MOBILE_MONEY',
    'AIRTEL_MONEY',
    'MPESA',
  ];

  /// Processes a mobile money payment.
  ///
  /// [request] should contain a valid phone number and amount.
  /// Returns a [PaymentResponse] with the result.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // Validate the request
      _validateRequest(request);

      // Simulate mobile money payment processing
      // In a real implementation, this would call the mobile money API
      await Future.delayed(const Duration(seconds: 2));

      // Generate a mock response
      return PaymentResponse(
        transactionId: _generateTransactionId(),
        status: PaymentStatus.successful,
        message: 'Mobile money payment processed successfully',
        amount: request.amount,
        currency: request.currency,
        timestamp: DateTime.now(),
        data: {
          'provider': _detectProvider(request.phoneNumber!),
          'phoneNumber': request.phoneNumber,
        },
      );
    } catch (e) {
      throw PaymentException('Mobile money payment failed: $e');
    }
  }

  /// Validates a mobile money payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.phoneNumber == null || request.phoneNumber!.isEmpty) {
      throw PaymentException.invalidData('phoneNumber');
    }

    if (!_isValidPhoneNumber(request.phoneNumber!)) {
      throw PaymentException.invalidData('phoneNumber format');
    }

    if (request.amount <= 0) {
      throw PaymentException.invalidData('amount');
    }
  }

  /// Validates if a phone number is in the correct format.
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Ugandan mobile number
    // Ugandan mobile numbers typically start with +256 or 0
    if (cleanNumber.startsWith('256') && cleanNumber.length == 12) {
      return true;
    }

    if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return true;
    }

    return false;
  }

  /// Detects the mobile money provider based on the phone number.
  String _detectProvider(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.startsWith('2567') || cleanNumber.startsWith('07')) {
      return 'MTN_MOBILE_MONEY';
    } else if (cleanNumber.startsWith('2567') || cleanNumber.startsWith('07')) {
      return 'AIRTEL_MONEY';
    } else {
      return 'UNKNOWN';
    }
  }

  /// Generates a unique transaction ID for mobile money payments.
  String _generateTransactionId() {
    return 'MM_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Checks if a provider is supported.
  static bool isProviderSupported(String provider) {
    return supportedProviders.contains(provider.toUpperCase());
  }
}
