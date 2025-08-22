import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/wallet.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../blocs/wallet/wallet_event.dart';

class SwapScreen extends StatefulWidget {
  @override
  _SwapScreenState createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _fromCurrency = 'BTC';
  String _toCurrency = 'USDT';
  double _exchangeRate = 43500.0; // Mock exchange rate
  double _estimatedAmount = 0.0;

  List<String> availableCurrencies = ['BTC', 'USDT', 'UGX'];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateEstimate);
    _fetchExchangeRate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swap Assets'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // TODO: Show swap history
            },
          ),
        ],
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletSwapSuccess) {
            _showSuccessDialog();
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // From Currency Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter amount';
                                  }
                                  double? amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Invalid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _fromCurrency,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                items: availableCurrencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency,
                                    child: Text(
                                      currency,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _fromCurrency = value!;
                                    if (_fromCurrency == _toCurrency) {
                                      _toCurrency = availableCurrencies
                                          .firstWhere(
                                            (c) => c != _fromCurrency,
                                          );
                                    }
                                  });
                                  _fetchExchangeRate();
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        BlocBuilder<WalletBloc, WalletState>(
                          builder: (context, state) {
                            if (state is WalletLoaded) {
                              final wallet = state.wallets.firstWhere(
                                (w) => w.currency == _fromCurrency,
                                orElse: () => Wallet(
                                  id: '',
                                  currency: _fromCurrency,
                                  balance: 0,
                                  address: '',
                                  isActive: true,
                                  createdAt: DateTime.now(),
                                ),
                              );
                              return Text(
                                'Available: ${wallet.balance.toStringAsFixed(wallet.currency == 'BTC' ? 8 : 2)} $_fromCurrency',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            }
                            return Text(
                              'Available: --',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // Swap Icon
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.swap_vert, color: Colors.white),
                      onPressed: _swapCurrencies,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // To Currency Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Text(
                                  _estimatedAmount.toStringAsFixed(
                                    _toCurrency == 'BTC' ? 8 : 2,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _toCurrency,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                items: availableCurrencies
                                    .where(
                                      (currency) => currency != _fromCurrency,
                                    )
                                    .map((currency) {
                                      return DropdownMenuItem(
                                        value: currency,
                                        child: Text(
                                          currency,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _toCurrency = value!;
                                  });
                                  _fetchExchangeRate();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Exchange Rate Info
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Exchange Rate:'),
                            Text(
                              '1 $_fromCurrency = ${_getDisplayRate()} $_toCurrency',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Network Fee:'),
                            Text(
                              '~0.0001 $_fromCurrency',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Processing Time:'),
                            Text(
                              '~2-5 minutes',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Swap Button
                BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: (state is WalletLoading) ? null : _performSwap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: (state is WalletLoading)
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Swap $_fromCurrency to $_toCurrency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _fetchExchangeRate();
  }

  void _calculateEstimate() {
    double? amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0) {
      setState(() {
        _estimatedAmount = amount * _exchangeRate;
      });
    } else {
      setState(() {
        _estimatedAmount = 0.0;
      });
    }
  }

  void _fetchExchangeRate() {
    // Mock exchange rate logic
    setState(() {
      if (_fromCurrency == 'BTC' && _toCurrency == 'USDT') {
        _exchangeRate = 43500.0;
      } else if (_fromCurrency == 'USDT' && _toCurrency == 'BTC') {
        _exchangeRate = 0.000023;
      } else if (_fromCurrency == 'BTC' && _toCurrency == 'UGX') {
        _exchangeRate = 160000000.0;
      } else if (_fromCurrency == 'USDT' && _toCurrency == 'UGX') {
        _exchangeRate = 3700.0;
      } else {
        _exchangeRate = 1.0;
      }
    });
    _calculateEstimate();
  }

  String _getDisplayRate() {
    if (_exchangeRate < 0.001) {
      return _exchangeRate.toStringAsFixed(8);
    } else if (_exchangeRate > 1000) {
      return _exchangeRate.toStringAsFixed(0);
    } else {
      return _exchangeRate.toStringAsFixed(2);
    }
  }

  void _performSwap() {
    if (_formKey.currentState!.validate()) {
      double amount = double.parse(_amountController.text);

      context.read<WalletBloc>().add(
        WalletSwapRequested(
          fromCurrency: _fromCurrency,
          toCurrency: _toCurrency,
          amount: amount,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Swap Successful'),
          ],
        ),
        content: Text(
          'Your ${_amountController.text} $_fromCurrency has been swapped to ${_estimatedAmount.toStringAsFixed(_toCurrency == 'BTC' ? 8 : 2)} $_toCurrency',
        ),
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
