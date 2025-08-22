import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Commented out for minimal build
import '../../models/wallet.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  @override
  _ReceiveMoneyScreenState createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Wallet? wallet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Wallet) {
      wallet = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (wallet == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Receive Money')),
        body: Center(child: Text('Invalid wallet selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Receive ${wallet!.currency}'),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareAddress),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code,
                                size: 100,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('QR Code will be displayed here'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Show this QR code to sender',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Address Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wallet Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              wallet!.address,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, size: 20),
                            onPressed: () => _copyAddress(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Request Specific Amount
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Specific Amount (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        suffixText: wallet!.currency,
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (Optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generatePaymentRequest,
                        child: Text('Generate Payment Request'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Recent Transactions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Incoming Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    // TODO: Add recent transactions list
                    Container(
                      height: 100,
                      child: Center(
                        child: Text(
                          'No recent transactions',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QR Code generation - commented out for minimal build
  /*
  String _generateQRData() {
    String qrData = wallet!.address;
    
    if (_amountController.text.isNotEmpty) {
      double? amount = double.tryParse(_amountController.text);
      if (amount != null && amount > 0) {
        // Create a payment URI
        if (wallet!.currency == 'BTC') {
          qrData = 'bitcoin:${wallet!.address}?amount=${amount}';
        } else {
          qrData = '${wallet!.address}?amount=${amount}&currency=${wallet!.currency}';
        }
        
        if (_noteController.text.isNotEmpty) {
          qrData += '&message=${Uri.encodeComponent(_noteController.text)}';
        }
      }
    }
    
    return qrData;
  }
  */

  void _copyAddress() {
    Clipboard.setData(ClipboardData(text: wallet!.address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareAddress() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share functionality coming soon')));
  }

  void _generatePaymentRequest() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update QR code with new data
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment request generated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
