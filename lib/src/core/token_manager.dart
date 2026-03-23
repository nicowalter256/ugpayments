import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'payment_config.dart';
import 'payment_exception.dart';
import 'http_client_factory.dart';
import '../utils/encryption.dart';

/// Manages authentication tokens for PesaPal API.
class TokenManager {
  final PaymentConfig _config;
  final HttpClient _httpClient;
  final FlutterSecureStorage _secureStorage;

  String? _cachedToken;
  DateTime? _tokenExpiry;

  static const Duration _expiryRefreshBuffer = Duration(seconds: 60);

  String get _tokenStorageKey =>
      'ugpayments.pesapal.token.${_config.environment}';

  String get _tokenExpiryStorageKey =>
      'ugpayments.pesapal.tokenExpiry.${_config.environment}';

  /// Creates a new TokenManager.
  TokenManager(this._config)
      : _httpClient = HttpClientFactory.createForConfig(_config),
        _secureStorage = const FlutterSecureStorage();

  /// Gets a valid authentication token, fetching a new one if necessary.
  Future<String> getToken() async {
    final now = DateTime.now();

    // Check if we have a valid cached token (refresh early).
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!.subtract(_expiryRefreshBuffer))) {
      return _cachedToken!;
    }

    // Try to restore from secure storage.
    final storedToken = await _secureStorage.read(key: _tokenStorageKey);
    final storedExpiry = await _secureStorage.read(
      key: _tokenExpiryStorageKey,
    );

    if (storedToken != null && storedExpiry != null) {
      final expiry = DateTime.tryParse(storedExpiry);
      if (expiry != null &&
          now.isBefore(expiry.subtract(_expiryRefreshBuffer))) {
        _cachedToken = storedToken;
        _tokenExpiry = expiry;
        return storedToken;
      }
    }

    // Fetch a new token
    return await _fetchNewToken();
  }

  /// Fetches a new authentication token from PesaPal.
  Future<String> _fetchNewToken() async {
    try {
      final url = _config.pesaPalAuthRequestTokenUri;

      final consumerKey = await _resolveConsumerKey();
      final consumerSecret = await _resolveConsumerSecret();

      final requestBody = {
        'consumer_key': consumerKey,
        'consumer_secret': consumerSecret,
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
          log('PesaPal: Successfully fetched new authentication token');
        }

        // Persist token for reuse across app restarts.
        await _secureStorage.write(
          key: _tokenStorageKey,
          value: _cachedToken,
        );
        if (_tokenExpiry != null) {
          await _secureStorage.write(
            key: _tokenExpiryStorageKey,
            value: _tokenExpiry!.toIso8601String(),
          );
        }

        return token;
      } else {
        throw PaymentException(
          'Failed to fetch token: ${response.statusCode} - '
          '${Encryption.sanitizeForLogging(responseBody)}',
        );
      }
    } catch (e) {
      throw PaymentException(
        'Failed to fetch authentication token: '
        '${Encryption.sanitizeForLogging(e.toString())}',
      );
    }
  }

  /// Clears the cached token, forcing a new token to be fetched on next request.
  void clearToken() {
    _cachedToken = null;
    _tokenExpiry = null;
    unawaited(_secureStorage.delete(key: _tokenStorageKey));
    unawaited(_secureStorage.delete(key: _tokenExpiryStorageKey));
  }

  Future<String> _resolveConsumerKey() async {
    final storageKey =
        _config.additionalConfig?['pesapal_consumerKey_storageKey']?.toString();

    if (storageKey != null && storageKey.trim().isNotEmpty) {
      final v = await _secureStorage.read(key: storageKey);
      if (v != null && v.trim().isNotEmpty) {
        return v;
      }
    }

    // Backwards compatible fallback.
    return _config.consumerKey;
  }

  Future<String> _resolveConsumerSecret() async {
    final storageKey = _config.additionalConfig?['pesapal_consumerSecret_storageKey']?.toString();

    if (storageKey != null && storageKey.trim().isNotEmpty) {
      final v = await _secureStorage.read(key: storageKey);
      if (v != null && v.trim().isNotEmpty) {
        return v;
      }
    }

    // Backwards compatible fallback.
    return _config.consumerSecret;
  }

  /// Disposes the HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
