import 'dart:core';

/// Strongly-typed card details for secure handling.
///
/// Security properties:
/// - CVV is intentionally not stored in this model.
/// - `toJson()` and `toString()` do not include the full card number.
/// - Only non-sensitive fields (e.g., `last4`) are kept.
class CardDetails {
  /// Detected card network (e.g., VISA, MASTERCARD, AMEX).
  final String cardType;

  /// Last 4 digits of the card number.
  final String last4;

  /// Expiry month as a 2-digit string (MM).
  final String expiryMonth;

  /// Expiry year as a 4-digit string (YYYY).
  final String expiryYear;

  const CardDetails({
    required this.cardType,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
  });

  /// Creates [CardDetails] from raw inputs without persisting CVV.
  ///
  /// Notes:
  /// - Pass CVV only if the calling integration validates it.
  /// - This model will NOT store CVV and will NOT serialize it.
  factory CardDetails.fromRaw({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    // CVV is accepted for compatibility but intentionally discarded.
    // ignore: unused_element
    String? cvv,
  }) {
    final digits = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    final cardType = _detectCardType(digits);

    return CardDetails(
      cardType: cardType,
      last4: last4,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
    );
  }

  factory CardDetails.fromJson(Map<String, dynamic> json) {
    return CardDetails(
      cardType: (json['cardType'] ?? 'UNKNOWN').toString(),
      last4: (json['last4'] ?? '').toString(),
      expiryMonth: (json['expiryMonth'] ?? '').toString(),
      expiryYear: (json['expiryYear'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardType': cardType,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
    };
  }

  @override
  String toString() {
    return 'CardDetails(cardType: $cardType, last4: $last4, expiry: $expiryMonth/$expiryYear)';
  }

  static String _detectCardType(String digitsOnly) {
    if (digitsOnly.startsWith('4')) return 'VISA';
    if (digitsOnly.startsWith('5')) return 'MASTERCARD';
    if (digitsOnly.startsWith('34') || digitsOnly.startsWith('37')) return 'AMEX';
    return 'UNKNOWN';
  }
}

