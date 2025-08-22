import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:firebase_core/firebase_core.dart'; // Temporarily commented out
import 'blocs/auth/auth_bloc.dart';
import 'blocs/wallet/wallet_bloc.dart';
import 'blocs/payments/payments_bloc.dart';
import 'services/bitnob_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add error handling for the entire app
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  print('DEBUG: App starting...');
  print('DEBUG: API Base URL: ${ApiConfig.baseUrl}');
  print('DEBUG: Running on mobile: ${ApiConfig.isMobile}');

  // Temporarily disable Firebase to test if it's causing the issue
  /*
  try {
    await Firebase.initializeApp();
    print('DEBUG: Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase for now
  }
  */

  print('DEBUG: About to run app...');
  
  try {
    runApp(MyApp());
  } catch (e) {
    print('ERROR: Failed to run app: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building MyApp widget...');
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => AuthBloc(BitnobService())),
        BlocProvider<WalletBloc>(
          create: (context) => WalletBloc(BitnobService()),
        ),
        BlocProvider<PaymentsBloc>(
          create: (context) => PaymentsBloc(BitnobService()),
        ),
      ],
      child: MaterialApp(
        title: 'Bitnob Remittance',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.debug,  // Temporarily start with debug screen
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
