import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../models/transaction.dart';
import 'payment_config.dart';
import 'payment_exception.dart';

/// Main client for handling payment operations in Uganda.
class PaymentClient {
  final PaymentConfig _config;

  /// Creates a new PaymentClient with the given configuration.
  PaymentClient(this._config);

  /// Processes a payment request.
  ///
  /// Returns a [PaymentResponse] with the result of the payment operation.
  ///
  /// Throws [PaymentException] if the payment fails.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // Validate the payment request
      _validateRequest(request);

      // Process the payment based on the payment method
      final response = await _processPaymentMethod(request);

      return response;
    } catch (e) {
      throw PaymentException('Payment processing failed: $e');
    }
  }

  /// Retrieves transaction details by transaction ID.
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      // Implementation for fetching transaction details
      // This would typically make an API call to the payment provider
      return null; // Placeholder
    } catch (e) {
      throw PaymentException('Failed to retrieve transaction: $e');
    }
  }

  /// Validates a payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.amount <= 0) {
      throw PaymentException('Amount must be greater than 0');
    }

    if (request.currency.isEmpty) {
      throw PaymentException('Currency is required');
    }

    if (request.paymentMethod.isEmpty) {
      throw PaymentException('Payment method is required');
    }
  }

  /// Processes payment based on the payment method.
  Future<PaymentResponse> _processPaymentMethod(PaymentRequest request) async {
    // Implementation would vary based on payment method
    // This is a placeholder implementation
    return PaymentResponse(
      transactionId: _generateTransactionId(),
      status: PaymentStatus.pending,
      message: 'Payment processed successfully',
      timestamp: DateTime.now(),
    );
  }

  /// Generates a unique transaction ID.
  String _generateTransactionId() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}';
  }
}
