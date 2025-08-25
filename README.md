# ugpayments

A comprehensive Flutter package for processing payments in Uganda, supporting multiple payment methods including mobile money, bank transfers, and card payments.

## Features

- **Multiple Payment Methods**: Support for mobile money (MTN, Airtel, M-Pesa), bank transfers, and card payments
- **Comprehensive Validation**: Built-in validation for payment data, phone numbers, card numbers, and more
- **Security**: Encryption utilities for sensitive payment data
- **Error Handling**: Robust exception handling with detailed error messages
- **JSON Serialization**: Full support for JSON serialization/deserialization
- **Type Safety**: Strongly typed models and responses
- **Testing**: Comprehensive test coverage

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  ugpayments: ^0.0.1
```

## Usage

### Basic Setup

```dart
import 'package:ugpayments/ugpayments.dart';

// Create a payment configuration
final config = PaymentConfig.sandbox(
  apiKey: 'your_api_key',
  apiSecret: 'your_api_secret',
);

// Create a payment client
final client = PaymentClient(config);
```

### Mobile Money Payment

```dart
// Create a payment request
final request = PaymentRequest(
  amount: 1000.0,
  currency: 'UGX',
  paymentMethod: 'MOBILE_MONEY',
  phoneNumber: '+256701234567',
  description: 'Payment for services',
);

// Process the payment
try {
  final response = await client.processPayment(request);

  if (response.isSuccessful) {
    print('Payment successful: ${response.transactionId}');
  } else {
    print('Payment failed: ${response.message}');
  }
} catch (e) {
  print('Payment error: $e');
}
```

### Card Payment

```dart
final request = PaymentRequest(
  amount: 5000.0,
  currency: 'UGX',
  paymentMethod: 'CARD_PAYMENT',
  metadata: {
    'cardNumber': '4111111111111111',
    'expiryMonth': '12',
    'expiryYear': '2025',
    'cvv': '123',
  },
);

final response = await client.processPayment(request);
```

### Bank Transfer

```dart
final request = PaymentRequest(
  amount: 10000.0,
  currency: 'UGX',
  paymentMethod: 'BANK_TRANSFER',
  metadata: {
    'bankName': 'STANBIC_BANK',
    'accountNumber': '1234567890',
  },
);

final response = await client.processPayment(request);
```

### Validation

```dart
// Validate phone numbers
if (PaymentValidator.isValidUgandanPhoneNumber('+256701234567')) {
  print('Valid phone number');
}

// Validate card numbers
if (PaymentValidator.isValidCardNumber('4111111111111111')) {
  print('Valid card number');
}

// Validate email addresses
if (PaymentValidator.isValidEmail('user@example.com')) {
  print('Valid email');
}
```

### Encryption

```dart
// Encrypt sensitive data
final encrypted = Encryption.encrypt('sensitive_data');
final decrypted = Encryption.decrypt(encrypted);

// Mask sensitive data for display
final maskedCard = Encryption.maskCardNumber('4111111111111111');
final maskedPhone = Encryption.maskPhoneNumber('+256701234567');
```

## Supported Payment Methods

### Mobile Money

- MTN Mobile Money
- Airtel Money
- M-Pesa

### Bank Transfers

- Stanbic Bank
- Centenary Bank
- DFCU Bank
- Barclays Bank
- Standard Chartered
- Bank of Africa

### Card Payments

- Visa
- Mastercard
- American Express

## Supported Currencies

- UGX (Ugandan Shilling)
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- KES (Kenyan Shilling)

## Error Handling

The package provides comprehensive error handling with specific exception types:

```dart
try {
  final response = await client.processPayment(request);
} on PaymentException catch (e) {
  switch (e.code) {
    case 'INVALID_DATA':
      print('Invalid payment data: ${e.message}');
      break;
    case 'AUTH_FAILED':
      print('Authentication failed');
      break;
    case 'INSUFFICIENT_FUNDS':
      print('Insufficient funds');
      break;
    default:
      print('Payment error: ${e.message}');
  }
}
```

## Testing

Run the tests to ensure everything works correctly:

```bash
flutter test
```

## Additional information

### Security Considerations

- Always use HTTPS in production
- Store API keys securely
- Never log sensitive payment data
- Use the provided encryption utilities for sensitive data
- Validate all input data before processing

### Best Practices

- Always handle exceptions when processing payments
- Validate payment data before sending to the API
- Use appropriate payment methods for your use case
- Implement proper error handling and user feedback
- Test thoroughly in sandbox environment before going live

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This package is licensed under the MIT License. See the LICENSE file for details.
