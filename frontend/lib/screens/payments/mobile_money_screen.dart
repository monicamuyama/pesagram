import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/bitnob_service.dart';
import '../../utils/constants.dart';

class MobileMoneyScreen extends StatefulWidget {
  @override
  _MobileMoneyScreenState createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends State<MobileMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final BitnobService _bitnobService = BitnobService();
  
  String _selectedProvider = 'MTN';
  String _selectedCurrency = 'UGX';
  bool _isLoading = false;
  List<String> _providers = [];
  
  // Available mobile money providers
  final List<Map<String, dynamic>> _mobileMoneyProviders = [
    {
      'code': 'MTN',
      'name': 'MTN Mobile Money',
      'icon': Icons.phone_android,
      'color': Colors.yellow.shade600,
      'currencies': ['UGX', 'RWF', 'ZMB'],
      'format': '+256XXXXXXXXX'
    },
    {
      'code': 'AIRTEL',
      'name': 'Airtel Money',
      'icon': Icons.phone_android,
      'color': Colors.red.shade600,
      'currencies': ['UGX', 'KES', 'TZS'],
      'format': '+256XXXXXXXXX'
    },
    {
      'code': 'MPESA',
      'name': 'M-Pesa',
      'icon': Icons.phone_android,
      'color': Colors.green.shade600,
      'currencies': ['KES', 'TZS'],
      'format': '+254XXXXXXXXX'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await _bitnobService.getMobileMoneyProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      print('Failed to load providers: $e');
      // Use default providers if API fails
      setState(() {
        _providers = _mobileMoneyProviders.map((p) => p['code'].toString()).toList();
      });
    }
  }

  Map<String, dynamic>? get _selectedProviderInfo {
    return _mobileMoneyProviders.firstWhere(
      (p) => p['code'] == _selectedProvider,
      orElse: () => _mobileMoneyProviders.first,
    );
  }

  Future<void> _sendToMobileMoney() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      final result = await _bitnobService.sendToMobileMoney(
        phoneNumber: phoneNumber,
        amount: amount,
        currency: _selectedCurrency,
        provider: _selectedProvider,
        description: description.isEmpty ? null : description,
      );

      if (result['success']) {
        _showSuccessDialog(
          'Transfer Initiated',
          'Mobile money transfer has been initiated successfully!\n\n'
          'Provider: ${_selectedProviderInfo?['name']}\n'
          'Phone: $phoneNumber\n'
          'Amount: $amount $_selectedCurrency\n\n'
          'Transaction ID: ${result['transactionId']}',
        );
        
        // Clear form
        _phoneController.clear();
        _amountController.clear();
        _descriptionController.clear();
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to send to mobile money');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
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
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        title: Text('Mobile Money Transfer'),
        backgroundColor: _selectedProviderInfo?['color'] ?? Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Provider Selection
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Provider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _mobileMoneyProviders.map((provider) {
                          final isSelected = provider['code'] == _selectedProvider;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProvider = provider['code'];
                                // Set default currency for provider
                                final currencies = provider['currencies'] as List<String>;
                                if (!currencies.contains(_selectedCurrency)) {
                                  _selectedCurrency = currencies.first;
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? provider['color'] 
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? provider['color'] 
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    provider['icon'],
                                    color: isSelected ? Colors.white : Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    provider['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Phone Number Input
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipient Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: _selectedProviderInfo?['format'] ?? '+256XXXXXXXXX',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (!value.startsWith('+')) {
                            return 'Phone number must include country code (e.g., +256)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Amount and Currency
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Amount is required';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: (_selectedProviderInfo?['currencies'] as List<String>? ?? ['UGX'])
                                  .map((currency) => DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Description (Optional)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'What is this payment for?',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Send Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendToMobileMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedProviderInfo?['color'] ?? Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send to ${_selectedProviderInfo?['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              
              SizedBox(height: 16),
              
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Transaction Info',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The recipient will receive an SMS notification to complete the transaction. '
                        'Processing time is typically 1-5 minutes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
