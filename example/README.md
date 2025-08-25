# UgPayments Example App

This is a complete Flutter example application demonstrating how to use the ugpayments package with PesaPal integration.

## Features

- ✅ Complete payment flow with PesaPal
- ✅ Form validation and error handling
- ✅ Payment status tracking
- ✅ WebView integration for payment completion
- ✅ Browser integration for payment URLs
- ✅ Local storage for payment history
- ✅ Modern Material 3 UI design

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK
- PesaPal account with API credentials

### Installation

1. **Navigate to the example directory:**

   ```bash
   cd example
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure PesaPal credentials:**

   Open `lib/main.dart` and replace the placeholder credentials:

   ```dart
   final config = PaymentConfig.pesaPalSandbox(
     apiKey: 'your_actual_pesapal_bearer_token', // Replace this
     apiSecret: 'your_actual_api_secret', // Replace this
     callbackUrl: 'https://your-app.com/payment-callback',
     notificationId: 'your_actual_notification_id',
     enableDebugLogging: true,
   );
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## How to Use

### 1. Enter Payment Details

- **Amount**: Enter the payment amount in UGX
- **Phone Number**: Customer's phone number (Ugandan format)
- **Email**: Customer's email address
- **Description**: Payment description

### 2. Process Payment

1. Click "Process Payment" button
2. The app will submit the payment to PesaPal
3. If successful, you'll get a transaction ID and redirect URL

### 3. Complete Payment

When a payment is pending, you have two options:

#### Option A: Open in Browser

- Click "Open Payment in Browser"
- This opens the PesaPal payment page in your device's default browser

#### Option B: Open in WebView

- Click "Open Payment in WebView"
- This opens the payment page within the app using a WebView

### 4. Check Payment Status

- Click "Check Status" to verify the current status of your transaction
- View transaction details including amount, status, and timestamps

## Configuration

### Sandbox vs Production

**For Testing (Sandbox):**

```dart
final config = PaymentConfig.pesaPalSandbox(
  apiKey: 'your_sandbox_token',
  apiSecret: 'your_sandbox_secret',
  // Uses: https://cybqa.pesapal.com/pesapalv3
);
```

**For Production:**

```dart
final config = PaymentConfig.pesaPalProduction(
  apiKey: 'your_production_token',
  apiSecret: 'your_production_secret',
  // Uses: https://pay.pesapal.com/v3
);
```

### Environment Variables

For better security, consider using environment variables:

```dart
final config = PaymentConfig.pesaPalSandbox(
  apiKey: const String.fromEnvironment('PESAPAL_API_KEY'),
  apiSecret: const String.fromEnvironment('PESAPAL_API_SECRET'),
  callbackUrl: const String.fromEnvironment('PESAPAL_CALLBACK_URL'),
  notificationId: const String.fromEnvironment('PESAPAL_NOTIFICATION_ID'),
);
```

Then run with:

```bash
flutter run --dart-define=PESAPAL_API_KEY=your_key --dart-define=PESAPAL_API_SECRET=your_secret
```

## API Endpoints

The app integrates with these PesaPal API endpoints:

**Sandbox:**

- Base URL: `https://cybqa.pesapal.com/pesapalv3`
- Submit Order: `POST /v3/api/Transactions/SubmitOrderRequest`
- Check Status: `GET /v3/api/Transactions/GetTransactionStatus`

**Production:**

- Base URL: `https://pay.pesapal.com/v3`
- Submit Order: `POST /v3/api/Transactions/SubmitOrderRequest`
- Check Status: `GET /v3/api/Transactions/GetTransactionStatus`

## Error Handling

The app includes comprehensive error handling:

- **Validation Errors**: Invalid amounts, phone numbers, etc.
- **Network Errors**: Connection issues
- **Authentication Errors**: Invalid API credentials
- **Payment Errors**: Failed transactions

## Dependencies

- `ugpayments`: The main payment package
- `url_launcher`: For opening payment URLs in browser
- `webview_flutter`: For in-app payment completion
- `shared_preferences`: For local storage of payment history

## Troubleshooting

### Common Issues

1. **"Invalid Access Token" Error**

   - Check your PesaPal API credentials
   - Ensure you're using the correct environment (sandbox vs production)

2. **"Network Error"**

   - Check your internet connection
   - Verify the PesaPal API endpoints are accessible

3. **"Invalid Data" Error**
   - Ensure all required fields are filled
   - Check phone number format (+256XXXXXXXXX)
   - Verify amount is greater than 0

### Debug Mode

Enable debug logging by setting:

```dart
enableDebugLogging: true,
```

This will show detailed API requests and responses in the console.

## Next Steps

1. **Get PesaPal Credentials**: Sign up at [PesaPal](https://www.pesapal.com) and get your API credentials
2. **Test in Sandbox**: Use sandbox environment for testing
3. **Go Live**: Switch to production when ready
4. **Customize UI**: Modify the UI to match your app's design
5. **Add More Features**: Implement webhooks, notifications, etc.

## Support

For issues with the ugpayments package, check the main package documentation or create an issue in the repository.

For PesaPal-specific issues, contact PesaPal support.
