import 'package:flutter/material.dart';
import 'package:ugpayments/ugpayments.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      title: 'UgPayments Example',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: PaymentHomeScreen(),
    );
  }
}

class PaymentHomeScreen extends StatefulWidget {
  @override
  _PaymentHomeScreenState createState() => _PaymentHomeScreenState();
}

class _PaymentHomeScreenState extends State<PaymentHomeScreen> {
  late PaymentClient client;
  bool isLoading = false;
  String? transactionId;
  String? redirectUrl;
  String? lastPaymentStatus;

  // Form controllers
  final TextEditingController amountController = TextEditingController(
    text: '1000',
  );
  final TextEditingController phoneController = TextEditingController(
    text: '+256701234567',
  );
  final TextEditingController emailController = TextEditingController(
    text: 'customer@example.com',
  );
  final TextEditingController descriptionController = TextEditingController(
    text: 'Payment for services',
  );

  @override
  void initState() {
    super.initState();
    _initializePaymentClient();
    _loadLastPaymentStatus();
  }

  void _initializePaymentClient() {
    // Check if credentials are configured
    if (!PesaPalConfig.isConfigured) {
      print(PesaPalConfig.configurationStatus);
      print(PesaPalConfig.securityWarning);
    }

    // Initialize with configuration from config.dart
    final config = PesaPalConfig.useProduction
        ? PaymentConfig.pesaPalProduction(
            consumerKey: PesaPalConfig.consumerKey,
            consumerSecret: PesaPalConfig.consumerSecret,
            callbackUrl: PesaPalConfig.callbackUrl,
            enableDebugLogging: PesaPalConfig.enableDebugLogging,
          )
        : PaymentConfig.pesaPalSandbox(
            consumerKey: PesaPalConfig.consumerKey,
            consumerSecret: PesaPalConfig.consumerSecret,
            callbackUrl: PesaPalConfig.callbackUrl,
            enableDebugLogging: PesaPalConfig.enableDebugLogging,
          );

    client = PaymentClient(config);
  }

  Future<void> _loadLastPaymentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastPaymentStatus = prefs.getString('last_payment_status');
      transactionId = prefs.getString('last_transaction_id');
    });
  }

  Future<void> _savePaymentStatus(String status, String? transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_payment_status', status);
    if (transactionId != null) {
      await prefs.setString('last_transaction_id', transactionId);
    }
  }

  Future<void> processPayment() async {
    if (amountController.text.isEmpty) {
      _showErrorDialog('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final request = PaymentRequest(
        amount: amount,
        currency: 'UGX',
        paymentMethod: 'PESAPAL',
        phoneNumber: phoneController.text,
        email: emailController.text,
        description: descriptionController.text,
        merchantReference: 'ORDER-${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'first_name': 'John',
          'last_name': 'Doe',
          'city': 'Kampala',
          'state': 'Central',
        },
      );

      final response = await client.processPayment(request);

      setState(() {
        transactionId = response.transactionId;
        redirectUrl = response.data?['redirect_url'];
        isLoading = false;
      });

      await _savePaymentStatus(
        response.status.toString(),
        response.transactionId,
      );

      if (response.isPending && redirectUrl != null) {
        // Automatically open the redirect URL in a WebView so the user
        // can complete payment without extra taps.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                url: redirectUrl!,
                transactionId: response.transactionId,
              ),
            ),
          );
        });
      } else if (response.isSuccessful) {
        _showSuccessDialog(response);
      } else {
        _showErrorDialog(response.message);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> checkTransactionStatus() async {
    if (transactionId == null) {
      _showErrorDialog('No transaction ID available');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final transaction = await client.getTransaction(transactionId!);

      setState(() {
        isLoading = false;
      });

      if (transaction != null) {
        _showTransactionDetailsDialog(transaction);
      } else {
        _showErrorDialog('Transaction not found');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error checking transaction: $e');
    }
  }

  void _showSuccessDialog(PaymentResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your payment has been processed successfully.'),
            SizedBox(height: 16),
            Text('Transaction ID: ${response.transactionId}'),
            Text('Amount: ${response.amount} ${response.currency}'),
            Text('Status: ${response.status}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetailsDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction.id}'),
            Text('Amount: ${transaction.amount} ${transaction.currency}'),
            Text('Status: ${transaction.status}'),
            Text('Payment Method: ${transaction.paymentMethod}'),
            Text('Created: ${transaction.createdAt}'),
            Text('Updated: ${transaction.updatedAt}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UgPayments • PesaPal'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Payment Flow',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submit an order, then the app opens Pesapal for completion.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (UGX)',
                        border: OutlineInputBorder(),
                        prefixText: 'UGX ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        hintText: '+256701234567',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        hintText: 'customer@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Payment for services',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (lastPaymentStatus != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Payment Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text('Status: $lastPaymentStatus'),
                      if (transactionId != null)
                        Text('Transaction ID: $transactionId'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading ? null : processPayment,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Order'),
                  ),
                ),
                SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: isLoading ? null : checkTransactionStatus,
                  child: const Text('Check Status'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (redirectUrl != null && lastPaymentStatus != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Redirect ready',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pesapal redirect URL is prepared. Completing payment will open automatically.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      if (transactionId != null)
                        Text('OrderTrackingId: $transactionId'),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration Info',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text('Environment: ${PesaPalConfig.environment}'),
                    Text('Base URL: ${PesaPalConfig.baseUrl}'),
                    Text('Provider: PesaPal'),
                    SizedBox(height: 8),
                    Text(
                      PesaPalConfig.isConfigured
                          ? '✅ Configured'
                          : '❌ Not Configured',
                      style: TextStyle(
                        color: PesaPalConfig.isConfigured
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.dispose();
    amountController.dispose();
    phoneController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  final String transactionId;

  PaymentWebViewScreen({required this.url, required this.transactionId});

  @override
  _PaymentWebViewScreenState createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
