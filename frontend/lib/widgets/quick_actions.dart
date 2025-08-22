import 'package:flutter/material.dart';
import '../utils/app_routes.dart';

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context,
              icon: Icons.send,
              label: 'Send',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, AppRoutes.sendMoney),
            ),
            _buildActionButton(
              context,
              icon: Icons.qr_code_scanner,
              label: 'Receive',
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, AppRoutes.receiveMoney),
            ),
            _buildActionButton(
              context,
              icon: Icons.swap_horiz,
              label: 'Swap',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, AppRoutes.swap),
            ),
            _buildActionButton(
              context,
              icon: Icons.more_horiz,
              label: 'More',
              color: Colors.purple,
              onTap: () => _showMoreOptions(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildMoreOption(
              context,
              icon: Icons.flash_on,
              title: 'Lightning Network',
              subtitle: 'Fast Bitcoin payments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.lightning);
              },
            ),
            _buildMoreOption(
              context,
              icon: Icons.phone_android,
              title: 'Mobile Money',
              subtitle: 'Send to MTN, Airtel, M-Pesa',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.mobileMoney);
              },
            ),
            _buildMoreOption(
              context,
              icon: Icons.repeat,
              title: 'Recurring Payments',
              subtitle: 'Set up automatic payments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.recurringPayments);
              },
            ),
            _buildMoreOption(
              context,
              icon: Icons.verified_user,
              title: 'KYC Verification',
              subtitle: 'Verify your identity',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.kyc);
              },
            ),
            _buildMoreOption(
              context,
              icon: Icons.security,
              title: '2FA Security',
              subtitle: 'Two-factor authentication',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.twoFactorAuth);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.blue,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
