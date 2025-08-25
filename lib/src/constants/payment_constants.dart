/// Constants used throughout the payment package.
class PaymentConstants {
  // Private constructor to prevent instantiation
  PaymentConstants._();

  /// Supported currencies
  static const List<String> supportedCurrencies = [
    'UGX', // Ugandan Shilling
    'USD', // US Dollar
    'EUR', // Euro
    'GBP', // British Pound
    'KES', // Kenyan Shilling
  ];

  /// Supported payment methods
  static const List<String> supportedPaymentMethods = [
    'MOBILE_MONEY',
    'BANK_TRANSFER',
    'CARD_PAYMENT',
    'CASH',
  ];

  /// Mobile money providers in Uganda
  static const List<String> mobileMoneyProviders = [
    'MTN_MOBILE_MONEY',
    'AIRTEL_MONEY',
    'MPESA',
  ];

  /// Supported banks in Uganda
  static const List<String> supportedBanks = [
    'STANBIC_BANK',
    'CENTENARY_BANK',
    'DFCU_BANK',
    'BARCLAYS_BANK',
    'STANDARD_CHARTERED',
    'BANK_OF_AFRICA',
  ];

  /// Supported card types
  static const List<String> supportedCardTypes = ['VISA', 'MASTERCARD', 'AMEX'];

  /// Default timeout for payment operations (in seconds)
  static const int defaultTimeoutSeconds = 30;

  /// Maximum amount allowed for a single transaction (in UGX)
  static const double maxTransactionAmount = 10000000.0; // 10 million UGX

  /// Minimum amount allowed for a single transaction (in UGX)
  static const double minTransactionAmount = 100.0; // 100 UGX

  /// Default currency for Uganda
  static const String defaultCurrency = 'UGX';

  /// API endpoints
  static const String sandboxBaseUrl = 'https://cybqa.pesapal.com/pesapalv3';
  static const String productionBaseUrl = 'https://pay.pesapal.com/v3';

  /// Error codes
  static const String errorInvalidData = 'INVALID_DATA';
  static const String errorAuthenticationFailed = 'AUTH_FAILED';
  static const String errorNetworkError = 'NETWORK_ERROR';
  static const String errorInsufficientFunds = 'INSUFFICIENT_FUNDS';
  static const String errorTimeout = 'TIMEOUT';
  static const String errorTransactionFailed = 'TRANSACTION_FAILED';
  static const String errorUnsupportedPaymentMethod =
      'UNSUPPORTED_PAYMENT_METHOD';

  /// Success messages
  static const String successPaymentProcessed =
      'Payment processed successfully';
  static const String successTransactionCompleted =
      'Transaction completed successfully';
  static const String successRefundProcessed = 'Refund processed successfully';

  /// Validation messages
  static const String validationAmountRequired = 'Amount is required';
  static const String validationAmountPositive = 'Amount must be positive';
  static const String validationCurrencyRequired = 'Currency is required';
  static const String validationPaymentMethodRequired =
      'Payment method is required';
  static const String validationPhoneNumberRequired =
      'Phone number is required for mobile money';
  static const String validationCardDetailsRequired =
      'Card details are required for card payment';
  static const String validationBankDetailsRequired =
      'Bank details are required for bank transfer';

  /// Transaction status messages
  static const String statusPending = 'Transaction is pending';
  static const String statusProcessing = 'Transaction is being processed';
  static const String statusSuccessful = 'Transaction was successful';
  static const String statusFailed = 'Transaction failed';
  static const String statusCancelled = 'Transaction was cancelled';
  static const String statusRefunded = 'Transaction was refunded';
  static const String statusExpired = 'Transaction expired';

  /// Security constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int tokenLength = 32;
  static const int sessionTimeoutMinutes = 30;

  /// Format patterns
  static const String phoneNumberPattern = r'^\+?256\d{9}$';
  static const String emailPattern = r'^[^@]+@[^@]+\.[^@]+$';
  static const String cardNumberPattern = r'^\d{13,19}$';
  static const String cvvPattern = r'^\d{3,4}$';
  static const String expiryDatePattern = r'^\d{2}/\d{4}$';

  /// Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String timeFormat = 'HH:mm:ss';

  /// File extensions
  static const String receiptFileExtension = '.pdf';
  static const String logFileExtension = '.log';

  /// HTTP status codes
  static const int httpOk = 200;
  static const int httpCreated = 201;
  static const int httpBadRequest = 400;
  static const int httpUnauthorized = 401;
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpInternalServerError = 500;
  static const int httpServiceUnavailable = 503;

  /// HTTP headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerUserAgent = 'User-Agent';
  static const String headerAccept = 'Accept';

  /// Content types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeForm = 'application/x-www-form-urlencoded';
  static const String contentTypeMultipart = 'multipart/form-data';
}
