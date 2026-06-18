import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/transaction.dart';
import '../providers/pesapal_provider.dart';
import '../utils/payment_validator.dart';
import 'payment_config.dart';
import 'payment_exception.dart';

/// Main client for handling payment operations in Uganda.
///
/// Delegates the actual PesaPal order submission and status lookups to
/// [PesaPalProvider] so there is a single implementation of that logic.
class PaymentClient {
  final PesaPalProvider _provider;

  /// Creates a new PaymentClient with the given configuration.
  PaymentClient(PaymentConfig config) : _provider = PesaPalProvider(config);

  /// Processes a payment request using PesaPal API.
  ///
  /// Returns a [PaymentResponse] with the result of the payment operation.
  ///
  /// Throws [PaymentException] if the payment fails.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    _validateRequest(request);
    return _provider.submitOrder(request);
  }

  /// Retrieves transaction details by transaction ID (PesaPal order tracking ID).
  Future<Transaction?> getTransaction(String transactionId) async {
    final response = await _provider.getTransactionStatus(transactionId);
    return _toTransaction(response);
  }

  /// Validates a payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.amount <= 0) {
      throw PaymentException('Amount must be greater than 0');
    }

    if (request.currency.isEmpty) {
      throw PaymentException('Currency is required');
    }

    if (!PaymentValidator.isValidCurrency(request.currency)) {
      throw PaymentException('Unsupported currency: ${request.currency}');
    }

    if (request.paymentMethod.isEmpty) {
      throw PaymentException('Payment method is required');
    }

    if (!PaymentValidator.isValidPaymentMethod(request.paymentMethod)) {
      throw PaymentException(
        'Unsupported payment method: ${request.paymentMethod}',
      );
    }
  }

  /// Maps a PesaPal status-check [PaymentResponse] into a [Transaction].
  Transaction _toTransaction(PaymentResponse response) {
    final data = response.data ?? const <String, dynamic>{};
    return Transaction(
      id: response.transactionId,
      amount: response.amount ?? 0.0,
      currency: response.currency ?? '',
      paymentMethod: data['payment_method']?.toString() ?? '',
      status: response.status,
      merchantReference: data['merchant_reference']?.toString(),
      createdAt: response.timestamp,
      updatedAt: response.timestamp,
    );
  }

  /// Disposes the HTTP client and token manager.
  void dispose() {
    _provider.dispose();
  }

  /// Clears cached auth token (and removes it from secure storage if present).
  ///
  /// Use this when the user logs out or you want to force a fresh token.
  void logout() {
    _provider.clearToken();
  }
}
