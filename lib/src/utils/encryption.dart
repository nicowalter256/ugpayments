import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart';

/// Utility class for handling payment data encryption and security.
class Encryption {
  static const int _aes256KeyLengthBytes = 32;
  static const int _gcmNonceLengthBytes = 12; // Recommended for GCM.

  /// Generates a new random AES-256 key (32 bytes).
  ///
  /// Security note: store this key using a secure key management solution.
  static Uint8List generateAes256Key() {
    final key = Uint8List(_aes256KeyLengthBytes);
    final random = Random.secure();
    for (var i = 0; i < key.length; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// Encrypts sensitive payment data using AES-256-GCM.
  ///
  /// - Requires an external AES-256 key (32 bytes).
  /// - Uses a fresh random nonce per encryption.
  /// - Provides authenticated encryption (integrity + confidentiality).
  ///
  /// Output format: `base64(nonce || ciphertextWithTag)`.
  static String encrypt(
    String data, {
    required List<int> key,
  }) {
    final keyBytes = _validateAes256Key(key);
    final nonce = _generateNonce();

    final aes = AES(
      Key(Uint8List.fromList(keyBytes)),
      mode: AESMode.gcm,
    );
    final encrypter = Encrypter(aes);

    final iv = IV(Uint8List.fromList(nonce));
    final encrypted = encrypter.encrypt(data, iv: iv);

    final output = Uint8List.fromList([...nonce, ...encrypted.bytes]);
    return base64.encode(output);
  }

  /// Decrypts data produced by [encrypt] using AES-256-GCM.
  static String decrypt(
    String encryptedData, {
    required List<int> key,
  }) {
    final keyBytes = _validateAes256Key(key);

    final raw = base64.decode(encryptedData);
    if (raw.length < _gcmNonceLengthBytes + 16) {
      // 16 bytes minimum for the GCM tag (implementation dependent but TAG is at least 128-bit).
      throw const FormatException('Invalid encrypted payload.');
    }

    final nonce = raw.sublist(0, _gcmNonceLengthBytes);
    final cipherBytes = raw.sublist(_gcmNonceLengthBytes);

    final aes = AES(
      Key(Uint8List.fromList(keyBytes)),
      mode: AESMode.gcm,
    );
    final encrypter = Encrypter(aes);

    final iv = IV(Uint8List.fromList(nonce));
    final encrypted = Encrypted(cipherBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Masks sensitive data like card numbers.
  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) {
      return cardNumber;
    }

    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final maskedPart = '*' * (cardNumber.length - 4);

    return '$maskedPart$lastFour';
  }

  /// Masks a phone number for display.
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) {
      return phoneNumber;
    }

    final lastFour = phoneNumber.substring(phoneNumber.length - 4);
    final maskedPart = '*' * (phoneNumber.length - 4);

    return '$maskedPart$lastFour';
  }

  /// Generates a secure random string for tokens.
  static String generateSecureToken(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Generates a cryptographically secure UUID v4.
  ///
  /// UUID v4 structure is:
  /// `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` where `y` is one of `8,9,a,b`.
  static String generateUuidV4() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    // Set version (4) and variant (10xx).
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String two(int v) => v.toRadixString(16).padLeft(2, '0');
    return '${two(bytes[0])}${two(bytes[1])}${two(bytes[2])}${two(bytes[3])}-'
        '${two(bytes[4])}${two(bytes[5])}-'
        '${two(bytes[6])}${two(bytes[7])}-'
        '${two(bytes[8])}${two(bytes[9])}-'
        '${two(bytes[10])}${two(bytes[11])}${two(bytes[12])}'
        '${two(bytes[13])}${two(bytes[14])}${two(bytes[15])}';
  }

  /// Generates a secure random number.
  static int generateSecureNumber(int min, int max) {
    final random = Random.secure();
    return min + random.nextInt(max - min + 1);
  }

  /// Creates a SHA-256 hash for verification (hex encoded).
  static String createHash(String data) => sha256Hex(data);

  /// Validates a SHA-256 hash using a constant-time comparison.
  static bool validateHash(String data, String expectedHash) {
    final actualHash = sha256Hex(data);
    return constantTimeEquals(actualHash, expectedHash);
  }

  /// Computes SHA-256 hash (hex encoded).
  static String sha256Hex(String data) {
    final digest = crypto.sha256.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Computes HMAC-SHA256 (hex encoded).
  ///
  /// Use this for integrity/authentication where the verification key must
  /// remain secret.
  static String hmacSha256Hex({
    required List<int> key,
    required String data,
  }) {
    final hmac = crypto.Hmac(crypto.sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  /// Constant-time string equality to reduce timing side-channels.
  static bool constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);

    var diff = aBytes.length ^ bBytes.length;
    final maxLen = aBytes.length > bBytes.length ? aBytes.length : bBytes.length;

    for (var i = 0; i < maxLen; i++) {
      final av = i < aBytes.length ? aBytes[i] : 0;
      final bv = i < bBytes.length ? bBytes[i] : 0;
      diff |= av ^ bv;
    }

    return diff == 0;
  }

  /// Sanitizes sensitive data for logging (removes sensitive information).
  static String sanitizeForLogging(
    String data, {
    List<String> sensitiveFields = const [],
  }) {
    String sanitized = data;

    // Remove common sensitive patterns
    final patterns = [
      RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'), // Card numbers
      RegExp(r'\b\d{3,4}\b'), // CVV
      RegExp(r'\b\d{2}/\d{2}\b'), // Expiry dates
      RegExp(r'\b\+?256\d{9}\b'), // Ugandan phone numbers
      // Credentials/tokens often appear in JSON or as headers.
      RegExp(
        r'"consumer_secret"\s*:\s*"[^"]+"',
        caseSensitive: false,
      ),
      RegExp(
        r'"consumer_key"\s*:\s*"[^"]+"',
        caseSensitive: false,
      ),
      RegExp(
        r'"token"\s*:\s*"[^"]+"',
        caseSensitive: false,
      ),
      RegExp(
        r'Bearer\s+[A-Za-z0-9\-\._~\+\/]+=*',
        caseSensitive: false,
      ),
      RegExp(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      ), // Email addresses
    ];

    for (final pattern in patterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        return '[REDACTED]';
      });
    }

    return sanitized;
  }

  static List<int> _validateAes256Key(List<int> key) {
    if (key.length != _aes256KeyLengthBytes) {
      throw ArgumentError.value(
        key,
        'key',
        'AES-256 key must be exactly $_aes256KeyLengthBytes bytes.',
      );
    }
    return List<int>.from(key);
  }

  static List<int> _generateNonce() {
    final nonce = Uint8List(_gcmNonceLengthBytes);
    final random = Random.secure();
    for (var i = 0; i < nonce.length; i++) {
      nonce[i] = random.nextInt(256);
    }
    return nonce;
  }
}
