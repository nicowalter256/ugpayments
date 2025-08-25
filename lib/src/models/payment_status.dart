/// Represents the status of a payment transaction.
enum PaymentStatus {
  /// Payment is pending processing.
  pending,

  /// Payment was successful.
  successful,

  /// Payment failed.
  failed,

  /// Payment was cancelled.
  cancelled,

  /// Payment is being processed.
  processing,

  /// Payment was refunded.
  refunded,

  /// Payment expired.
  expired,
}
