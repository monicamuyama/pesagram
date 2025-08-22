import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../blocs/wallet/wallet_state.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/recent_transactions.dart';
import '../wallet/wallet_screen.dart';
import '../../services/bitnob_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _kycStatus;
  String? _kycRejectionReason;
  bool _showKycBanner = true;
  final BitnobService _service = BitnobService();

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(WalletLoadRequested());
    _fetchKycStatus();
  }

  Future<void> _fetchKycStatus() async {
    final result = await _service.getKycStatus();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _kycStatus = result['data']['kycStatus'];
          _kycRejectionReason = result['data']['kycRejectionReason'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outlined),
            onPressed: () {
              // Handle profile
            },
          ),
          IconButton(
            icon: Icon(Icons.verified_user_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/kyc');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildHomeTab(), _buildWalletTab(), _buildTransactionsTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WalletBloc>().add(WalletLoadRequested());
        await _fetchKycStatus();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showKycBanner && _kycStatus != 'approved')
              Dismissible(
                key: ValueKey('kyc-banner'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => setState(() => _showKycBanner = false),
                child: Card(
                  color: _kycStatus == 'rejected' ? Colors.red[100] : Colors.yellow[100],
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(Icons.verified_user_outlined, color: Colors.orange),
                    title: Text(_kycStatus == 'rejected'
                        ? 'KYC Rejected'
                        : (_kycStatus == 'in_review' ? 'KYC In Review' : 'Complete Your KYC')),
                    subtitle: _kycStatus == 'rejected' && _kycRejectionReason != null
                        ? Text('Reason: $_kycRejectionReason', style: TextStyle(color: Colors.red))
                        : (_kycStatus == 'pending' ? Text('You need to complete KYC to unlock all features.') : null),
                    trailing: TextButton(
                      child: Text('KYC'),
                      onPressed: () {
                        Navigator.pushNamed(context, '/kyc');
                      },
                    ),
                  ),
                ),
              ),
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                if (state is WalletLoaded) {
                  return BalanceCard(totalBalance: state.totalUgxBalance);
                } else if (state is WalletLoading) {
                  return Card(
                    child: Container(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                return BalanceCard(totalBalance: 0);
              },
            ),
            SizedBox(height: 24),
            QuickActions(),
            SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            RecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletTab() {
    return WalletScreen();
  }

  Widget _buildTransactionsTab() {
    return Center(child: Text('Transaction History'));
  }
}
