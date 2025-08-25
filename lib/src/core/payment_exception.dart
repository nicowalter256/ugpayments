/// Exception thrown when payment operations fail.
class PaymentException implements Exception {
  /// The error message.
  final String message;

  /// The error code (if available).
  final String? code;

  /// Additional error details.
  final Map<String, dynamic>? details;

  /// The original exception that caused this payment exception.
  final Exception? originalException;

  /// Creates a new PaymentException.
  const PaymentException(
    this.message, {
    this.code,
    this.details,
    this.originalException,
  });

  /// Creates a PaymentException for invalid payment data.
  factory PaymentException.invalidData(String field) {
    return PaymentException(
      'Invalid payment data: $field is required or invalid',
      code: 'INVALID_DATA',
      details: {'field': field},
    );
  }

  /// Creates a PaymentException for authentication failures.
  factory PaymentException.authenticationFailed() {
    return PaymentException(
      'Authentication failed. Please check your API credentials.',
      code: 'AUTH_FAILED',
    );
  }

  /// Creates a PaymentException for network errors.
  factory PaymentException.networkError(String reason) {
    return PaymentException(
      'Network error: $reason',
      code: 'NETWORK_ERROR',
      details: {'reason': reason},
    );
  }

  /// Creates a PaymentException for insufficient funds.
  factory PaymentException.insufficientFunds() {
    return PaymentException(
      'Insufficient funds to complete the transaction.',
      code: 'INSUFFICIENT_FUNDS',
    );
  }

  /// Creates a PaymentException for transaction timeout.
  factory PaymentException.timeout() {
    return PaymentException(
      'Transaction timed out. Please try again.',
      code: 'TIMEOUT',
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('PaymentException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    return buffer.toString();
  }
}
