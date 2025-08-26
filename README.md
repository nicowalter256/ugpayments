# ugpayments

A comprehensive Flutter package for processing payments in Uganda, supporting multiple payment methods including PesaPal integration, mobile money, bank transfers, and card payments.

## Features

- **PesaPal Integration**: Full integration with PesaPal payment gateway
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

### Basic Setup with PesaPal

```dart
import 'package:ugpayments/ugpayments.dart';

// Create a PesaPal payment configuration
final config = PaymentConfig.pesaPalSandbox(
  consumerKey: 'your_pesapal_consumer_key',
  consumerSecret: 'your_consumer_secret',
  callbackUrl: 'https://your-app.com/payment-callback',
  notificationId: 'your_notification_id',
);

// Create a payment client
final client = PaymentClient(config);
```

### PesaPal Payment Processing

```dart
// Create a payment request
final request = PaymentRequest(
  amount: 1000.0,
  currency: 'UGX',
  paymentMethod: 'PESAPAL',
  phoneNumber: '+256701234567',
  email: 'customer@example.com',
  description: 'Payment for services',
  merchantReference: 'ORDER-123',
  metadata: {
    'first_name': 'John',
    'last_name': 'Doe',
    'city': 'Kampala',
    'state': 'Central',
  },
);

// Process the payment
try {
  final response = await client.processPayment(request);

  if (response.isSuccessful) {
    print('Payment successful: ${response.transactionId}');
  } else if (response.isPending) {
    print('Payment pending. Redirect to: ${response.data?['redirect_url']}');
    // Open the redirect URL in a WebView or browser
  } else {
    print('Payment failed: ${response.message}');
  }
} catch (e) {
  print('Payment error: $e');
}
```

### Using PesaPal Provider Directly

```dart
// Create PesaPal provider
final pesapalProvider = PesaPalProvider(config);

// Submit order
final response = await pesapalProvider.submitOrder(request);

// Check transaction status
final statusResponse = await pesapalProvider.getTransactionStatus(
  response.transactionId,
);
```

### Mobile Money Payment (Legacy)

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

### PesaPal Integration

- Complete PesaPal API integration
- Order submission and status tracking
- Redirect URL handling
- Callback notifications

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

## PesaPal Integration Details

### Simplified Authentication

The package now uses automatic token authentication. You only need to provide your `consumer_key` and `consumer_secret` - the package will automatically:

1. Fetch authentication tokens from PesaPal's `/api/Auth/RequestToken` endpoint
2. Cache tokens and reuse them until they expire
3. Automatically refresh tokens when needed
4. Handle all authentication headers for API requests

This eliminates the need for you to manually manage bearer tokens.

### Configuration

```dart
// Sandbox environment
final config = PaymentConfig.pesaPalSandbox(
  consumerKey: 'your_consumer_key',
  consumerSecret: 'your_consumer_secret',
  callbackUrl: 'https://your-app.com/callback',
  notificationId: 'your_notification_id',
);

// Production environment
final config = PaymentConfig.pesaPalProduction(
  consumerKey: 'your_production_consumer_key',
  consumerSecret: 'your_production_consumer_secret',
  callbackUrl: 'https://your-app.com/callback',
  notificationId: 'your_notification_id',
);
```

### API Endpoints

The package integrates with the following PesaPal API endpoints:

**Sandbox Environment:**

- Base URL: `https://cybqa.pesapal.com/pesapalv3`
- `POST /api/Auth/RequestToken` - Get authentication token
- `POST /api/Transactions/SubmitOrderRequest` - Submit payment order
- `GET /api/Transactions/GetTransactionStatus` - Get transaction status

**Production Environment:**

- Base URL: `https://pay.pesapal.com/v3`
- `POST /api/Auth/RequestToken` - Get authentication token
- `POST /api/Transactions/SubmitOrderRequest` - Submit payment order
- `GET /api/Transactions/GetTransactionStatus` - Get transaction status

### Response Handling

```dart
final response = await client.processPayment(request);

// Check if payment is pending (requires redirect)
if (response.isPending) {
  final redirectUrl = response.data?['redirect_url'];
  // Open redirectUrl in WebView or browser
}

// Check transaction status later
final statusResponse = await client.getTransaction(response.transactionId);
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
- Handle PesaPal redirect URLs properly in your UI

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This package is licensed under the MIT License. See the LICENSE file for details.
