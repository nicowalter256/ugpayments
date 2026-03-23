import 'card_details.dart';

/// Represents a payment request with all necessary details.
class PaymentRequest {
  /// The amount to be paid.
  final double amount;

  /// The currency code (e.g., 'UGX', 'USD').
  final String currency;

  /// The payment method to be used.
  final String paymentMethod;

  /// The customer's phone number (for mobile money).
  final String? phoneNumber;

  /// The customer's email address.
  final String? email;

  /// A description of the payment.
  final String? description;

  /// Additional metadata for the payment.
  final Map<String, dynamic>? metadata;

  /// Strongly-typed card details (PCI-aware: no CVV serialization).
  final CardDetails? cardDetails;

  /// The merchant reference ID.
  final String? merchantReference;

  /// Creates a new PaymentRequest.
  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.phoneNumber,
    this.email,
    this.description,
    this.merchantReference,
    this.cardDetails,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata == null
            ? null
            : _sanitizeMetadataForStorage(Map<String, dynamic>.from(metadata));
  

  /// Creates a PaymentRequest from a JSON map.
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      description: json['description'],
      cardDetails: json['cardDetails'] != null
          ? CardDetails.fromJson(Map<String, dynamic>.from(json['cardDetails']))
          : null,
      metadata:
          json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      merchantReference: json['merchantReference'],
    );
  }

  /// Converts the PaymentRequest to a JSON map.
  Map<String, dynamic> toJson() {
    // Metadata has already been sanitized at object creation time.
    final sanitizedMetadata = metadata;

    return {
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (cardDetails != null) 'cardDetails': cardDetails!.toJson(),
      if (sanitizedMetadata != null) 'metadata': sanitizedMetadata,
      if (merchantReference != null) 'merchantReference': merchantReference,
    };
  }

  @override
  String toString() {
    return 'PaymentRequest(amount: $amount, currency: $currency, paymentMethod: $paymentMethod)';
  }

  static Map<String, dynamic> _sanitizeMetadataForSerialization(
    Map<String, dynamic> input,
  ) {
    // Remove common sensitive card fields if they were provided through the legacy metadata map.
    // This is a best-effort defense; callers should use the strongly-typed `cardDetails` field instead.
    const sensitiveKeys = {
      'cardNumber',
      'cvv',
      'expiryMonth',
      'expiryYear',
    };

    input.removeWhere((key, _) => sensitiveKeys.contains(key));
    return input;
  }

  static Map<String, dynamic> _sanitizeMetadataForStorage(
    Map<String, dynamic> input,
  ) {
    // Remove sensitive card fields early so they are never stored in this object.
    return _sanitizeMetadataForSerialization(input);
  }
}
