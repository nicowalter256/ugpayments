/// Configuration settings for the payment client.
class PaymentConfig {
  /// The consumer key for PesaPal authentication.
  final String consumerKey;

  /// The consumer secret for PesaPal authentication.
  final String consumerSecret;

  /// The base URL for the payment API.
  final String baseUrl;

  /// The environment (production, sandbox, etc.).
  final String environment;

  /// Timeout for API requests in seconds.
  final int timeoutSeconds;

  /// Whether to enable debug logging.
  final bool enableDebugLogging;

  /// Additional configuration options.
  final Map<String, dynamic>? additionalConfig;

  /// Creates a new PaymentConfig.
  const PaymentConfig({
    required this.consumerKey,
    required this.consumerSecret,
    required this.baseUrl,
    this.environment = 'production',
    this.timeoutSeconds = 30,
    this.enableDebugLogging = false,
    this.additionalConfig,
  });

  /// Creates a PaymentConfig for PesaPal sandbox/testing environment.
  factory PaymentConfig.pesaPalSandbox({
    required String consumerKey,
    required String consumerSecret,
    String baseUrl = 'https://cybqa.pesapal.com/pesapalv3',
    int timeoutSeconds = 30,
    bool enableDebugLogging = true,
    String? callbackUrl,
    String? notificationId,
  }) {
    return PaymentConfig(
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      baseUrl: baseUrl,
      environment: 'sandbox',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
      additionalConfig: {
        if (callbackUrl != null) 'callback_url': callbackUrl,
        if (notificationId != null) 'notification_id': notificationId,
        'provider': 'pesapal',
      },
    );
  }

  /// Creates a PaymentConfig for PesaPal production environment.
  factory PaymentConfig.pesaPalProduction({
    required String consumerKey,
    required String consumerSecret,
    String baseUrl = 'https://pay.pesapal.com/v3',
    int timeoutSeconds = 30,
    bool enableDebugLogging = false,
    String? callbackUrl,
    String? notificationId,
  }) {
    return PaymentConfig(
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      baseUrl: baseUrl,
      environment: 'production',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
      additionalConfig: {
        if (callbackUrl != null) 'callback_url': callbackUrl,
        if (notificationId != null) 'notification_id': notificationId,
        'provider': 'pesapal',
      },
    );
  }

  /// Creates a PaymentConfig for sandbox/testing environment.
  factory PaymentConfig.sandbox({
    required String consumerKey,
    required String consumerSecret,
    String baseUrl = 'https://sandbox-api.ugpayments.com',
    int timeoutSeconds = 30,
    bool enableDebugLogging = true,
  }) {
    return PaymentConfig(
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      baseUrl: baseUrl,
      environment: 'sandbox',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Creates a PaymentConfig for production environment.
  factory PaymentConfig.production({
    required String consumerKey,
    required String consumerSecret,
    String baseUrl = 'https://api.ugpayments.com',
    int timeoutSeconds = 30,
    bool enableDebugLogging = false,
  }) {
    return PaymentConfig(
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      baseUrl: baseUrl,
      environment: 'production',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Creates a PaymentConfig from a JSON map.
  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      consumerKey: json['consumerKey'] ?? '',
      consumerSecret: json['consumerSecret'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      environment: json['environment'] ?? 'production',
      timeoutSeconds: json['timeoutSeconds'] ?? 30,
      enableDebugLogging: json['enableDebugLogging'] ?? false,
      additionalConfig: json['additionalConfig'] != null
          ? Map<String, dynamic>.from(json['additionalConfig'])
          : null,
    );
  }

  /// Converts the PaymentConfig to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'consumerKey': consumerKey,
      'consumerSecret': consumerSecret,
      'baseUrl': baseUrl,
      'environment': environment,
      'timeoutSeconds': timeoutSeconds,
      'enableDebugLogging': enableDebugLogging,
      if (additionalConfig != null) 'additionalConfig': additionalConfig,
    };
  }

  /// Returns true if this is a sandbox configuration.
  bool get isSandbox => environment == 'sandbox';

  /// Returns true if this is a production configuration.
  bool get isProduction => environment == 'production';

  /// Returns true if this is a PesaPal configuration.
  bool get isPesaPal => additionalConfig?['provider'] == 'pesapal';

  /// Gets the callback URL for PesaPal.
  String? get callbackUrl => additionalConfig?['callback_url'];

  /// Gets the notification ID for PesaPal.
  String? get notificationId => additionalConfig?['notification_id'];

  @override
  String toString() {
    return 'PaymentConfig(environment: $environment, baseUrl: $baseUrl, provider: ${additionalConfig?['provider'] ?? 'generic'})';
  }
}
