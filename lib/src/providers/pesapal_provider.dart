import 'dart:convert';
import 'dart:io';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../core/payment_config.dart';
import '../core/payment_exception.dart';
import '../core/token_manager.dart';
import '../utils/encryption.dart';
import '../core/http_client_factory.dart';

/// PesaPal payment provider implementation.
class PesaPalProvider {
  final PaymentConfig _config;
  final HttpClient _httpClient;
  final TokenManager _tokenManager;

  /// Creates a new PesaPal provider.
  PesaPalProvider(this._config)
    : _httpClient = HttpClientFactory.createForConfig(_config),
      _tokenManager = TokenManager(_config);

  /// Submits a payment order to PesaPal.
  Future<PaymentResponse> submitOrder(PaymentRequest request) async {
    try {
      // Get authentication token
      final token = await _tokenManager.getToken();

      // Ensure we have a valid `notification_id` by registering an IPN URL
      // when it isn't provided by the consumer of the package.
      final notificationId = await _resolveNotificationId(token);

      final url = Uri.parse(
        '${_config.baseUrl}/api/Transactions/SubmitOrderRequest',
      );

      final requestBody = _buildOrderRequestBody(request, notificationId);

      final httpRequest = await _httpClient.postUrl(url);
      httpRequest.headers.set('Authorization', 'Bearer $token');
      httpRequest.headers.set('Content-Type', 'application/json');
      httpRequest.write(json.encode(requestBody));

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;
        return _parseOrderResponse(data, request);
      } else {
        throw PaymentException(
          'PesaPal API error: ${response.statusCode} - '
          '${Encryption.sanitizeForLogging(responseBody)}',
        );
      }
    } catch (e) {
      throw PaymentException(
        'Failed to submit order to PesaPal: ${Encryption.sanitizeForLogging(e.toString())}',
      );
    }
  }

  /// Gets the status of a transaction.
  Future<PaymentResponse> getTransactionStatus(String orderTrackingId) async {
    try {
      // Get authentication token
      final token = await _tokenManager.getToken();

      final url = Uri.parse(
        '${_config.baseUrl}/api/Transactions/GetTransactionStatus?orderTrackingId=$orderTrackingId',
      );

      final request = await _httpClient.getUrl(url);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;
        return _parseStatusResponse(data);
      } else {
        throw PaymentException(
          'Failed to get transaction status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw PaymentException('Failed to get transaction status: $e');
    }
  }

  /// Builds the order request body for PesaPal API.
  Map<String, dynamic> _buildOrderRequestBody(
    PaymentRequest request,
    String notificationId,
  ) {
    return {
      'id': request.merchantReference ?? _generateMerchantReference(),
      'currency': request.currency,
      'amount': request.amount,
      'description': request.description ?? 'Payment via ugpayments',
      'callback_url':
          _config.callbackUrl ?? 'https://www.myapplication.com/response-page',
      'notification_id': notificationId,
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
  }

  /// Parses the order submission response from PesaPal.
  PaymentResponse _parseOrderResponse(
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
        'provider': 'pesapal',
      },
    );
  }

  /// Parses the transaction status response from PesaPal.
  PaymentResponse _parseStatusResponse(Map<String, dynamic> data) {
    final orderTrackingId = data['order_tracking_id'] as String?;
    final merchantReference = data['merchant_reference'] as String?;
    final paymentStatus = data['payment_status'] as String?;
    final paymentMethod = data['payment_method'] as String?;
    final amount = data['amount'] as double?;
    final currency = data['currency'] as String?;

    PaymentStatus status;
    String message;

    switch (paymentStatus?.toLowerCase()) {
      case 'completed':
        status = PaymentStatus.successful;
        message = 'Payment completed successfully';
        break;
      case 'pending':
        status = PaymentStatus.pending;
        message = 'Payment is pending';
        break;
      case 'failed':
        status = PaymentStatus.failed;
        message = 'Payment failed';
        break;
      case 'cancelled':
        status = PaymentStatus.cancelled;
        message = 'Payment was cancelled';
        break;
      default:
        status = PaymentStatus.pending;
        message = 'Payment status: $paymentStatus';
    }

    return PaymentResponse(
      transactionId: orderTrackingId ?? _generateTransactionId(),
      status: status,
      message: message,
      amount: amount,
      currency: currency,
      timestamp: DateTime.now(),
      data: {
        'merchant_reference': merchantReference,
        'payment_method': paymentMethod,
        'pesapal_status': paymentStatus,
        'provider': 'pesapal',
      },
    );
  }

  /// Generates a unique transaction ID.
  String _generateTransactionId() {
    return 'PESAPAL_${Encryption.generateUuidV4()}';
  }

  /// Generates a merchant reference.
  String _generateMerchantReference() {
    return 'REF_${Encryption.generateUuidV4()}';
  }

  /// Resolves a valid PesaPal `notification_id`.
  ///
  /// Returns the configured `notificationId` if present, otherwise
  /// registers `ipnUrl` (or `callbackUrl`) with PesaPal's `RegisterIPN`
  /// endpoint and returns the `ipn_id` PesaPal assigns to it.
  Future<String> _resolveNotificationId(String token) async {
    final existing = _config.notificationId;
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final ipnUrl = _config.ipnUrl;
    if (ipnUrl == null || ipnUrl.trim().isEmpty) {
      throw PaymentException(
        'Missing IPN URL. Provide callbackUrl (used as IPN url by default) or set ipnUrl in PaymentConfig.',
      );
    }

    return _registerIpnAndReturnId(
      token: token,
      ipnUrl: ipnUrl,
      ipnNotificationType: _config.ipnNotificationType,
    );
  }

  Future<String> _registerIpnAndReturnId({
    required String token,
    required String ipnUrl,
    required String ipnNotificationType,
  }) async {
    try {
      final httpRequest = await _httpClient.postUrl(_config.pesaPalRegisterIpnUri);
      httpRequest.headers.set('Authorization', 'Bearer $token');
      httpRequest.headers.set('Accept', 'application/json');
      httpRequest.headers.set('Content-Type', 'application/json');

      httpRequest.write(
        json.encode({
          'url': ipnUrl,
          'ipn_notification_type': ipnNotificationType,
        }),
      );

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw PaymentException(
          'Failed to register IPN: ${response.statusCode} - '
          '${Encryption.sanitizeForLogging(responseBody)}',
        );
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;
      final ipnId = data['ipn_id'] as String?;
      if (ipnId == null || ipnId.trim().isEmpty) {
        throw PaymentException(
          'IPN registration succeeded but ipn_id was missing. Response: $data',
        );
      }

      return ipnId;
    } catch (e) {
      throw PaymentException(
        'Failed to register IPN: ${Encryption.sanitizeForLogging(e.toString())}',
      );
    }
  }

  /// Clears cached auth token (and removes it from secure storage if present).
  void clearToken() {
    _tokenManager.clearToken();
  }

  /// Disposes the HTTP client and token manager.
  void dispose() {
    _httpClient.close();
    _tokenManager.dispose();
  }
}
