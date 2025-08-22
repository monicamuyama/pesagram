import 'package:flutter/material.dart';
import '../../services/bitnob_service.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  @override
  _RecurringPaymentsScreenState createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BitnobService _bitnobService = BitnobService();
  
  // Create recurring payment form
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _recipientType = 'address'; // 'address', 'phone', 'mobile_money'
  String _selectedCurrency = 'BTC';
  String _frequency = 'monthly'; // 'daily', 'weekly', 'monthly'
  DateTime _startDate = DateTime.now().add(Duration(days: 1));
  DateTime? _endDate;
  int? _maxPayments;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _recurringPayments = [];

  final List<String> _currencies = ['BTC', 'USDT', 'UGX'];
  final List<String> _frequencies = ['daily', 'weekly', 'monthly'];
  final List<Map<String, String>> _recipientTypes = [
    {'value': 'address', 'label': 'Crypto Address'},
    {'value': 'phone', 'label': 'Phone Number'},
    {'value': 'mobile_money', 'label': 'Mobile Money'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecurringPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecurringPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await _bitnobService.getRecurringPayments();
      setState(() {
        _recurringPayments = payments;
      });
    } catch (e) {
      _showErrorDialog('Failed to load recurring payments: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRecurringPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recipient = _recipientController.text.trim();
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();

      final result = await _bitnobService.createRecurringPayment(
        recipientType: _recipientType,
        recipient: recipient,
        amount: amount,
        currency: _selectedCurrency,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        maxPayments: _maxPayments,
        description: description.isEmpty ? null : description,
      );

      if (result['success']) {
        _showSuccessDialog(
          'Recurring Payment Created',
          'Your recurring payment has been set up successfully!\n\n'
          'Schedule ID: ${result['scheduleId']}\n'
          'Recipient: $recipient\n'
          'Amount: $amount $_selectedCurrency\n'
          'Frequency: $_frequency',
        );
        
        // Clear form
        _recipientController.clear();
        _amountController.clear();
        _descriptionController.clear();
        
        // Reload payments
        _loadRecurringPayments();
        
        // Switch to list tab
        _tabController.animateTo(1);
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to create recurring payment');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRecurringPayment(String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Recurring Payment'),
        content: Text('Are you sure you want to cancel this recurring payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _bitnobService.cancelRecurringPayment(scheduleId);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recurring payment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecurringPayments();
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to cancel recurring payment');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _selectDate(bool isEndDate) async {
    final initialDate = isEndDate ? (_endDate ?? _startDate) : _startDate;
    final firstDate = isEndDate ? _startDate : DateTime.now();
    final lastDate = DateTime.now().add(Duration(days: 365 * 2)); // 2 years
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (selectedDate != null) {
      setState(() {
        if (isEndDate) {
          _endDate = selectedDate;
        } else {
          _startDate = selectedDate;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        }
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
            onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildCreatePaymentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipient Type Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _recipientType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _recipientTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _recipientType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Recipient Input
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _recipientController,
                      decoration: InputDecoration(
                        labelText: _getRecipientLabel(),
                        hintText: _getRecipientHint(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Recipient is required';
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
                      'Payment Amount',
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
                            items: _currencies.map((currency) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
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

            // Frequency and Schedule
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _frequencies.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency.substring(0, 1).toUpperCase() + frequency.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _frequency = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Start Date
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // End Date (Optional)
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Date (Optional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _endDate != null 
                                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                        : 'No end date',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            if (_endDate != null)
                              IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => setState(() => _endDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Description
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
                        hintText: 'What is this recurring payment for?',
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

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createRecurringPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                      'Create Recurring Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentListTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_recurringPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Recurring Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first recurring payment',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _recurringPayments.length,
      itemBuilder: (context, index) {
        final payment = _recurringPayments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${payment['amount']} ${payment['currency']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment['status']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'To: ${payment['recipient']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Frequency: ${payment['frequency']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (payment['description'] != null)
                  Text(
                    'Description: ${payment['description']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${_formatDate(payment['nextPaymentDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _cancelRecurringPayment(payment['scheduleId']),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRecipientLabel() {
    switch (_recipientType) {
      case 'address':
        return 'Crypto Address';
      case 'phone':
        return 'Phone Number';
      case 'mobile_money':
        return 'Mobile Money Number';
      default:
        return 'Recipient';
    }
  }

  String _getRecipientHint() {
    switch (_recipientType) {
      case 'address':
        return 'Enter wallet address';
      case 'phone':
        return '+256XXXXXXXXX';
      case 'mobile_money':
        return '+256XXXXXXXXX';
      default:
        return 'Enter recipient';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recurring Payments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Create', icon: Icon(Icons.add)),
            Tab(text: 'My Payments', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreatePaymentTab(),
          _buildPaymentListTab(),
        ],
      ),
    );
  }
}
