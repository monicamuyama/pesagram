import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/payments/payments_bloc.dart';
import '../../blocs/payments/payments_event.dart';
import '../../blocs/payments/payments_state.dart';

class SendMoneyScreen extends StatefulWidget {
  @override
  _SendMoneyScreenState createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();

  String _selectedCurrency = 'BTC';
  String _selectedRecipientType = 'phone';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Money')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          labelText: 'Select Currency',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: ['BTC', 'USDT', 'UGX'].map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('$currency Wallet'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.money),
                          suffixText: _selectedCurrency,
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true)
                            return 'Amount is required';
                          if (double.tryParse(value!) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
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
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRecipientType,
                        decoration: InputDecoration(
                          labelText: 'Send To',
                          prefixIcon: Icon(Icons.send),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'phone',
                            child: Text('Mobile Money'),
                          ),
                          DropdownMenuItem(
                            value: 'bank',
                            child: Text('Bank Account'),
                          ),
                          DropdownMenuItem(
                            value: 'address',
                            child: Text('Crypto Address'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipientType = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _recipientController,
                        decoration: InputDecoration(
                          labelText: _getRecipientLabel(),
                          prefixIcon: Icon(_getRecipientIcon()),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true)
                            return 'Recipient is required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              BlocConsumer<PaymentsBloc, PaymentsState>(
                listener: (context, state) {
                  if (state is PaymentsSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment sent successfully!')),
                    );
                    Navigator.pop(context);
                  } else if (state is PaymentsError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is PaymentsLoading ? null : _sendMoney,
                    child: state is PaymentsLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Send Money'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecipientLabel() {
    switch (_selectedRecipientType) {
      case 'phone':
        return 'Phone Number';
      case 'bank':
        return 'Account Number';
      case 'address':
        return 'Wallet Address';
      default:
        return 'Recipient';
    }
  }

  IconData _getRecipientIcon() {
    switch (_selectedRecipientType) {
      case 'phone':
        return Icons.phone;
      case 'bank':
        return Icons.account_balance;
      case 'address':
        return Icons.account_balance_wallet;
      default:
        return Icons.person;
    }
  }

  void _sendMoney() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PaymentsBloc>().add(
        PaymentSendRequested(
          fromCurrency: _selectedCurrency,
          amount: double.parse(_amountController.text),
          recipient: _recipientController.text,
          recipientType: _selectedRecipientType,
        ),
      );
    }
  }
}
