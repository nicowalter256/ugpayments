/// Utility class for validating payment-related data.
class PaymentValidator {
  /// Validates an email address format.
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validates a phone number format for Uganda.
  static bool isValidUgandanPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ugandan mobile numbers: +256XXXXXXXXX or 0XXXXXXXXX
    if (cleanNumber.startsWith('256') && cleanNumber.length == 12) {
      return true;
    }

    if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return true;
    }

    return false;
  }

  /// Validates an amount (must be positive).
  static bool isValidAmount(double amount) {
    return amount > 0;
  }

  /// Validates a currency code.
  static bool isValidCurrency(String currency) {
    final validCurrencies = ['UGX', 'USD', 'EUR', 'GBP', 'KES'];
    return validCurrencies.contains(currency.toUpperCase());
  }

  /// Validates a payment method.
  static bool isValidPaymentMethod(String paymentMethod) {
    final validMethods = [
      'MOBILE_MONEY',
      'BANK_TRANSFER',
      'CARD_PAYMENT',
      'CASH',
    ];
    return validMethods.contains(paymentMethod.toUpperCase());
  }

  /// Validates a transaction ID format.
  static bool isValidTransactionId(String transactionId) {
    // Transaction IDs should be alphanumeric and at least 10 characters
    final transactionIdRegex = RegExp(r'^[A-Za-z0-9_]{10,}$');
    return transactionIdRegex.hasMatch(transactionId);
  }

  /// Validates a merchant reference ID.
  static bool isValidMerchantReference(String merchantReference) {
    // Merchant references should be alphanumeric and at least 5 characters
    final merchantRefRegex = RegExp(r'^[A-Za-z0-9_-]{5,}$');
    return merchantRefRegex.hasMatch(merchantReference);
  }

  /// Validates a card number using Luhn algorithm.
  static bool isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validates a CVV code.
  static bool isValidCvv(String cvv) {
    final cleanCvv = cvv.replaceAll(RegExp(r'[^\d]'), '');
    return cleanCvv.length >= 3 && cleanCvv.length <= 4;
  }

  /// Validates an expiry date.
  static bool isValidExpiryDate(String month, String year) {
    try {
      final expiryMonth = int.parse(month);
      final expiryYear = int.parse(year);

      if (expiryMonth < 1 || expiryMonth > 12) {
        return false;
      }

      final now = DateTime.now();
      final expiryDate = DateTime(expiryYear, expiryMonth);

      return expiryDate.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// Validates a bank account number format.
  static bool isValidBankAccountNumber(String accountNumber) {
    final cleanNumber = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanNumber.length >= 10 && cleanNumber.length <= 15;
  }

  /// Sanitizes a phone number to international format.
  static String sanitizePhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return '+256${cleanNumber.substring(1)}';
    }

    if (cleanNumber.startsWith('256') && cleanNumber.length == 12) {
      return '+$cleanNumber';
    }

    return phoneNumber;
  }

  /// Formats an amount with proper decimal places.
  static String formatAmount(double amount, String currency) {
    if (currency.toUpperCase() == 'UGX') {
      // Ugandan Shillings typically don't use decimal places
      return amount.toInt().toString();
    } else {
      // Other currencies use 2 decimal places
      return amount.toStringAsFixed(2);
    }
  }
}
