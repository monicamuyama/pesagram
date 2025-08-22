class AppConstants {
  // App configuration
  static const String appName = 'Pesagram';
  static const String appVersion = '1.0.0';
  
  // Bitnob API configuration
  static const String bitnobBaseUrl = 'https://api.bitnob.co/api/v1';
  static const String bitnobApiKey = 'your_bitnob_api_key';
  
  // Mobile Money Providers
  static const List<Map<String, dynamic>> mobileMoneyProviders = [
    {
      'name': 'MTN Mobile Money',
      'code': 'mtn',
      'color': 0xFFFFD700, // Yellow
      'currencies': ['UGX'],
      'icon': '📱',
    },
    {
      'name': 'Airtel Money',
      'code': 'airtel',
      'color': 0xFFFF0000, // Red
      'currencies': ['UGX', 'KES', 'TZS'],
      'icon': '💳',
    },
    {
      'name': 'M-Pesa',
      'code': 'mpesa',
      'color': 0xFF00AA00, // Green
      'currencies': ['KES', 'TZS'],
      'icon': '💰',
    },
  ];
  
  // Supported currencies
  static const List<String> supportedCurrencies = [
    'UGX',
    'KES',
    'TZS',
    'USD',
    'BTC',
    'NGN',
  ];
  
  // Transaction types
  static const List<String> transactionTypes = [
    'send',
    'receive',
    'swap',
    'lightning',
    'mobile_money',
    'recurring',
  ];
  
  // Recurring payment frequencies
  static const List<String> recurringFrequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];
  
  // API endpoints
  static const String signInEndpoint = '/signin';
  static const String signUpEndpoint = '/signup';
  static const String verifyEndpoint = '/verify';
  static const String walletEndpoint = '/wallet';
  static const String transactionEndpoint = '/transaction';
  static const String lightningEndpoint = '/lightning';
  static const String mobileMoneyEndpoint = '/mobile-money';
  static const String recurringPaymentsEndpoint = '/recurring-payments';
  static const String kycEndpoint = '/kyc';
  static const String twoFactorEndpoint = '/auth/2fa';
  
  // Storage keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String themeKey = 'theme_mode';
  
  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String generalErrorMessage = 'Something went wrong. Please try again.';
  static const String invalidCredentialsMessage = 'Invalid credentials. Please try again.';
  static const String accountNotVerifiedMessage = 'Account not verified. Please verify your email.';
  
  // Success messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Registration successful! Please verify your email.';
  static const String transactionSuccessMessage = 'Transaction completed successfully!';
  static const String verificationSuccessMessage = 'Account verified successfully!';
}
