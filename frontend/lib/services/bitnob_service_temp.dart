import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';

class BitnobService {
  // Backend configuration - update this to your deployed backend URL
  static const String baseUrl = 'http://localhost:3000/api';

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
  Future<Map<String, dynamic>> signUp(
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
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await _saveAuthToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Sign up failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: _getAuthHeaders(null),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveAuthToken(data['token']);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Sign in failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
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
        final List<dynamic> walletsData = data['wallets'] ?? [];

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
            fromCurrency: txData['fromCurrency'] ?? txData['currency'] ?? '',
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
          fromCurrency: txData['fromCurrency'] ?? currency,
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
          fromCurrency: txData['fromCurrency'] ?? fromCurrency,
          toCurrency: txData['toCurrency'] ?? toCurrency,
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

  Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null;
  }
}
