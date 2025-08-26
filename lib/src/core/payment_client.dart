import 'dart:convert';
import 'dart:io';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../models/transaction.dart';
import 'payment_config.dart';
import 'payment_exception.dart';
import 'token_manager.dart';

/// Main client for handling payment operations in Uganda.
class PaymentClient {
  final PaymentConfig _config;
  final HttpClient _httpClient;
  final TokenManager _tokenManager;

  /// Creates a new PaymentClient with the given configuration.
  PaymentClient(this._config)
    : _httpClient = HttpClient(),
      _tokenManager = TokenManager(_config);

  /// Processes a payment request using PesaPal API.
  ///
  /// Returns a [PaymentResponse] with the result of the payment operation.
  ///
  /// Throws [PaymentException] if the payment fails.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // Validate the payment request
      _validateRequest(request);

      // Process the payment using PesaPal API
      final response = await _submitOrderToPesaPal(request);

      return response;
    } catch (e) {
      throw PaymentException('Payment processing failed: $e');
    }
  }

  /// Retrieves transaction details by transaction ID.
  Future<Transaction?> getTransaction(String transactionId) async {
    try {
      // Get authentication token
      final token = await _tokenManager.getToken();

      final url = Uri.parse(
        '${_config.baseUrl}/api/Transactions/GetTransactionStatus?orderTrackingId=$transactionId',
      );

      final request = await _httpClient.getUrl(url);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;
        return _parseTransactionFromPesaPal(data);
      } else {
        throw PaymentException(
          'Failed to retrieve transaction: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw PaymentException('Failed to retrieve transaction: $e');
    }
  }

  /// Validates a payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.amount <= 0) {
      throw PaymentException('Amount must be greater than 0');
    }

    if (request.currency.isEmpty) {
      throw PaymentException('Currency is required');
    }

    if (request.paymentMethod.isEmpty) {
      throw PaymentException('Payment method is required');
    }
  }

  /// Submits an order to PesaPal API.
  Future<PaymentResponse> _submitOrderToPesaPal(PaymentRequest request) async {
    final url = Uri.parse(
      '${_config.baseUrl}/v3/api/Transactions/SubmitOrderRequest',
    );

    final requestBody = {
      'id': request.merchantReference ?? _generateMerchantReference(),
      'currency': request.currency,
      'amount': request.amount,
      'description': request.description ?? 'Payment via ugpayments',
      'callback_url':
          _config.additionalConfig?['callback_url'] ??
          'https://www.myapplication.com/response-page',
      'notification_id':
          _config.additionalConfig?['notification_id'] ??
          _generateNotificationId(),
      'billing_address': {
        'email_address': request.email ?? '',
        'phone_number': request.phoneNumber ?? '',
        'country_code': 'UG',
        'first_name': request.metadata?['first_name'] ?? '',
        'middle_name': request.metadata?['middle_name'] ?? '',
        'last_name': request.metadata?['last_name'] ?? '',
        'line_1': request.metadata?['line_1'] ?? '',
        'line_2': request.metadata?['line_2'] ?? '',
        'city': request.metadata?['city'] ?? '',
        'state': request.metadata?['state'] ?? '',
        'postal_code': request.metadata?['postal_code'] ?? '',
        'zip_code': request.metadata?['zip_code'] ?? '',
      },
    };

    // Get authentication token
    final token = await _tokenManager.getToken();

    final httpRequest = await _httpClient.postUrl(url);
    httpRequest.headers.set('Authorization', 'Bearer $token');
    httpRequest.headers.set('Content-Type', 'application/json');
    httpRequest.write(json.encode(requestBody));

    final response = await httpRequest.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      return _parsePesaPalResponse(data, request);
    } else {
      throw PaymentException(
        'PesaPal API error: ${response.statusCode} - $responseBody',
      );
    }
  }

  /// Parses PesaPal API response into PaymentResponse.
  PaymentResponse _parsePesaPalResponse(
    Map<String, dynamic> data,
    PaymentRequest originalRequest,
  ) {
    final orderTrackingId = data['order_tracking_id'] as String?;
    final merchantReference = data['merchant_reference'] as String?;
    final redirectUrl = data['redirect_url'] as String?;
    final error = data['error'];
    final status = data['status'] as String?;

    if (error != null) {
      throw PaymentException('PesaPal error: $error');
    }

    if (status != '200') {
      throw PaymentException('PesaPal API returned status: $status');
    }

    return PaymentResponse(
      transactionId: orderTrackingId ?? _generateTransactionId(),
      status: PaymentStatus.pending,
      message: 'Payment submitted successfully. Redirect to complete payment.',
      amount: originalRequest.amount,
      currency: originalRequest.currency,
      timestamp: DateTime.now(),
      data: {
        'merchant_reference': merchantReference,
        'redirect_url': redirectUrl,
        'pesapal_status': status,
      },
    );
  }

  /// Parses PesaPal transaction data into Transaction model.
  Transaction? _parseTransactionFromPesaPal(Map<String, dynamic> data) {
    // This would parse the actual PesaPal transaction response
    // Implementation depends on the actual response format
    return null;
  }

  /// Generates a unique transaction ID.
  String _generateTransactionId() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generates a merchant reference.
  String _generateMerchantReference() {
    return 'REF_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generates a notification ID.
  String _generateNotificationId() {
    return 'NOTIF_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Disposes the HTTP client and token manager.
  void dispose() {
    _httpClient.close();
    _tokenManager.dispose();
  }
}
