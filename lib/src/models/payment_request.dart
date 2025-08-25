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

  /// The merchant reference ID.
  final String? merchantReference;

  /// Creates a new PaymentRequest.
  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.phoneNumber,
    this.email,
    this.description,
    this.metadata,
    this.merchantReference,
  });

  /// Creates a PaymentRequest from a JSON map.
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      description: json['description'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      merchantReference: json['merchantReference'],
    );
  }

  /// Converts the PaymentRequest to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (merchantReference != null) 'merchantReference': merchantReference,
    };
  }

  @override
  String toString() {
    return 'PaymentRequest(amount: $amount, currency: $currency, paymentMethod: $paymentMethod)';
  }
}
