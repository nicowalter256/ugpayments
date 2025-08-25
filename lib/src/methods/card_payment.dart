import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../core/payment_exception.dart';

/// Handles card payment processing.
class CardPayment {
  /// Supported card types.
  static const List<String> supportedCardTypes = ['VISA', 'MASTERCARD', 'AMEX'];

  /// Processes a card payment.
  ///
  /// [request] should contain card details and amount.
  /// Returns a [PaymentResponse] with the result.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // Validate the request
      _validateRequest(request);

      // Simulate card payment processing
      // In a real implementation, this would call the payment gateway API
      await Future.delayed(const Duration(seconds: 2));

      // Generate a mock response
      return PaymentResponse(
        transactionId: _generateTransactionId(),
        status: PaymentStatus.successful,
        message: 'Card payment processed successfully',
        amount: request.amount,
        currency: request.currency,
        timestamp: DateTime.now(),
        data: {
          'cardType': _detectCardType(request),
          'lastFourDigits': _extractLastFourDigits(request),
          'paymentMethod': 'CARD',
        },
      );
    } catch (e) {
      throw PaymentException('Card payment failed: $e');
    }
  }

  /// Validates a card payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.metadata == null) {
      throw PaymentException.invalidData('metadata (card details)');
    }

    final cardNumber = request.metadata!['cardNumber'];
    final expiryMonth = request.metadata!['expiryMonth'];
    final expiryYear = request.metadata!['expiryYear'];
    final cvv = request.metadata!['cvv'];

    if (cardNumber == null || cardNumber.toString().isEmpty) {
      throw PaymentException.invalidData('cardNumber');
    }

    if (expiryMonth == null || expiryMonth.toString().isEmpty) {
      throw PaymentException.invalidData('expiryMonth');
    }

    if (expiryYear == null || expiryYear.toString().isEmpty) {
      throw PaymentException.invalidData('expiryYear');
    }

    if (cvv == null || cvv.toString().isEmpty) {
      throw PaymentException.invalidData('cvv');
    }

    if (!_isValidCardNumber(cardNumber.toString())) {
      throw PaymentException.invalidData('cardNumber format');
    }

    if (!_isValidExpiryDate(expiryMonth.toString(), expiryYear.toString())) {
      throw PaymentException.invalidData('expiry date');
    }

    if (!_isValidCvv(cvv.toString())) {
      throw PaymentException.invalidData('cvv');
    }

    if (request.amount <= 0) {
      throw PaymentException.invalidData('amount');
    }
  }

  /// Validates if a card number is in the correct format using Luhn algorithm.
  bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validates if an expiry date is valid and not expired.
  bool _isValidExpiryDate(String month, String year) {
    try {
      final expiryMonth = int.parse(month);
      final expiryYear = int.parse(year);

      if (expiryMonth < 1 || expiryMonth > 12) {
        return false;
      }

      final now = DateTime.now();
      final expiryDate = DateTime(expiryYear, expiryMonth);

      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// Validates if a CVV is in the correct format.
  bool _isValidCvv(String cvv) {
    final cleanCvv = cvv.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCvv.length >= 3 && cleanCvv.length <= 4;
  }

  /// Detects the card type based on the card number.
  String _detectCardType(PaymentRequest request) {
    final cardNumber = request.metadata!['cardNumber']?.toString() ?? '';
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.startsWith('4')) {
      return 'VISA';
    } else if (cleanNumber.startsWith('5')) {
      return 'MASTERCARD';
    } else if (cleanNumber.startsWith('3')) {
      return 'AMEX';
    } else {
      return 'UNKNOWN';
    }
  }

  /// Extracts the last four digits of the card number.
  String _extractLastFourDigits(PaymentRequest request) {
    final cardNumber = request.metadata!['cardNumber']?.toString() ?? '';
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length >= 4) {
      return cleanNumber.substring(cleanNumber.length - 4);
    }

    return '';
  }

  /// Generates a unique transaction ID for card payments.
  String _generateTransactionId() {
    return 'CP_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Checks if a card type is supported.
  static bool isCardTypeSupported(String cardType) {
    return supportedCardTypes.contains(cardType.toUpperCase());
  }

  /// Gets the list of supported card types.
  static List<String> getSupportedCardTypes() {
    return List.from(supportedCardTypes);
  }
}
