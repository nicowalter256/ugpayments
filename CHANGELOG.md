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
