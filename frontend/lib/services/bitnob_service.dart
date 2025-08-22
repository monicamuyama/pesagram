import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class BitnobService {
  // Use centralized configuration
  static String get baseUrl => ApiConfig.baseUrl;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> _clearAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Map<String, String> _getAuthHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication
  Future<User> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: _getAuthHeaders(null),
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phone': '+1234567890', // Default phone for demo
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['data']?['token'] ?? data['token'];
        if (token != null) {
          await _saveAuthToken(token);
        }
        
        // Convert user data to User object if it exists and return it directly
        final userData = data['data']?['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          return User.fromJson(userData);
        }
        
        throw Exception('Invalid user data received');
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<User> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: _getAuthHeaders(null),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['data']?['token'] ?? data['token'];
        if (token != null) {
          await _saveAuthToken(token);
        }
        
        // Convert user data to User object if it exists and return it directly
        final userData = data['data']?['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          return User.fromJson(userData);
        }
        
        throw Exception('Invalid user data received');
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Sign in failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> signOut() async {
    await _clearAuthToken();
  }

  // Wallet Management
  Future<List<Wallet>> getWallets() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wallet'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> walletsData = data['data']?['wallets'] ?? data['wallets'] ?? [];

        return walletsData.map((walletData) {
          return Wallet(
            id: walletData['id']?.toString() ?? '',
            currency: walletData['currency'] ?? '',
            balance: (walletData['balance'] ?? 0.0).toDouble(),
            address: walletData['address'] ?? 'N/A',
            isActive: walletData['isActive'] ?? true,
            createdAt: walletData['createdAt'] != null
                ? DateTime.parse(walletData['createdAt'])
                : DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception('Failed to get wallets');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Wallet> createWallet(String currency) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/wallet'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({'currency': currency}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final walletData = data['wallet'];

        return Wallet(
          id: walletData['id']?.toString() ?? '',
          currency: walletData['currency'] ?? currency,
          balance: (walletData['balance'] ?? 0.0).toDouble(),
          address: walletData['address'] ?? 'N/A',
          isActive: walletData['isActive'] ?? true,
          createdAt: walletData['createdAt'] != null
              ? DateTime.parse(walletData['createdAt'])
              : DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create wallet');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<double> getWalletBalance(String walletId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wallet/$walletId/balance'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balance'] ?? 0.0).toDouble();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get wallet balance');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Transaction Management
  Future<List<Transaction>> getTransactions({String? walletId}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      String url = '$baseUrl/transaction';
      if (walletId != null) {
        url += '?walletId=$walletId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> transactionsData = data['transactions'] ?? [];

        return transactionsData.map((txData) {
          return Transaction(
            id: txData['id']?.toString() ?? '',
            type: txData['type'] ?? 'unknown',
            amount: (txData['amount'] ?? 0.0).toDouble(),
            fromCurrency: txData['currency'] ?? '',
            status: txData['status'] ?? 'pending',
            recipient: txData['recipient'] ?? '',
            createdAt: txData['createdAt'] != null
                ? DateTime.parse(txData['createdAt'])
                : DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception('Failed to get transactions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Transaction> sendTransaction({
    required String fromWalletId,
    required String toAddress,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/send'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'fromWalletId': fromWalletId,
          'toAddress': toAddress,
          'amount': amount,
          'currency': currency,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final txData = data['transaction'];

        return Transaction(
          id: txData['id']?.toString() ?? '',
          type: txData['type'] ?? 'send',
          amount: (txData['amount'] ?? 0.0).toDouble(),
          fromCurrency: txData['currency'] ?? currency,
          status: txData['status'] ?? 'pending',
          recipient: txData['recipient'] ?? toAddress,
          createdAt: txData['createdAt'] != null
              ? DateTime.parse(txData['createdAt'])
              : DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send transaction');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Transaction> swapCurrency({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/swap'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'fromWalletId': fromWalletId,
          'toWalletId': toWalletId,
          'amount': amount,
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final txData = data['transaction'];

        return Transaction(
          id: txData['id']?.toString() ?? '',
          type: txData['type'] ?? 'swap',
          amount: (txData['amount'] ?? 0.0).toDouble(),
          fromCurrency: txData['currency'] ?? fromCurrency,
          toCurrency: toCurrency,
          status: txData['status'] ?? 'pending',
          recipient: txData['recipient'] ?? '',
          createdAt: txData['createdAt'] != null
              ? DateTime.parse(txData['createdAt'])
              : DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to swap currency');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // KYC Submission
  Future<Map<String, dynamic>> submitKyc({
    required String idType,
    required String idNumber,
    required String idImage,
    required String selfieImage,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/kyc/submit'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({
        'idType': idType,
        'idNumber': idNumber,
        'idImage': idImage,
        'selfieImage': selfieImage,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data['data']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'KYC submission failed'};
    }
  }

  Future<Map<String, dynamic>> getKycStatus() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/kyc/status'),
      headers: _getAuthHeaders(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': data['data']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Failed to fetch KYC status'};
    }
  }

  // 2FA: Request OTP
  Future<Map<String, dynamic>> request2faOtp() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-2fa'),
      headers: _getAuthHeaders(token),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Failed to request OTP'};
    }
  }

  // 2FA: Verify OTP
  Future<Map<String, dynamic>> verify2faOtp(String otp) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-2fa'),
      headers: _getAuthHeaders(token),
      body: jsonEncode({'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Failed to verify OTP'};
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null;
  }

  // Lightning Network Methods
  Future<Map<String, dynamic>> createLightningInvoice({
    required int amountSats,
    String? description,
    int? expirySeconds,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/lightning/invoice'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'amount': amountSats,
          'description': description ?? 'Lightning payment',
          'expiry': expirySeconds ?? 3600, // 1 hour default
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'invoice': data['data']?['invoice'],
          'paymentRequest': data['data']?['payment_request'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create Lightning invoice'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> payLightningInvoice(String invoice) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/lightning/pay'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'invoice': invoice,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'paymentHash': data['data']?['payment_hash'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to pay Lightning invoice'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Mobile Money Methods
  Future<Map<String, dynamic>> sendToMobileMoney({
    required String phoneNumber,
    required double amount,
    required String currency,
    required String provider, // MTN, AIRTEL, etc.
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/mobile-money'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'currency': currency,
          'provider': provider,
          'description': description ?? 'Mobile money transfer',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'transactionId': data['data']?['transaction_id'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to send to mobile money'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<List<String>> getMobileMoneyProviders() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/mobile-money/providers'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> providers = data['data']?['providers'] ?? [];
        return providers.cast<String>();
      } else {
        throw Exception('Failed to get mobile money providers');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Recurring Payments Methods
  Future<Map<String, dynamic>> createRecurringPayment({
    required String recipientType, // 'address', 'phone', 'mobile_money'
    required String recipient,
    required double amount,
    required String currency,
    required String frequency, // 'daily', 'weekly', 'monthly'
    required DateTime startDate,
    DateTime? endDate,
    int? maxPayments,
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/recurring-payments'),
        headers: _getAuthHeaders(token),
        body: jsonEncode({
          'recipientType': recipientType,
          'recipient': recipient,
          'amount': amount,
          'currency': currency,
          'frequency': frequency,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'maxPayments': maxPayments,
          'description': description ?? 'Recurring payment',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'scheduleId': data['data']?['schedule_id'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create recurring payment'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getRecurringPayments() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/recurring-payments'),
        headers: _getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> payments = data['data']?['payments'] ?? [];
        return payments.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get recurring payments');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> cancelRecurringPayment(String scheduleId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/recurring-payments/$scheduleId'),
        headers: _getAuthHeaders(token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Recurring payment cancelled',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to cancel recurring payment'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
