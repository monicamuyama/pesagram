import 'dart:io';

class ApiConfig {
  // Environment configuration
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  // Your computer's IP address (replace with your actual IP)
  static const String _computerIp = '192.168.89.17'; // Updated with your actual IP
  
  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:3000/api', // For web/desktop
    'development-mobile': 'http://$_computerIp:3000/api', // For mobile
    'staging': 'https://your-staging-api.vercel.app/api',
    'production': 'https://your-production-api.vercel.app/api',
  };
  
  // Get the current base URL based on environment and platform
  static String get baseUrl {
    if (_environment == 'development') {
      // Auto-detect platform and use appropriate URL
      if (Platform.isAndroid || Platform.isIOS) {
        return _baseUrls['development-mobile']!;
      } else {
        return _baseUrls['development']!;
      }
    }
    return _baseUrls[_environment] ?? _baseUrls['development']!;
  }
  
  // Helper method to manually set IP for mobile testing
  static String getMobileDevUrl(String computerIp) {
    return 'http://$computerIp:3000/api';
  }
  
  // Helper to check if running on mobile
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  // API endpoints
  static const String authSignup = '/auth/signup';
  static const String authSignin = '/auth/signin';
  static const String authLogout = '/auth/logout';
  static const String authVerify = '/auth/verify';
  static const String authRequest2FA = '/auth/request-2fa';
  static const String authVerify2FA = '/auth/verify-2fa';
  
  static const String wallets = '/wallet';
  static const String walletBalance = '/wallet/{id}/balance';
  static const String walletRates = '/wallet/rates';
  
  static const String transactions = '/transaction';
  static const String transactionSend = '/transaction/send';
  static const String transactionSwap = '/transaction/swap';
  
  static const String kycSubmit = '/kyc/submit';
  static const String kycStatus = '/kyc/status';
  
  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  
  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // API configuration
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Debug settings
  static bool get isDebugMode => _environment == 'development';
  
  // Environment helpers
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';
}
