import 'package:flutter/material.dart';

class RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual BLoC data
    final transactions = [
      {
        'type': 'send',
        'recipient': 'John Doe',
        'amount': 50000.0,
        'currency': 'UGX',
        'time': '2 hours ago',
        'status': 'completed',
      },
      {
        'type': 'receive',
        'recipient': 'Sarah Kim',
        'amount': 0.005,
        'currency': 'BTC',
        'time': '5 hours ago',
        'status': 'completed',
      },
      {
        'type': 'swap',
        'recipient': 'BTC → USDT',
        'amount': 25.0,
        'currency': 'USDT',
        'time': '1 day ago',
        'status': 'completed',
      },
    ];

    return Column(
      children: transactions.map((tx) => _buildTransactionItem(context, tx)).toList(),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    IconData icon;
    Color iconColor;
    String prefix;

    switch (transaction['type']) {
      case 'send':
        icon = Icons.arrow_upward;
        iconColor = Colors.red;
        prefix = '-';
        break;
      case 'receive':
        icon = Icons.arrow_downward;
        iconColor = Colors.green;
        prefix = '+';
        break;
      case 'swap':
        icon = Icons.swap_horiz;
        iconColor = Colors.blue;
        prefix = '';
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
        prefix = '';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          transaction['recipient'],
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(transaction['time']),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix${transaction['amount']} ${transaction['currency']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction['type'] == 'send' ? Colors.red : Colors.green,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction['status'],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}