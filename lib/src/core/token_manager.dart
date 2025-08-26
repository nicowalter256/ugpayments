import 'dart:convert';
import 'dart:io';
import 'payment_config.dart';
import 'payment_exception.dart';

/// Manages authentication tokens for PesaPal API.
class TokenManager {
  final PaymentConfig _config;
  final HttpClient _httpClient;

  String? _cachedToken;
  DateTime? _tokenExpiry;

  /// Creates a new TokenManager.
  TokenManager(this._config) : _httpClient = HttpClient();

  /// Gets a valid authentication token, fetching a new one if necessary.
  Future<String> getToken() async {
    // Check if we have a valid cached token
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken!;
    }

    // Fetch a new token
    return await _fetchNewToken();
  }

  /// Fetches a new authentication token from PesaPal.
  Future<String> _fetchNewToken() async {
    try {
      final url = Uri.parse('${_config.baseUrl}/api/Auth/RequestToken');

      final requestBody = {
        'consumer_key': _config.consumerKey,
        'consumer_secret': _config.consumerSecret,
      };

      final httpRequest = await _httpClient.postUrl(url);
      httpRequest.headers.set('Content-Type', 'application/json');
      httpRequest.write(json.encode(requestBody));

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody) as Map<String, dynamic>;

        final token = data['token'] as String?;
        final expiryDate = data['expiryDate'] as String?;
        final error = data['error'];
        final status = data['status'] as String?;

        if (error != null) {
          throw PaymentException('Token request failed: $error');
        }

        if (status != '200') {
          throw PaymentException('Token request returned status: $status');
        }

        if (token == null) {
          throw PaymentException('No token received from PesaPal');
        }

        // Cache the token and set expiry
        _cachedToken = token;
        if (expiryDate != null) {
          _tokenExpiry = DateTime.parse(expiryDate);
        } else {
          // If no expiry date provided, assume 30 minutes
          _tokenExpiry = DateTime.now().add(const Duration(minutes: 30));
        }

        if (_config.enableDebugLogging) {
          print('PesaPal: Successfully fetched new authentication token');
        }

        return token;
      } else {
        throw PaymentException(
          'Failed to fetch token: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      throw PaymentException('Failed to fetch authentication token: $e');
    }
  }

  /// Clears the cached token, forcing a new token to be fetched on next request.
  void clearToken() {
    _cachedToken = null;
    _tokenExpiry = null;
  }

  /// Disposes the HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
