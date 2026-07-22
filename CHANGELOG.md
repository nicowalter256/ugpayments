## 0.2.1

- Docs: fix the install snippet in README.md, which still referenced the
  original `^0.0.1` version constraint
- Docs: replace the "Error Handling" example's `code`-string switch (which
  matched codes the library didn't actually throw, e.g. `INVALID_DATA`,
  `AUTH_FAILED`) with an exhaustive `switch` over the concrete
  `PaymentException` subtypes introduced in 0.2.0

## 0.2.0

- BREAKING: `PaymentException` is now a `sealed` class hierarchy instead of a
  single concrete class. Catching `PaymentException` still catches every
  case, but code that constructed it directly (`PaymentException('...')`)
  must switch to one of the typed factories/subtypes: `PaymentException.invalidData`,
  `.authenticationFailed`, `.networkError`, `.insufficientFunds`, `.timeout`,
  `.validation` (request-validation failures), or `.api` (arbitrary PesaPal
  API/transport failures). This also lets calling code exhaustively `switch`
  over the concrete exception subtypes.
- Fixes:
  - `PesaPalProvider`/`TokenManager` catch-alls no longer re-wrap an
    already-thrown `PaymentException`, so `code`/`details`/`originalException`
    now survive instead of being lost behind a generic wrapper message
  - `PesaPalProvider.getTransactionStatus`'s catch-all now sanitizes the
    caught error before interpolating it into the exception message, matching
    the rest of the file
- Hardening: public data models and service classes (`PaymentClient`,
  `PaymentConfig`, `TokenManager`, `PesaPalProvider`, `PaymentRequest`,
  `PaymentResponse`, `Transaction`, `CardDetails`, `PaymentValidator`,
  `Encryption`, `HttpClientFactory`, `PaymentConstants`,
  `PesaPalRedirectWebViewPage`, and the deprecated legacy processors) are now
  declared `final class` so they can't be extended/implemented outside this
  package, protecting constructor-time invariants like metadata redaction
- Example app now completes checkout using the package's hardened
  `PesaPalRedirectWebViewPage` (with `*.pesapal.com` allowlisting) instead of
  its own unrestricted WebView

## 0.1.4

- Fixes:
  - `PesaPalProvider.submitOrder` no longer fabricates a local `notification_id`; it now registers an IPN with PesaPal (matching `PaymentClient`) when one isn't configured
  - `PaymentClient.getTransaction` no longer always returns `null`; it now delegates to `PesaPalProvider` and returns a populated `Transaction`
  - `PaymentClient` and `PesaPalProvider` no longer duplicate PesaPal order logic; `PaymentClient` delegates to `PesaPalProvider`
  - Unified sensitive-key redaction between `PaymentRequest`/`PaymentResponse` serialization (was missing `pan`/`cvv2` in one of the two)
  - `PaymentConstants.supportedPaymentMethods` now includes `PESAPAL`
  - `PaymentClient` now validates currency and payment method against `PaymentValidator`

## 0.1.3

- SECURITY (BREAKING/behavioral):
  - Replace insecure XOR encryption with AES-256-GCM (authenticated encryption) using external keys
  - Replace custom hashing with SHA-256 + constant-time comparisons
  - Add TLS certificate pinning (fail-closed in production) via HttpClient factory
  - Harden PesaPal WebView with `https://*.pesapal.com` allowlisting and safer redirect handling
  - Store PesaPal tokens securely using `flutter_secure_storage` with early refresh
  - Add PCI-aware `CardDetails` model (CVV not stored/serialized) and sanitize legacy card fields
  - Disable legacy simulated `CardPayment`, `MobileMoney`, and `BankTransfer` processors (runtime disabled)
  - Prevent credential leakage by removing secrets from `PaymentConfig.toJson()` and sanitizing `PaymentResponse.toJson()`
  - Replace timestamp-based IDs with UUID v4

## 0.1.2

- Docs: sync READMEs with the latest PesaPal flow (consumerKey/consumerSecret
  and automatic redirect WebView).

## 0.1.1

- Fix PesaPal redirect WebView getting stuck by enabling JavaScript, improving
  navigation/error callbacks, and allowing third-party cookies on Android.
- Remove unused notification id generator and switch token logging to `dart:developer`.

## 0.1.0

- **BREAKING CHANGE**: Simplified PesaPal authentication
  - Changed from `apiKey`/`apiSecret` to `consumerKey`/`consumerSecret`
  - Automatic token authentication - no manual token management required
  - Added TokenManager for automatic token fetching and caching
  - Tokens are automatically refreshed when they expire
- **New Features**:
  - Automatic PesaPal token authentication via `/api/Auth/RequestToken` endpoint
  - Token caching and automatic refresh
  - Simplified user experience - only requires consumer credentials
- **Improvements**:
  - Updated all examples to use new authentication method
  - Enhanced documentation with simplified setup instructions
  - Better error handling for token requests
  - Improved security with no exposed credentials in examples
- **Bug Fixes**:
  - Fixed API endpoint paths for PesaPal integration
  - Updated all tests to use new parameter names
  - Ensured proper resource cleanup with dispose methods

## 0.0.1

- Initial release of the ugpayments package
- Core payment functionality with support for multiple payment methods
- **PesaPal Integration**: Full integration with PesaPal payment gateway
  - Order submission via PesaPal API
  - Transaction status tracking
  - Redirect URL handling
  - Callback notifications
  - Correct sandbox URL: https://cybqa.pesapal.com/pesapalv3
  - Correct production URL: https://pay.pesapal.com/v3
- Mobile money payment processing (MTN, Airtel, M-Pesa)
- Bank transfer payment processing
- Card payment processing with validation
- Comprehensive data validation utilities
- Encryption and security utilities
- JSON serialization support for all models
- Robust error handling with specific exception types
- Complete test coverage (32 tests)
- Full documentation and usage examples
- PesaPal-specific configuration options
- Provider-based architecture for extensibility
