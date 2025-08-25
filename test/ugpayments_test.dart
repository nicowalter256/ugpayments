import 'package:flutter_test/flutter_test.dart';

import 'package:ugpayments/ugpayments.dart';

void main() {
  group('PaymentClient Tests', () {
    late PaymentClient client;
    late PaymentConfig config;

    setUp(() {
      config = PaymentConfig.sandbox(
        apiKey: 'test_key',
        apiSecret: 'test_secret',
      );
      client = PaymentClient(config);
    });

    test('should create PaymentClient with configuration', () {
      expect(client, isA<PaymentClient>());
    });

    test('should process mobile money payment', () async {
      final request = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'MOBILE_MONEY',
        phoneNumber: '+256701234567',
        description: 'Test payment',
      );

      final response = await client.processPayment(request);

      expect(response, isA<PaymentResponse>());
      expect(response.transactionId, isNotEmpty);
      expect(response.status, isA<PaymentStatus>());
      expect(response.message, isNotEmpty);
    });

    test('should throw exception for invalid amount', () async {
      final request = PaymentRequest(
        amount: -100.0,
        currency: 'UGX',
        paymentMethod: 'MOBILE_MONEY',
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
        paymentMethod: 'MOBILE_MONEY',
        phoneNumber: '+256701234567',
      );

      expect(
        () => client.processPayment(request),
        throwsA(isA<PaymentException>()),
      );
    });
  });

  group('PaymentRequest Tests', () {
    test('should create PaymentRequest with required fields', () {
      final request = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'MOBILE_MONEY',
        phoneNumber: '+256701234567',
      );

      expect(request.amount, equals(1000.0));
      expect(request.currency, equals('UGX'));
      expect(request.paymentMethod, equals('MOBILE_MONEY'));
      expect(request.phoneNumber, equals('+256701234567'));
    });

    test('should convert to and from JSON', () {
      final originalRequest = PaymentRequest(
        amount: 1000.0,
        currency: 'UGX',
        paymentMethod: 'MOBILE_MONEY',
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
      expect(PaymentValidator.isValidPaymentMethod('MOBILE_MONEY'), isTrue);
      expect(PaymentValidator.isValidPaymentMethod('BANK_TRANSFER'), isTrue);
      expect(PaymentValidator.isValidPaymentMethod('INVALID'), isFalse);
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
  });
}
