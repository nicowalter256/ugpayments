import 'dart:convert';
import 'dart:math';

/// Utility class for handling payment data encryption and security.
class Encryption {
  /// Simple encryption key (in production, use proper key management).
  static const String _defaultKey = 'ugpayments_secure_key_2024';

  /// Encrypts sensitive payment data.
  ///
  /// Note: This is a basic implementation. In production, use proper encryption libraries.
  static String encrypt(String data) {
    try {
      // Convert to base64 for basic obfuscation
      final bytes = utf8.encode(data);
      final base64Data = base64.encode(bytes);

      // Simple XOR encryption with the key
      final keyBytes = utf8.encode(_defaultKey);
      final encryptedBytes = <int>[];

      for (int i = 0; i < base64Data.length; i++) {
        final dataByte = base64Data.codeUnitAt(i);
        final keyByte = keyBytes[i % keyBytes.length];
        encryptedBytes.add(dataByte ^ keyByte);
      }

      return base64.encode(encryptedBytes);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts encrypted payment data.
  static String decrypt(String encryptedData) {
    try {
      // Decode from base64
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(_defaultKey);

      // Reverse XOR encryption
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        final encryptedByte = encryptedBytes[i];
        final keyByte = keyBytes[i % keyBytes.length];
        decryptedBytes.add(encryptedByte ^ keyByte);
      }

      final decryptedBase64 = String.fromCharCodes(decryptedBytes);
      final originalBytes = base64.decode(decryptedBase64);

      return utf8.decode(originalBytes);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
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

  /// Generates a secure random number.
  static int generateSecureNumber(int min, int max) {
    final random = Random.secure();
    return min + random.nextInt(max - min + 1);
  }

  /// Creates a hash of sensitive data for verification.
  static String createHash(String data) {
    final bytes = utf8.encode(data);
    final base64Data = base64.encode(bytes);

    // Simple hash function (in production, use proper hashing)
    int hash = 0;
    for (int i = 0; i < base64Data.length; i++) {
      hash = ((hash << 5) - hash + base64Data.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16);
  }

  /// Validates if data has been tampered with using a hash.
  static bool validateHash(String data, String expectedHash) {
    final actualHash = createHash(data);
    return actualHash == expectedHash;
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
}
