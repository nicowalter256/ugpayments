import 'package:flutter/material.dart';
import 'package:ugpayments/ugpayments.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UgPayments Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
            apiKey: PesaPalConfig.apiKey,
            apiSecret: PesaPalConfig.apiSecret,
            callbackUrl: PesaPalConfig.callbackUrl,
            notificationId: PesaPalConfig.notificationId,
            enableDebugLogging: PesaPalConfig.enableDebugLogging,
          )
        : PaymentConfig.pesaPalSandbox(
            apiKey: PesaPalConfig.apiKey,
            apiSecret: PesaPalConfig.apiSecret,
            callbackUrl: PesaPalConfig.callbackUrl,
            notificationId: PesaPalConfig.notificationId,
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
        _showPaymentDialog();
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

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your payment is pending. Please complete it by clicking the link below.',
            ),
            SizedBox(height: 16),
            Text(
              'Transaction ID: $transactionId',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openPaymentUrl();
            },
            child: Text('Open Payment'),
          ),
        ],
      ),
    );
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

  Future<void> _openPaymentUrl() async {
    if (redirectUrl != null) {
      final Uri url = Uri.parse(redirectUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Could not open payment URL');
      }
    }
  }

  void _openPaymentWebView() {
    if (redirectUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            url: redirectUrl!,
            transactionId: transactionId!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UgPayments Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  child: ElevatedButton(
                    onPressed: isLoading ? null : processPayment,
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Process Payment'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : checkTransactionStatus,
                  child: Text('Check Status'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (redirectUrl != null) ...[
              ElevatedButton.icon(
                onPressed: _openPaymentUrl,
                icon: Icon(Icons.open_in_browser),
                label: Text('Open Payment in Browser'),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _openPaymentWebView,
                icon: Icon(Icons.web),
                label: Text('Open Payment in WebView'),
              ),
            ],
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
