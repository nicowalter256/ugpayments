/// Configuration settings for the payment client.
class PaymentConfig {
  /// The API key for authentication.
  final String apiKey;

  /// The API secret for authentication.
  final String apiSecret;

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
    required this.apiKey,
    required this.apiSecret,
    required this.baseUrl,
    this.environment = 'production',
    this.timeoutSeconds = 30,
    this.enableDebugLogging = false,
    this.additionalConfig,
  });

  /// Creates a PaymentConfig for sandbox/testing environment.
  factory PaymentConfig.sandbox({
    required String apiKey,
    required String apiSecret,
    String baseUrl = 'https://sandbox-api.ugpayments.com',
    int timeoutSeconds = 30,
    bool enableDebugLogging = true,
  }) {
    return PaymentConfig(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      environment: 'sandbox',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Creates a PaymentConfig for production environment.
  factory PaymentConfig.production({
    required String apiKey,
    required String apiSecret,
    String baseUrl = 'https://api.ugpayments.com',
    int timeoutSeconds = 30,
    bool enableDebugLogging = false,
  }) {
    return PaymentConfig(
      apiKey: apiKey,
      apiSecret: apiSecret,
      baseUrl: baseUrl,
      environment: 'production',
      timeoutSeconds: timeoutSeconds,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Creates a PaymentConfig from a JSON map.
  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    return PaymentConfig(
      apiKey: json['apiKey'] ?? '',
      apiSecret: json['apiSecret'] ?? '',
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
      'apiKey': apiKey,
      'apiSecret': apiSecret,
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

  @override
  String toString() {
    return 'PaymentConfig(environment: $environment, baseUrl: $baseUrl)';
  }
}
