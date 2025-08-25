import 'package:ugpayments/ugpayments.dart';

/// Example demonstrating PesaPal integration with ugpayments package.
void main() async {
  // Example 1: Basic PesaPal Setup
  await basicPesaPalSetup();

  // Example 2: Complete Payment Flow
  await completePaymentFlow();

  // Example 3: Transaction Status Checking
  await transactionStatusChecking();
}

/// Example 1: Basic PesaPal Setup
Future<void> basicPesaPalSetup() async {
  print('=== Example 1: Basic PesaPal Setup ===');

  // Create PesaPal configuration for sandbox environment
  final config = PaymentConfig.pesaPalSandbox(
    apiKey: 'your_pesapal_bearer_token_here',
    apiSecret: 'your_api_secret_here',
    callbackUrl: 'https://your-app.com/payment-callback',
    notificationId: 'your_notification_id_here',
  );

  // Create payment client
  final client = PaymentClient(config);

  print('✅ PesaPal client configured successfully');
  // Note: client is created but not used in this example
  // In a real app, you would use it to process payments
  print('Environment: ${config.environment}');
  print('Base URL: ${config.baseUrl}');
  print('Is PesaPal: ${config.isPesaPal}');
  print('Note: Sandbox URL: https://cybqa.pesapal.com/pesapalv3');
  print('Note: Production URL: https://pay.pesapal.com/v3');
}

/// Example 2: Complete Payment Flow
Future<void> completePaymentFlow() async {
  print('\n=== Example 2: Complete Payment Flow ===');

  // Create PesaPal configuration
  final config = PaymentConfig.pesaPalSandbox(
    apiKey: 'your_pesapal_bearer_token_here',
    apiSecret: 'your_api_secret_here',
    callbackUrl: 'https://your-app.com/payment-callback',
    notificationId: 'your_notification_id_here',
  );

  final client = PaymentClient(config);

  // Create a payment request
  final request = PaymentRequest(
    amount: 500.0,
    currency: 'UGX',
    paymentMethod: 'PESAPAL',
    phoneNumber: '+256701234567',
    email: 'customer@example.com',
    description: 'Payment for online services',
    merchantReference: 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
    metadata: {
      'first_name': 'John',
      'last_name': 'Doe',
      'city': 'Kampala',
      'state': 'Central',
    },
  );

  print('📝 Payment Request Created:');
  print('  Amount: ${request.amount} ${request.currency}');
  print('  Description: ${request.description}');
  print('  Merchant Reference: ${request.merchantReference}');
  print('  Customer Email: ${request.email}');
  print('  Customer Phone: ${request.phoneNumber}');

  try {
    // Process the payment
    print('\n🔄 Processing payment...');
    final response = await client.processPayment(request);

    print('✅ Payment Response Received:');
    print('  Transaction ID: ${response.transactionId}');
    print('  Status: ${response.status}');
    print('  Message: ${response.message}');

    if (response.isPending) {
      print('⏳ Payment is pending. Customer needs to complete payment.');
      final redirectUrl = response.data?['redirect_url'];
      if (redirectUrl != null) {
        print('🔗 Redirect URL: $redirectUrl');
        print('💡 Open this URL in a WebView or browser to complete payment');
      }
    } else if (response.isSuccessful) {
      print('🎉 Payment completed successfully!');
    } else {
      print('❌ Payment failed: ${response.message}');
    }
  } catch (e) {
    print('❌ Payment Error: $e');
  }
}

/// Example 3: Transaction Status Checking
Future<void> transactionStatusChecking() async {
  print('\n=== Example 3: Transaction Status Checking ===');

  // Create PesaPal configuration
  final config = PaymentConfig.pesaPalSandbox(
    apiKey: 'your_pesapal_bearer_token_here',
    apiSecret: 'your_api_secret_here',
    callbackUrl: 'https://your-app.com/payment-callback',
    notificationId: 'your_notification_id_here',
  );

  final client = PaymentClient(config);

  // Example transaction ID (in real app, this would come from a previous payment)
  const transactionId = 'your_transaction_id_here';

  try {
    print('🔍 Checking transaction status for: $transactionId');

    final transaction = await client.getTransaction(transactionId);

    if (transaction != null) {
      print('✅ Transaction Found:');
      print('  ID: ${transaction.id}');
      print('  Amount: ${transaction.amount} ${transaction.currency}');
      print('  Status: ${transaction.status}');
      print('  Payment Method: ${transaction.paymentMethod}');
      print('  Created: ${transaction.createdAt}');
      print('  Updated: ${transaction.updatedAt}');
    } else {
      print('❌ Transaction not found');
    }
  } catch (e) {
    print('❌ Error checking transaction: $e');
  }
}

/// Example 4: Using PesaPal Provider Directly
Future<void> pesapalProviderExample() async {
  print('\n=== Example 4: Using PesaPal Provider Directly ===');

  // Create PesaPal configuration
  final config = PaymentConfig.pesaPalSandbox(
    apiKey: 'your_pesapal_bearer_token_here',
    apiSecret: 'your_api_secret_here',
    callbackUrl: 'https://your-app.com/payment-callback',
    notificationId: 'your_notification_id_here',
  );

  // Create PesaPal provider directly
  final pesapalProvider = PesaPalProvider(config);

  // Create payment request
  final request = PaymentRequest(
    amount: 1000.0,
    currency: 'UGX',
    paymentMethod: 'PESAPAL',
    phoneNumber: '+256701234567',
    email: 'customer@example.com',
    description: 'Direct provider payment',
    merchantReference: 'DIRECT-${DateTime.now().millisecondsSinceEpoch}',
  );

  try {
    // Submit order directly to PesaPal
    print('📤 Submitting order to PesaPal...');
    final response = await pesapalProvider.submitOrder(request);

    print('✅ Order submitted successfully:');
    print('  Transaction ID: ${response.transactionId}');
    print('  Status: ${response.status}');
    print('  Redirect URL: ${response.data?['redirect_url']}');

    // Check transaction status
    print('\n🔍 Checking transaction status...');
    final statusResponse = await pesapalProvider.getTransactionStatus(
      response.transactionId,
    );

    print('📊 Status Response:');
    print('  Status: ${statusResponse.status}');
    print('  Message: ${statusResponse.message}');
    print('  Payment Method: ${statusResponse.data?['payment_method']}');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Clean up
    pesapalProvider.dispose();
  }
}

/// Example 5: Error Handling
Future<void> errorHandlingExample() async {
  print('\n=== Example 5: Error Handling ===');

  final config = PaymentConfig.pesaPalSandbox(
    apiKey: 'invalid_token',
    apiSecret: 'invalid_secret',
  );

  final client = PaymentClient(config);

  final request = PaymentRequest(
    amount: 100.0,
    currency: 'UGX',
    paymentMethod: 'PESAPAL',
    phoneNumber: '+256701234567',
  );

  try {
    await client.processPayment(request);
  } on PaymentException catch (e) {
    print('❌ Payment Exception: ${e.message}');
    print('  Code: ${e.code}');
    print('  Details: ${e.details}');

    // Handle specific error types
    switch (e.code) {
      case 'AUTH_FAILED':
        print('🔐 Authentication failed. Check your API credentials.');
        break;
      case 'INVALID_DATA':
        print('📝 Invalid payment data. Check your request parameters.');
        break;
      case 'NETWORK_ERROR':
        print('🌐 Network error. Check your internet connection.');
        break;
      default:
        print('⚠️ Unknown error occurred.');
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
  }
}
