import 'payment_status.dart';

/// Represents a response from a payment operation.
class PaymentResponse {
  /// The unique transaction ID.
  final String transactionId;

  /// The status of the payment.
  final PaymentStatus status;

  /// A message describing the result.
  final String message;

  /// The amount that was processed.
  final double? amount;

  /// The currency used.
  final String? currency;

  /// Additional response data.
  final Map<String, dynamic>? data;

  /// Timestamp when the response was created.
  final DateTime timestamp;

  /// Creates a new PaymentResponse.
  const PaymentResponse({
    required this.transactionId,
    required this.status,
    required this.message,
    this.amount,
    this.currency,
    this.data,
    required this.timestamp,
  });

  /// Creates a PaymentResponse from a JSON map.
  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      transactionId: json['transactionId'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.failed,
      ),
      message: json['message'] ?? '',
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Converts the PaymentResponse to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status.toString().split('.').last,
      'message': message,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (data != null) 'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns true if the payment was successful.
  bool get isSuccessful => status == PaymentStatus.successful;

  /// Returns true if the payment is pending.
  bool get isPending => status == PaymentStatus.pending;

  /// Returns true if the payment failed.
  bool get isFailed => status == PaymentStatus.failed;

  @override
  String toString() {
    return 'PaymentResponse(transactionId: $transactionId, status: $status, message: $message)';
  }
}
