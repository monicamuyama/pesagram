import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/bitnob_service.dart';

class LightningScreen extends StatefulWidget {
  @override
  _LightningScreenState createState() => _LightningScreenState();
}

class _LightningScreenState extends State<LightningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BitnobService _bitnobService = BitnobService();
  
  // Create Invoice form
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invoiceFormKey = GlobalKey<FormState>();
  
  // Pay Invoice form
  final _invoiceController = TextEditingController();
  final _payFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _generatedInvoice;
  String? _paymentResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    if (!_invoiceFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedInvoice = null;
    });

    try {
      final amountSats = int.parse(_amountController.text);
      final description = _descriptionController.text;

      final result = await _bitnobService.createLightningInvoice(
        amountSats: amountSats,
        description: description.isEmpty ? null : description,
      );

      if (result['success']) {
        setState(() {
          _generatedInvoice = result['paymentRequest'] ?? result['invoice'];
        });
        
        _showSuccessDialog('Invoice Created', 
          'Lightning invoice created successfully!\n\nAmount: $amountSats sats');
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to create invoice');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _payInvoice() async {
    if (!_payFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _paymentResult = null;
    });

    try {
      final invoice = _invoiceController.text.trim();

      final result = await _bitnobService.payLightningInvoice(invoice);

      if (result['success']) {
        setState(() {
          _paymentResult = 'Payment successful!';
        });
        
        _showSuccessDialog('Payment Sent', 
          'Lightning payment sent successfully!\n\nPayment Hash: ${result['paymentHash']}');
        
        _invoiceController.clear();
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to pay invoice');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
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
            onPressed: () => Navigator.pop(context),
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
            onPressed: () => Navigator.pop(context),
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
        title: Row(
          children: [
            Icon(Icons.bolt, color: Colors.orange),
            SizedBox(width: 8),
            Text('Lightning Network'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Create Invoice'),
            Tab(text: 'Pay Invoice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateInvoiceTab(),
          _buildPayInvoiceTab(),
        ],
      ),
    );
  }

  Widget _buildCreateInvoiceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _invoiceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.receipt, size: 48, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      'Create Lightning Invoice',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generate a Lightning invoice to receive instant payments',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (satoshis)',
                prefixIcon: Icon(Icons.bolt),
                helperText: '1 BTC = 100,000,000 sats',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Amount is required';
                final amount = int.tryParse(value!);
                if (amount == null || amount <= 0) return 'Valid amount required';
                if (amount < 1000) return 'Minimum 1,000 sats';
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLength: 200,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createInvoice,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Creating...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.create),
                        SizedBox(width: 8),
                        Text('Create Invoice'),
                      ],
                    ),
            ),
            if (_generatedInvoice != null) ...[
              SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Invoice Generated',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Lightning Invoice:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _generatedInvoice!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(_generatedInvoice!),
                        icon: Icon(Icons.copy),
                        label: Text('Copy Invoice'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayInvoiceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _payFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.send, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Pay Lightning Invoice',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Paste a Lightning invoice to send instant payment',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _invoiceController,
              decoration: InputDecoration(
                labelText: 'Lightning Invoice',
                prefixIcon: Icon(Icons.bolt),
                hintText: 'lnbc1...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.paste),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData?.text != null) {
                      _invoiceController.text = clipboardData!.text!;
                    }
                  },
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Invoice is required';
                if (!value!.toLowerCase().startsWith('lnbc')) {
                  return 'Invalid Lightning invoice format';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _payInvoice,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Paying...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text('Pay Invoice'),
                      ],
                    ),
            ),
            if (_paymentResult != null) ...[
              SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _paymentResult!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
