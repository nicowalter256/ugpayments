import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ugpayments/ugpayments.dart';

/// A local stand-in for the PesaPal v3 API.
class _FakePesaPal {
  late final HttpServer _server;

  /// Body returned by `GetTransactionStatus`.
  Map<String, dynamic> statusBody = {};

  /// Delay applied before every response.
  Duration delay = Duration.zero;

  final List<Uri> requests = [];

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      requests.add(req.uri);
      await Future<void>.delayed(delay);
      final body = switch (req.uri.path) {
        '/api/Auth/RequestToken' => {
          'token': 'test-token',
          'expiryDate': DateTime.now()
              .add(const Duration(minutes: 5))
              .toUtc()
              .toIso8601String(),
          'error': null,
          'status': '200',
        },
        '/api/Transactions/SubmitOrderRequest' => {
          'order_tracking_id': 'track-123',
          'merchant_reference': 'ORDER-1',
          'redirect_url': 'https://cybqa.pesapal.com/pesapaliframe/x',
          'error': null,
          'status': '200',
        },
        '/api/Transactions/GetTransactionStatus' => statusBody,
        _ => {'error': 'not found'},
      };
      try {
        req.response
          ..headers.contentType = ContentType.json
          ..write(json.encode(body));
        await req.response.close();
      } catch (_) {
        // Client aborted (timeout tests).
      }
    });
  }

  Future<void> stop() => _server.close(force: true);
}

/// A PesaPal v3 `GetTransactionStatus` response body.
Map<String, dynamic> _status({
  required String description,
  required int statusCode,
  Object amount = 1000,
}) => {
  'payment_method': 'MTN UG',
  'amount': amount,
  'created_date': '2026-10-06T10:00:00.000',
  'confirmation_code': 'CONF-1',
  'payment_status_description': description,
  'description': '',
  'message': 'Request processed successfully',
  'payment_account': '2567XXXXX123',
  'call_back_url': 'https://test.com/callback?OrderTrackingId=track-123',
  'status_code': statusCode,
  'merchant_reference': 'ORDER-1',
  'payment_status_code': '',
  'currency': 'UGX',
  'error': {
    'error_type': null,
    'code': null,
    'message': null,
    'call_back_url': null,
  },
  'status': '200',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding stubs every HttpClient to return 400; these tests talk
  // to a real local server instead.
  HttpOverrides.global = null;

  late _FakePesaPal pesapal;

  PaymentConfig config({int timeoutSeconds = 30}) =>
      PaymentConfig.pesaPalSandbox(
        consumerKey: 'key',
        consumerSecret: 'secret',
        baseUrl: pesapal.baseUrl,
        callbackUrl: 'https://test.com/callback',
        notificationId: 'ipn-1',
        timeoutSeconds: timeoutSeconds,
      );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    pesapal = _FakePesaPal();
    await pesapal.start();
  });

  tearDown(() => pesapal.stop());

  group('GetTransactionStatus parsing', () {
    final cases = {
      ('Completed', 1): PaymentStatus.successful,
      ('Failed', 2): PaymentStatus.failed,
      ('Reversed', 3): PaymentStatus.refunded,
      ('INVALID', 0): PaymentStatus.pending,
    };

    cases.forEach((input, expected) {
      test('maps ${input.$1} to $expected', () async {
        pesapal.statusBody = _status(
          description: input.$1,
          statusCode: input.$2,
        );
        final provider = PesaPalProvider(config());
        addTearDown(provider.dispose);

        final response = await provider.getTransactionStatus('track-123');

        expect(response.status, expected);
        expect(response.transactionId, 'track-123');
      });
    });

    test('accepts integer amounts', () async {
      pesapal.statusBody = _status(
        description: 'Completed',
        statusCode: 1,
        amount: 1000,
      );
      final client = PaymentClient(config());
      addTearDown(client.dispose);

      final transaction = await client.getTransaction('track-123');

      expect(transaction!.amount, 1000.0);
      expect(transaction.status, PaymentStatus.successful);
      expect(transaction.paymentMethod, 'MTN UG');
      expect(transaction.merchantReference, 'ORDER-1');
    });

    test('URL-encodes the tracking id', () async {
      pesapal.statusBody = _status(description: 'Completed', statusCode: 1);
      final provider = PesaPalProvider(config());
      addTearDown(provider.dispose);

      await provider.getTransactionStatus('a&b=c');

      final statusRequest = pesapal.requests.last;
      expect(statusRequest.queryParameters['orderTrackingId'], 'a&b=c');
    });

    test('throws when PesaPal reports an error', () async {
      pesapal.statusBody = {
        ..._status(description: '', statusCode: 0),
        'error': {
          'error_type': 'api_error',
          'code': 'payment_details_not_found',
          'message': 'Pending Payment',
        },
        'status': '500',
      };
      final provider = PesaPalProvider(config());
      addTearDown(provider.dispose);

      expect(
        provider.getTransactionStatus('track-123'),
        throwsA(
          isA<PaymentApiException>().having(
            (e) => e.code,
            'code',
            'payment_details_not_found',
          ),
        ),
      );
    });
  });

  test('submitOrder returns the redirect URL', () async {
    final client = PaymentClient(config());
    addTearDown(client.dispose);

    final response = await client.processPayment(
      PaymentRequest(amount: 1000, currency: 'UGX', paymentMethod: 'PESAPAL'),
    );

    expect(response.isPending, isTrue);
    expect(response.transactionId, 'track-123');
    expect(response.data?['redirect_url'], startsWith('https://'));
  });

  test(
    'requests exceeding timeoutSeconds throw PaymentTimeoutException',
    () async {
      pesapal.delay = const Duration(seconds: 3);
      final provider = PesaPalProvider(config(timeoutSeconds: 1));
      addTearDown(provider.dispose);

      await expectLater(
        provider.getTransactionStatus('track-123'),
        throwsA(isA<PaymentTimeoutException>()),
      );
    },
  );

  group('production TLS pinning', () {
    test('fails closed without pins', () {
      expect(
        () => PaymentClient(
          PaymentConfig.pesaPalProduction(
            consumerKey: 'key',
            consumerSecret: 'secret',
          ),
        ),
        throwsA(
          isA<PaymentApiException>().having(
            (e) => e.code,
            'code',
            'TLS_PINNING_REQUIRED',
          ),
        ),
      );
    });

    test('factory passes pins through to the config', () {
      final config = PaymentConfig.pesaPalProductionFromSecureStorage(
        consumerKeyStorageKey: 'k',
        consumerSecretStorageKey: 's',
        pinnedCertificatesPem: const ['PEM'],
      );

      expect(config.additionalConfig?['pesapal_pinned_certs_pem'], ['PEM']);
      expect(config.additionalConfig?['pesapal_consumerKey_storageKey'], 'k');
    });
  });
}
