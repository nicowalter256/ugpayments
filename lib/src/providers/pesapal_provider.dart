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
final class PesaPalProvider {
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

      final response = await HttpClientFactory.send(
        _httpClient,
        method: 'POST',
        uri: _config.pesaPalSubmitOrderRequestUri,
        timeout: _config.timeout,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        jsonBody: _buildOrderRequestBody(request, notificationId),
      );
      final responseBody = response.body;

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;
        return _parseOrderResponse(data, request);
      } else {
        throw PaymentException.api(
          'PesaPal API error: ${response.statusCode} - '
          '${Encryption.sanitizeForLogging(responseBody)}',
        );
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException.api(
        'Failed to submit order to PesaPal: ${Encryption.sanitizeForLogging(e.toString())}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Gets the status of a transaction.
  Future<PaymentResponse> getTransactionStatus(String orderTrackingId) async {
    try {
      // Get authentication token
      final token = await _tokenManager.getToken();

      final response = await HttpClientFactory.send(
        _httpClient,
        method: 'GET',
        uri: _config.pesaPalGetTransactionStatusUri(orderTrackingId),
        timeout: _config.timeout,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _parseStatusResponse(data, orderTrackingId);
      } else {
        throw PaymentException.api(
          'Failed to get transaction status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException.api(
        'Failed to get transaction status: ${Encryption.sanitizeForLogging(e.toString())}',
        originalException: e is Exception ? e : null,
      );
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
      throw PaymentException.api('PesaPal error: $error');
    }

    if (status != '200') {
      throw PaymentException.api('PesaPal API returned status: $status');
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
  ///
  /// PesaPal v3 reports the outcome as `payment_status_description`
  /// (`Completed`, `Failed`, `Reversed`, `Invalid`) alongside a numeric
  /// `status_code` (1, 2, 3, 0). The response does not echo the tracking ID,
  /// so the one that was looked up is passed in.
  PaymentResponse _parseStatusResponse(
    Map<String, dynamic> data,
    String orderTrackingId,
  ) {
    final apiError = data['error'];
    if (apiError is Map &&
        (apiError['code'] != null || apiError['message'] != null)) {
      throw PaymentException.api(
        'PesaPal status error: ${apiError['message'] ?? apiError['code']}',
        code: apiError['code']?.toString(),
      );
    }

    final merchantReference = data['merchant_reference']?.toString();
    final paymentMethod = data['payment_method']?.toString();
    final description =
        (data['payment_status_description'] ?? data['payment_status'])
            ?.toString();
    final statusCode = data['status_code'] is num
        ? (data['status_code'] as num).toInt()
        : int.tryParse('${data['status_code']}');
    final amount = data['amount'] is num
        ? (data['amount'] as num).toDouble()
        : double.tryParse('${data['amount']}');
    final currency = data['currency']?.toString();

    final (status, message) = switch ((
      description?.toLowerCase(),
      statusCode,
    )) {
      ('completed', _) ||
      (null, 1) => (PaymentStatus.successful, 'Payment completed successfully'),
      ('failed', _) || (null, 2) => (PaymentStatus.failed, 'Payment failed'),
      ('reversed', _) ||
      (null, 3) => (PaymentStatus.refunded, 'Payment was reversed'),
      ('cancelled', _) => (PaymentStatus.cancelled, 'Payment was cancelled'),
      // `Invalid` is what PesaPal reports for an order the customer hasn't
      // paid yet, so treat it as still pending rather than failed.
      _ => (
        PaymentStatus.pending,
        'Payment status: ${description ?? 'unknown'}',
      ),
    };

    return PaymentResponse(
      transactionId: orderTrackingId,
      status: status,
      message: message,
      amount: amount,
      currency: currency,
      timestamp: DateTime.now(),
      data: {
        'merchant_reference': merchantReference,
        'payment_method': paymentMethod,
        'pesapal_status': description,
        'pesapal_status_code': statusCode,
        'confirmation_code': data['confirmation_code']?.toString(),
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
      throw PaymentException.validation(
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
      final response = await HttpClientFactory.send(
        _httpClient,
        method: 'POST',
        uri: _config.pesaPalRegisterIpnUri,
        timeout: _config.timeout,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        jsonBody: {'url': ipnUrl, 'ipn_notification_type': ipnNotificationType},
      );
      final responseBody = response.body;

      if (response.statusCode != 200) {
        throw PaymentException.api(
          'Failed to register IPN: ${response.statusCode} - '
          '${Encryption.sanitizeForLogging(responseBody)}',
        );
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;
      final ipnId = data['ipn_id'] as String?;
      if (ipnId == null || ipnId.trim().isEmpty) {
        throw PaymentException.api(
          'IPN registration succeeded but ipn_id was missing. Response: $data',
        );
      }

      return ipnId;
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException.api(
        'Failed to register IPN: ${Encryption.sanitizeForLogging(e.toString())}',
        originalException: e is Exception ? e : null,
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
