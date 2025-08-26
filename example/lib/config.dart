/// Configuration file for PesaPal credentials and settings.
///
/// IMPORTANT: Replace the placeholder values with your actual PesaPal credentials.
/// Never commit real credentials to version control.
class PesaPalConfig {
  // ============================================================================
  // SANDBOX CREDENTIALS (FOR TESTING)
  // ============================================================================

  /// Your PesaPal sandbox consumer key
  /// Get this from your PesaPal sandbox dashboard
  static const String sandboxConsumerKey = 'your_sandbox_consumer_key_here';

  /// Your PesaPal sandbox consumer secret
  /// Get this from your PesaPal sandbox dashboard
  static const String sandboxConsumerSecret =
      'your_sandbox_consumer_secret_here';

  /// Your callback URL for sandbox testing
  /// This should be a URL that can receive payment notifications
  static const String sandboxCallbackUrl =
      'https://your-app.com/sandbox-callback';

  /// Your notification ID for sandbox testing
  /// Get this from your PesaPal sandbox dashboard
  static const String sandboxNotificationId =
      'your_sandbox_notification_id_here';

  // ============================================================================
  // PRODUCTION CREDENTIALS (FOR LIVE PAYMENTS)
  // ============================================================================

  /// Your PesaPal production consumer key
  /// Get this from your PesaPal production dashboard
  static const String productionConsumerKey =
      'your_production_consumer_key_here';

  /// Your PesaPal production consumer secret
  /// Get this from your PesaPal production dashboard
  static const String productionConsumerSecret =
      'your_production_consumer_secret_here';

  /// Your callback URL for production
  /// This should be a URL that can receive payment notifications
  static const String productionCallbackUrl =
      'https://your-app.com/production-callback';

  /// Your notification ID for production
  /// Get this from your PesaPal production dashboard
  static const String productionNotificationId =
      'your_production_notification_id_here';

  // ============================================================================
  // ENVIRONMENT SETTINGS
  // ============================================================================

  /// Set to true to use production environment, false for sandbox
  /// WARNING: Only set to true when you're ready for live payments
  static const bool useProduction = false;

  /// Enable debug logging for API requests and responses
  /// Set to false in production for security
  static const bool enableDebugLogging = true;

  /// Timeout for API requests in seconds
  static const int timeoutSeconds = 30;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the current consumer key based on environment
  static String get consumerKey =>
      useProduction ? productionConsumerKey : sandboxConsumerKey;

  /// Get the current consumer secret based on environment
  static String get consumerSecret =>
      useProduction ? productionConsumerSecret : sandboxConsumerSecret;

  /// Get the current callback URL based on environment
  static String get callbackUrl =>
      useProduction ? productionCallbackUrl : sandboxCallbackUrl;

  /// Get the current notification ID based on environment
  static String get notificationId =>
      useProduction ? productionNotificationId : sandboxNotificationId;

  /// Get the current environment name
  static String get environment => useProduction ? 'Production' : 'Sandbox';

  /// Get the current base URL
  static String get baseUrl => useProduction
      ? 'https://pay.pesapal.com/v3'
      : 'https://cybqa.pesapal.com/pesapalv3';

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// Check if credentials are properly configured
  static bool get isConfigured {
    if (useProduction) {
      return productionConsumerKey != 'your_production_consumer_key_here' &&
          productionConsumerSecret != 'your_production_consumer_secret_here';
    } else {
      return sandboxConsumerKey != 'your_sandbox_consumer_key_here' &&
          sandboxConsumerSecret != 'your_sandbox_consumer_secret_here';
    }
  }

  /// Get configuration status message
  static String get configurationStatus {
    if (!isConfigured) {
      return '❌ Credentials not configured. Please update config.dart with your PesaPal credentials.';
    }
    return '✅ Credentials configured for $environment environment.';
  }

  // ============================================================================
  // SECURITY WARNINGS
  // ============================================================================

  /// Security warning message
  static const String securityWarning = '''
⚠️ SECURITY WARNING ⚠️

1. Never commit real credentials to version control
2. Use environment variables in production
3. Keep your consumer keys and secrets secure
4. Regularly rotate your credentials
5. Monitor your API usage

For production apps, consider using:
- Environment variables
- Secure key storage
- Credential rotation
- Request signing
''';
}
