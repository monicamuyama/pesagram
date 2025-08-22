import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/two_factor_auth_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/payments/send_money_screen.dart';
import '../screens/payments/receive_money_screen.dart';
import '../screens/payments/mobile_money_screen.dart';
import '../screens/payments/recurring_payments_screen.dart';
import '../screens/swap/swap_screen.dart';
import '../screens/kyc/kyc_screen.dart';
import '../screens/lightning/lightning_screen.dart';
import '../screens/debug/debug_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String debug = '/debug';  // Add debug route
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String wallet = '/wallet';
  static const String sendMoney = '/send-money';
  static const String receiveMoney = '/receive-money';
  static const String mobileMoney = '/mobile-money';
  static const String recurringPayments = '/recurring-payments';
  static const String swap = '/swap';
  static const String kyc = '/kyc';
  static const String lightning = '/lightning';
  static const String twoFactorAuth = '/two-factor-auth';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    debug: (context) => DebugScreen(),  // Add debug screen
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    dashboard: (context) => DashboardScreen(),
    wallet: (context) => WalletScreen(),
    sendMoney: (context) => SendMoneyScreen(),
    receiveMoney: (context) => ReceiveMoneyScreen(),
    mobileMoney: (context) => MobileMoneyScreen(),
    recurringPayments: (context) => RecurringPaymentsScreen(),
    swap: (context) => SwapScreen(),
    kyc: (context) => KycScreen(),
    lightning: (context) => LightningScreen(),
    twoFactorAuth: (context) => TwoFactorAuthScreen(),
  };
}
