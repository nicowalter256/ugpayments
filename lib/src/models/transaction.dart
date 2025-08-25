import 'payment_status.dart';

/// Represents a payment transaction with full details.
class Transaction {
  /// The unique transaction ID.
  final String id;

  /// The amount of the transaction.
  final double amount;

  /// The currency used.
  final String currency;

  /// The payment method used.
  final String paymentMethod;

  /// The status of the transaction.
  final PaymentStatus status;

  /// The customer's phone number (if applicable).
  final String? phoneNumber;

  /// The customer's email address.
  final String? email;

  /// A description of the transaction.
  final String? description;

  /// The merchant reference ID.
  final String? merchantReference;

  /// When the transaction was created.
  final DateTime createdAt;

  /// When the transaction was last updated.
  final DateTime updatedAt;

  /// Additional transaction data.
  final Map<String, dynamic>? metadata;

  /// Creates a new Transaction.
  const Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.phoneNumber,
    this.email,
    this.description,
    this.merchantReference,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// Creates a Transaction from a JSON map.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      currency: json['currency'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.failed,
      ),
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      description: json['description'],
      merchantReference: json['merchantReference'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Converts the Transaction to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status.toString().split('.').last,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (merchantReference != null) 'merchantReference': merchantReference,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates a copy of this Transaction with updated fields.
  Transaction copyWith({
    String? id,
    double? amount,
    String? currency,
    String? paymentMethod,
    PaymentStatus? status,
    String? phoneNumber,
    String? email,
    String? description,
    String? merchantReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      description: description ?? this.description,
      merchantReference: merchantReference ?? this.merchantReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, currency: $currency, status: $status)';
  }
}
