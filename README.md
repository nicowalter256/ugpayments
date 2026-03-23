# ugpayments

A comprehensive Flutter package for processing payments in Uganda, supporting PesaPal integration (including card options via redirect flow) and mobile money.

## Features

- **PesaPal Integration**: Full integration with PesaPal payment gateway
- **Multiple Payment Methods**: Support for mobile money (MTN, Airtel, M-Pesa) and PesaPal (including card options via redirect flow)
- **Comprehensive Validation**: Built-in validation for payment data, phone numbers, and more
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

## Before you start (PesaPal keys)
Before using the PesaPal parts of this package, you need your Pesapal credentials from your Pesapal account:

1. Go to the [Pesapal website](https://www.pesapal.com/) and create/register your merchant account.
2. In your Pesapal dashboard/developer settings, obtain your API credentials:
   - `consumer_key` (your "Consumer Key")
   - `consumer_secret` (your "Consumer Secret")
3. Make sure you use the correct credentials for the environment:
   - `PaymentConfig.pesaPalSandbox` -> your *sandbox* `consumer_key`/`consumer_secret`
   - `PaymentConfig.pesaPalProduction` -> your *production* `consumer_key`/`consumer_secret`
4. Set `callbackUrl` to the URL that Pesapal will call after payment. This endpoint should be publicly reachable.

Notes:
- Keep `consumer_key` and `consumer_secret` out of source control (use environment variables or your application's secrets management in real projects).

## Usage

### Basic Setup with PesaPal

```dart
import 'package:ugpayments/ugpayments.dart';

// Create a PesaPal payment configuration
final config = PaymentConfig.pesaPalSandbox(
  // Copy these from your Pesapal dashboard ("Consumer Key" / "Consumer Secret")
  consumerKey: 'your_pesapal_consumer_key',
  consumerSecret: 'your_consumer_secret',
  callbackUrl: 'https://your-app.com/payment-callback',
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
    // Open the Pesapal redirect URL in your WebView.
    // Inside the Pesapal checkout page, the customer can choose a payment method (including cards).
    // You do NOT need to make a separate "card payment" request before showing this page.
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

### Legacy payment methods (disabled)

`CardPayment`, `MobileMoney`, and `BankTransfer` are disabled in this package (they throw at runtime) to avoid unsafe simulated payment processing.

Use the PesaPal flow (`redirect_url` in a WebView) for card and mobile-money options.

### Validation

```dart
// Validate phone numbers
if (PaymentValidator.isValidUgandanPhoneNumber('+256701234567')) {
  print('Valid phone number');
}

// Validate email addresses
if (PaymentValidator.isValidEmail('user@example.com')) {
  print('Valid email');
}
```

### Encryption

```dart
// Encrypt sensitive data (requires an external AES-256 key)
final aesKey = Encryption.generateAes256Key();
final encrypted = Encryption.encrypt('sensitive_data', key: aesKey);
final decrypted = Encryption.decrypt(encrypted, key: aesKey);

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

Note: Card payments are handled inside Pesapal's checkout page that you open using the `redirect_url` in a WebView.
Mobile money options are also selected inside the same Pesapal checkout page.

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
);

// Production environment
final config = PaymentConfig.pesaPalProduction(
  consumerKey: 'your_production_consumer_key',
  consumerSecret: 'your_production_consumer_secret',
  callbackUrl: 'https://your-app.com/callback',
);
```

### Response Handling

```dart
final response = await client.processPayment(request);

// Check if payment is pending (requires redirect)
if (response.isPending) {
  final redirectUrl = response.data?['redirect_url'];
  // Open redirectUrl in your WebView.
  // The Pesapal checkout page will handle the customer flow (including card options),
  // so you do not initiate a separate "card payment" request.
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

If you need help (or you find a bug), please open an issue on GitHub: https://github.com/nicowalter256/ugpayments/issues

### License

This package is licensed under the MIT License. See the LICENSE file for details.
