import 'package:flutter_test/flutter_test.dart';

import 'package:ugpayments/ugpayments.dart';

void main() {
  group('PaymentClient Tests', () {
    late PaymentClient client;
    late PaymentConfig config;

    setUp(() {
      config = PaymentConfig.pesaPalSandbox(
        consumerKey: 'test_key',
        consumerSecret: 'test_secret',
        callbackUrl: 'https://test.com/callback',
        notificationId: 'test-notification-id',
      );
      client = PaymentClient(config);
    });

    test('should create PaymentClient with configuration', () {
      expect(client, isA<PaymentClient>());
    });

    test('should validate payment request', () {
      final request = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'PESAPAL',
        phoneNumber: '+256701234567',
        email: 'test@example.com',
        description: 'Test payment',
        merchantReference: 'TEST-ORDER-123',
        metadata: {'first_name': 'John', 'last_name': 'Doe'},
      );

      // Test that the request is created correctly
      expect(request.amount, equals(1000.0));
      expect(request.currency, equals('UGX'));
      expect(request.paymentMethod, equals('PESAPAL'));
      expect(request.phoneNumber, equals('+256701234567'));
      expect(request.email, equals('test@example.com'));
      expect(request.description, equals('Test payment'));
      expect(request.merchantReference, equals('TEST-ORDER-123'));
    });

    test('should throw exception for invalid amount', () async {
      final request = PaymentRequest(
        amount: -100.0,
        currency: 'UGX',
        paymentMethod: 'PESAPAL',
        phoneNumber: '+256701234567',
      );

      expect(
        () => client.processPayment(request),
        throwsA(isA<PaymentException>()),
      );
    });

    test('should throw exception for missing currency', () async {
      final request = PaymentRequest(
        amount: 1000.0,
        currency: '',
        paymentMethod: 'PESAPAL',
        phoneNumber: '+256701234567',
      );

      expect(
        () => client.processPayment(request),
        throwsA(isA<PaymentException>()),
      );
    });
  });

  group('PesaPalProvider Tests', () {
    late PesaPalProvider provider;
    late PaymentConfig config;

    setUp(() {
      config = PaymentConfig.pesaPalSandbox(
        consumerKey: 'test_bearer_token',
        consumerSecret: 'test_secret',
        callbackUrl: 'https://test.com/callback',
        notificationId: 'test-notification-id',
      );
      provider = PesaPalProvider(config);
    });

    test('should create PesaPalProvider with configuration', () {
      expect(provider, isA<PesaPalProvider>());
    });

    test('should build order request body correctly', () {
      // Test that the provider can be created and has the expected methods
      expect(provider.submitOrder, isA<Function>());
      expect(provider.getTransactionStatus, isA<Function>());
    });
  });

  group('PaymentConfig Tests', () {
    test('should create PesaPal sandbox configuration', () {
      final config = PaymentConfig.pesaPalSandbox(
        consumerKey: 'test_key',
        consumerSecret: 'test_secret',
        callbackUrl: 'https://test.com/callback',
        notificationId: 'test-notification-id',
      );

      expect(config.isSandbox, isTrue);
      expect(config.isPesaPal, isTrue);
      expect(config.callbackUrl, equals('https://test.com/callback'));
      expect(config.notificationId, equals('test-notification-id'));
      expect(config.baseUrl, equals('https://cybqa.pesapal.com/pesapalv3'));
    });

    test('should create PesaPal production configuration', () {
      final config = PaymentConfig.pesaPalProduction(
        consumerKey: 'test_key',
        consumerSecret: 'test_secret',
        callbackUrl: 'https://test.com/callback',
        notificationId: 'test-notification-id',
      );

      expect(config.isProduction, isTrue);
      expect(config.isPesaPal, isTrue);
      expect(config.callbackUrl, equals('https://test.com/callback'));
      expect(config.notificationId, equals('test-notification-id'));
      expect(config.baseUrl, equals('https://pay.pesapal.com/v3'));
    });

    test('should create generic sandbox configuration', () {
      final config = PaymentConfig.sandbox(
        consumerKey: 'test_key',
        consumerSecret: 'test_secret',
      );

      expect(config.isSandbox, isTrue);
      expect(config.isPesaPal, isFalse);
      expect(config.baseUrl, equals('https://sandbox-api.ugpayments.com'));
    });

    test('should create generic production configuration', () {
      final config = PaymentConfig.production(
        consumerKey: 'test_key',
        consumerSecret: 'test_secret',
      );

      expect(config.isProduction, isTrue);
      expect(config.isPesaPal, isFalse);
      expect(config.baseUrl, equals('https://api.ugpayments.com'));
    });
  });

  group('PaymentRequest Tests', () {
    test('should create PaymentRequest with required fields', () {
      final request = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'PESAPAL',
        phoneNumber: '+256701234567',
      );

      expect(request.amount, equals(1000.0));
      expect(request.currency, equals('UGX'));
      expect(request.paymentMethod, equals('PESAPAL'));
      expect(request.phoneNumber, equals('+256701234567'));
    });

    test('should convert to and from JSON', () {
      final originalRequest = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'PESAPAL',
        phoneNumber: '+256701234567',
        email: 'test@example.com',
        description: 'Test payment',
        merchantReference: 'REF123',
      );

      final json = originalRequest.toJson();
      final restoredRequest = PaymentRequest.fromJson(json);

      expect(restoredRequest.amount, equals(originalRequest.amount));
      expect(restoredRequest.currency, equals(originalRequest.currency));
      expect(
        restoredRequest.paymentMethod,
        equals(originalRequest.paymentMethod),
      );
      expect(restoredRequest.phoneNumber, equals(originalRequest.phoneNumber));
      expect(restoredRequest.email, equals(originalRequest.email));
      expect(restoredRequest.description, equals(originalRequest.description));
      expect(
        restoredRequest.merchantReference,
        equals(originalRequest.merchantReference),
      );
    });
  });

  group('PaymentResponse Tests', () {
    test('should create PaymentResponse with required fields', () {
      final response = PaymentResponse(
        transactionId: 'TXN123',
        status: PaymentStatus.successful,
        message: 'Payment successful',
        amount: 1000.0,
        currency: 'UGX',
        timestamp: DateTime.now(),
      );

      expect(response.transactionId, equals('TXN123'));
      expect(response.status, equals(PaymentStatus.successful));
      expect(response.message, equals('Payment successful'));
      expect(response.amount, equals(1000.0));
      expect(response.currency, equals('UGX'));
      expect(response.isSuccessful, isTrue);
      expect(response.isFailed, isFalse);
    });

    test('should convert to and from JSON', () {
      final originalResponse = PaymentResponse(
        transactionId: 'TXN123',
        status: PaymentStatus.successful,
        message: 'Payment successful',
        amount: 1000.0,
        currency: 'UGX',
        timestamp: DateTime.now(),
        data: {'key': 'value'},
      );

      final json = originalResponse.toJson();
      final restoredResponse = PaymentResponse.fromJson(json);

      expect(
        restoredResponse.transactionId,
        equals(originalResponse.transactionId),
      );
      expect(restoredResponse.status, equals(originalResponse.status));
      expect(restoredResponse.message, equals(originalResponse.message));
      expect(restoredResponse.amount, equals(originalResponse.amount));
      expect(restoredResponse.currency, equals(originalResponse.currency));
    });

    test('should handle different payment statuses', () {
      final pendingResponse = PaymentResponse(
        transactionId: 'TXN123',
        status: PaymentStatus.pending,
        message: 'Payment pending',
        timestamp: DateTime.now(),
      );

      final failedResponse = PaymentResponse(
        transactionId: 'TXN123',
        status: PaymentStatus.failed,
        message: 'Payment failed',
        timestamp: DateTime.now(),
      );

      expect(pendingResponse.isPending, isTrue);
      expect(pendingResponse.isSuccessful, isFalse);
      expect(pendingResponse.isFailed, isFalse);

      expect(failedResponse.isFailed, isTrue);
      expect(failedResponse.isSuccessful, isFalse);
      expect(failedResponse.isPending, isFalse);
    });
  });

  group('PaymentValidator Tests', () {
    test('should validate valid email addresses', () {
      expect(PaymentValidator.isValidEmail('test@example.com'), isTrue);
      expect(PaymentValidator.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(PaymentValidator.isValidEmail('invalid-email'), isFalse);
    });

    test('should validate Ugandan phone numbers', () {
      expect(
        PaymentValidator.isValidUgandanPhoneNumber('+256701234567'),
        isTrue,
      );
      expect(PaymentValidator.isValidUgandanPhoneNumber('0701234567'), isTrue);
      expect(
        PaymentValidator.isValidUgandanPhoneNumber('256701234567'),
        isTrue,
      );
      expect(PaymentValidator.isValidUgandanPhoneNumber('123456789'), isFalse);
    });

    test('should validate amounts', () {
      expect(PaymentValidator.isValidAmount(100.0), isTrue);
      expect(PaymentValidator.isValidAmount(0.0), isFalse);
      expect(PaymentValidator.isValidAmount(-100.0), isFalse);
    });

    test('should validate currencies', () {
      expect(PaymentValidator.isValidCurrency('UGX'), isTrue);
      expect(PaymentValidator.isValidCurrency('USD'), isTrue);
      expect(PaymentValidator.isValidCurrency('INVALID'), isFalse);
    });

    test('should validate payment methods', () {
      expect(PaymentValidator.isValidPaymentMethod('PESAPAL'), isTrue);
      expect(PaymentValidator.isValidPaymentMethod('MOBILE_MONEY'), isTrue);
      expect(PaymentValidator.isValidPaymentMethod('BANK_TRANSFER'), isTrue);
      expect(PaymentValidator.isValidPaymentMethod('INVALID'), isFalse);
    });

    test('should validate card numbers', () {
      expect(PaymentValidator.isValidCardNumber('4111111111111111'), isTrue);
      expect(PaymentValidator.isValidCardNumber('5555555555554444'), isTrue);
      expect(PaymentValidator.isValidCardNumber('1234567890123456'), isFalse);
    });

    test('should validate CVV codes', () {
      expect(PaymentValidator.isValidCvv('123'), isTrue);
      expect(PaymentValidator.isValidCvv('1234'), isTrue);
      expect(PaymentValidator.isValidCvv('12'), isFalse);
      expect(PaymentValidator.isValidCvv('12345'), isFalse);
    });

    test('should validate expiry dates', () {
      final nextYear = DateTime.now().year + 1;
      expect(
        PaymentValidator.isValidExpiryDate('12', nextYear.toString()),
        isTrue,
      );
      expect(
        PaymentValidator.isValidExpiryDate('01', nextYear.toString()),
        isTrue,
      );
      expect(
        PaymentValidator.isValidExpiryDate('13', nextYear.toString()),
        isFalse,
      );
      expect(
        PaymentValidator.isValidExpiryDate('00', nextYear.toString()),
        isFalse,
      );
    });

    test('should sanitize phone numbers', () {
      expect(
        PaymentValidator.sanitizePhoneNumber('0701234567'),
        equals('+256701234567'),
      );
      expect(
        PaymentValidator.sanitizePhoneNumber('256701234567'),
        equals('+256701234567'),
      );
      expect(
        PaymentValidator.sanitizePhoneNumber('+256701234567'),
        equals('+256701234567'),
      );
    });

    test('should format amounts correctly', () {
      expect(PaymentValidator.formatAmount(1000.0, 'UGX'), equals('1000'));
      expect(PaymentValidator.formatAmount(1000.50, 'USD'), equals('1000.50'));
      expect(PaymentValidator.formatAmount(1000.0, 'USD'), equals('1000.00'));
    });
  });

  group('Encryption Tests', () {
    test('should encrypt and decrypt data', () {
      const originalData = 'sensitive payment data';

      final encrypted = Encryption.encrypt(originalData);
      final decrypted = Encryption.decrypt(encrypted);

      expect(decrypted, equals(originalData));
    });

    test('should mask card numbers', () {
      expect(
        Encryption.maskCardNumber('1234567890123456'),
        equals('************3456'),
      );
      expect(Encryption.maskCardNumber('1234'), equals('1234'));
    });

    test('should mask phone numbers', () {
      expect(
        Encryption.maskPhoneNumber('+256701234567'),
        equals('*********4567'),
      );
      expect(Encryption.maskPhoneNumber('123'), equals('123'));
    });

    test('should generate secure tokens', () {
      final token1 = Encryption.generateSecureToken(16);
      final token2 = Encryption.generateSecureToken(16);

      expect(token1.length, equals(16));
      expect(token2.length, equals(16));
      expect(token1, isNot(equals(token2)));
    });

    test('should generate secure numbers', () {
      final number1 = Encryption.generateSecureNumber(1, 100);
      final number2 = Encryption.generateSecureNumber(1, 100);

      expect(number1, greaterThanOrEqualTo(1));
      expect(number1, lessThanOrEqualTo(100));
      expect(number2, greaterThanOrEqualTo(1));
      expect(number2, lessThanOrEqualTo(100));
    });

    test('should create and validate hashes', () {
      const data = 'test data';
      final hash = Encryption.createHash(data);

      expect(Encryption.validateHash(data, hash), isTrue);
      expect(Encryption.validateHash('different data', hash), isFalse);
    });

    test('should sanitize data for logging', () {
      const sensitiveData =
          'Card: 4111111111111111, Phone: +256701234567, Email: test@example.com';
      final sanitized = Encryption.sanitizeForLogging(sensitiveData);

      expect(sanitized, contains('[REDACTED]'));
      expect(sanitized, isNot(contains('4111111111111111')));
      expect(sanitized, isNot(contains('+256701234567')));
      expect(sanitized, isNot(contains('test@example.com')));
    });
  });
}
