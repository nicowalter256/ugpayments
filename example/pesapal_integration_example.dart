import 'package:ugpayments/ugpayments.dart';

/// Simple example demonstrating PesaPal integration with automatic token authentication
void main() async {
  // Configure PesaPal with your consumer credentials
  final config = PaymentConfig.pesaPalSandbox(
    consumerKey: 'your_consumer_key_here',
    consumerSecret: 'your_consumer_secret_here',
    callbackUrl: 'https://your-app.com/payment-callback',
    notificationId: 'your_notification_id',
    enableDebugLogging: true,
  );

  // Create payment client
  final client = PaymentClient(config);

  try {
    // Create a payment request
    final request = PaymentRequest(
      amount: 1000.0,
      currency: 'UGX',
      paymentMethod: 'PESAPAL',
      phoneNumber: '+256701234567',
      email: 'customer@example.com',
      description: 'Payment for services',
      merchantReference: 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
      metadata: {
        'first_name': 'John',
        'last_name': 'Doe',
        'city': 'Kampala',
        'state': 'Central',
      },
    );

    print('Processing payment...');

    // Process the payment (token authentication happens automatically)
    final response = await client.processPayment(request);

    print('Payment processed successfully!');
    print('Transaction ID: ${response.transactionId}');
    print('Status: ${response.status}');
    print('Message: ${response.message}');

    if (response.isPending) {
      final redirectUrl = response.data?['redirect_url'];
      print('Payment is pending. Redirect to: $redirectUrl');
      // Open redirectUrl in WebView or browser to complete payment
    } else if (response.isSuccessful) {
      print('Payment completed successfully!');
    } else {
      print('Payment failed: ${response.message}');
    }

    // Check transaction status later
    print('\nChecking transaction status...');
    final transaction = await client.getTransaction(response.transactionId);
    if (transaction != null) {
      print('Transaction status: ${transaction.status}');
    }
  } catch (e) {
    print('Error processing payment: $e');
  } finally {
    // Always dispose the client
    client.dispose();
  }
}

/// Example using PesaPal provider directly
void pesapalProviderExample() async {
  final config = PaymentConfig.pesaPalProduction(
    consumerKey: 'your_production_consumer_key',
    consumerSecret: 'your_production_consumer_secret',
    callbackUrl: 'https://your-app.com/callback',
    notificationId: 'your_notification_id',
  );

  final pesapalProvider = PesaPalProvider(config);

  try {
    final request = PaymentRequest(
      amount: 5000.0,
      currency: 'UGX',
      paymentMethod: 'PESAPAL',
      phoneNumber: '+256701234567',
      email: 'customer@example.com',
      description: 'Large payment for services',
    );

    // Submit order (token authentication happens automatically)
    final response = await pesapalProvider.submitOrder(request);
    print('Order submitted: ${response.transactionId}');

    // Check status
    final statusResponse = await pesapalProvider.getTransactionStatus(
      response.transactionId,
    );
    print('Status: ${statusResponse.status}');
  } catch (e) {
    print('Error: $e');
  } finally {
    pesapalProvider.dispose();
  }
}
