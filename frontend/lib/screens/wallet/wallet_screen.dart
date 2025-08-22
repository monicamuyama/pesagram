import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../models/wallet.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallets'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddWalletDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is WalletLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(WalletLoadRequested());
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: state.wallets.length,
                itemBuilder: (context, index) {
                  final wallet = state.wallets[index];
                  return _buildWalletCard(wallet);
                },
              ),
            );
          } else if (state is WalletError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WalletBloc>().add(WalletLoadRequested());
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('No wallets found'));
        },
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    IconData icon;
    Color color;

    switch (wallet.currency) {
      case 'BTC':
        icon = Icons.currency_bitcoin;
        color = Colors.orange;
        break;
      case 'USDT':
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case 'UGX':
        icon = Icons.money;
        color = Colors.blue;
        break;
      default:
        icon = Icons.account_balance_wallet;
        color = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${wallet.currency} Wallet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Balance',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${wallet.balance.toStringAsFixed(wallet.currency == 'BTC' ? 8 : 2)} ${wallet.currency}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'UGX ${wallet.ugxEquivalent.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Address: ${wallet.address}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/send-money',
                        arguments: wallet,
                      );
                    },
                    icon: Icon(Icons.send),
                    label: Text('Send'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/receive-money',
                        arguments: wallet,
                      );
                    },
                    icon: Icon(Icons.qr_code),
                    label: Text('Receive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/swap', arguments: wallet);
                    },
                    icon: Icon(Icons.swap_horiz),
                    label: Text('Swap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedCurrency = 'BTC';
        return AlertDialog(
          title: Text('Add New Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select currency for your new wallet:'),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: ['BTC', 'USDT', 'UGX'].map((String currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedCurrency = newValue;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<WalletBloc>().add(
                  WalletCreateRequested(currency: selectedCurrency),
                );
                Navigator.of(context).pop();
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
