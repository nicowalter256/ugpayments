import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/payment_status.dart';
import '../core/payment_exception.dart';

/// Handles bank transfer payment processing.
class BankTransfer {
  /// Supported banks in Uganda.
  static const List<String> supportedBanks = [
    'STANBIC_BANK',
    'CENTENARY_BANK',
    'DFCU_BANK',
    'BARCLAYS_BANK',
    'STANDARD_CHARTERED',
    'BANK_OF_AFRICA',
  ];

  /// Processes a bank transfer payment.
  ///
  /// [request] should contain bank account details and amount.
  /// Returns a [PaymentResponse] with the result.
  Future<PaymentResponse> processPayment(PaymentRequest request) async {
    try {
      // Validate the request
      _validateRequest(request);

      // Simulate bank transfer processing
      // In a real implementation, this would call the bank's API
      await Future.delayed(const Duration(seconds: 3));

      // Generate a mock response
      return PaymentResponse(
        transactionId: _generateTransactionId(),
        status: PaymentStatus.pending,
        message: 'Bank transfer initiated successfully',
        amount: request.amount,
        currency: request.currency,
        timestamp: DateTime.now(),
        data: {
          'bankName': _extractBankName(request),
          'accountNumber': _extractAccountNumber(request),
          'transferType': 'BANK_TRANSFER',
        },
      );
    } catch (e) {
      throw PaymentException('Bank transfer failed: $e');
    }
  }

  /// Validates a bank transfer payment request.
  void _validateRequest(PaymentRequest request) {
    if (request.metadata == null) {
      throw PaymentException.invalidData('metadata (bank details)');
    }

    final bankName = request.metadata!['bankName'];
    final accountNumber = request.metadata!['accountNumber'];

    if (bankName == null || bankName.toString().isEmpty) {
      throw PaymentException.invalidData('bankName');
    }

    if (accountNumber == null || accountNumber.toString().isEmpty) {
      throw PaymentException.invalidData('accountNumber');
    }

    if (!isBankSupported(bankName.toString())) {
      throw PaymentException('Unsupported bank: $bankName');
    }

    if (request.amount <= 0) {
      throw PaymentException.invalidData('amount');
    }
  }

  /// Extracts bank name from the request metadata.
  String _extractBankName(PaymentRequest request) {
    return request.metadata!['bankName']?.toString() ?? '';
  }

  /// Extracts account number from the request metadata.
  String _extractAccountNumber(PaymentRequest request) {
    return request.metadata!['accountNumber']?.toString() ?? '';
  }

  /// Generates a unique transaction ID for bank transfers.
  String _generateTransactionId() {
    return 'BT_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Checks if a bank is supported.
  static bool isBankSupported(String bankName) {
    return supportedBanks.contains(bankName.toUpperCase());
  }

  /// Gets the list of supported banks.
  static List<String> getSupportedBanks() {
    return List.from(supportedBanks);
  }

  /// Validates an account number format.
  static bool isValidAccountNumber(String accountNumber) {
    // Basic validation for Ugandan bank account numbers
    // Account numbers are typically 10-15 digits
    final cleanNumber = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanNumber.length >= 10 && cleanNumber.length <= 15;
  }
}
