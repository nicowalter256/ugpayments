/// Exception thrown when payment operations fail.
///
/// This is a sealed hierarchy: catching [PaymentException] catches every
/// subtype below, and a `switch` over a caught instance is exhaustiveness
/// checked by the compiler.
sealed class PaymentException implements Exception {
  /// The error message.
  final String message;

  /// The error code (if available).
  final String? code;

  /// Additional error details.
  final Map<String, dynamic>? details;

  /// The original exception that caused this payment exception.
  final Exception? originalException;

  const PaymentException(
    this.message, {
    this.code,
    this.details,
    this.originalException,
  });

  /// Creates a PaymentException for invalid payment data.
  factory PaymentException.invalidData(String field) =
      PaymentInvalidDataException;

  /// Creates a PaymentException for authentication failures.
  factory PaymentException.authenticationFailed() =
      PaymentAuthenticationException;

  /// Creates a PaymentException for network errors.
  factory PaymentException.networkError(String reason) =
      PaymentNetworkException;

  /// Creates a PaymentException for insufficient funds.
  factory PaymentException.insufficientFunds() =
      PaymentInsufficientFundsException;

  /// Creates a PaymentException for transaction timeout.
  factory PaymentException.timeout() = PaymentTimeoutException;

  /// Creates a PaymentException for a request-validation failure
  /// (e.g. a bad amount, currency, or payment method).
  factory PaymentException.validation(
    String message, {
    String? code,
    Map<String, dynamic>? details,
  }) = PaymentValidationException;

  /// Creates a PaymentException for an arbitrary PesaPal API/transport
  /// failure that doesn't fit one of the more specific categories above.
  factory PaymentException.api(
    String message, {
    String? code,
    Map<String, dynamic>? details,
    Exception? originalException,
  }) = PaymentApiException;

  @override
  String toString() {
    final buffer = StringBuffer('PaymentException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    return buffer.toString();
  }
}

/// Payment data (e.g. a request field) was missing or invalid.
final class PaymentInvalidDataException extends PaymentException {
  /// The field that was missing or invalid.
  final String field;

  PaymentInvalidDataException(this.field)
    : super(
        'Invalid payment data: $field is required or invalid',
        code: 'INVALID_DATA',
        details: {'field': field},
      );
}

/// PesaPal rejected the configured API credentials.
final class PaymentAuthenticationException extends PaymentException {
  const PaymentAuthenticationException()
    : super(
        'Authentication failed. Please check your API credentials.',
        code: 'AUTH_FAILED',
      );
}

/// A network-level failure occurred while talking to PesaPal.
final class PaymentNetworkException extends PaymentException {
  /// The underlying reason for the network failure.
  final String reason;

  PaymentNetworkException(this.reason)
    : super(
        'Network error: $reason',
        code: 'NETWORK_ERROR',
        details: {'reason': reason},
      );
}

/// The transaction failed due to insufficient funds.
final class PaymentInsufficientFundsException extends PaymentException {
  const PaymentInsufficientFundsException()
    : super(
        'Insufficient funds to complete the transaction.',
        code: 'INSUFFICIENT_FUNDS',
      );
}

/// The transaction timed out.
final class PaymentTimeoutException extends PaymentException {
  const PaymentTimeoutException()
    : super('Transaction timed out. Please try again.', code: 'TIMEOUT');
}

/// A [PaymentRequest] failed local validation before being sent to PesaPal.
final class PaymentValidationException extends PaymentException {
  PaymentValidationException(
    super.message, {
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

/// An arbitrary PesaPal API/transport failure (bad status code, malformed
/// response, IPN registration failure, etc.).
final class PaymentApiException extends PaymentException {
  PaymentApiException(
    super.message, {
    super.code = 'API_ERROR',
    super.details,
    super.originalException,
  });
}
