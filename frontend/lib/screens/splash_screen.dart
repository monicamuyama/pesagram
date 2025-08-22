import 'package:flutter/material.dart';
import '../utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('DEBUG: Splash screen initialized'); // Debug print
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    print('DEBUG: Navigation function called');
    await Future.delayed(Duration(seconds: 3));
    print('DEBUG: Delay completed, checking mounted state: $mounted');
    if (mounted) {
      print('DEBUG: Attempting navigation to login');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      print('DEBUG: Widget not mounted, skipping navigation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Bitnob Remittance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Send money across borders',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
