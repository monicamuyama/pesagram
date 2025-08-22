import '../../models/wallet.dart';

abstract class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final List<Wallet> wallets;
  final double totalUgxBalance;

  WalletLoaded({required this.wallets, required this.totalUgxBalance});
}

class WalletSwapSuccess extends WalletState {}

class WalletError extends WalletState {
  final String message;

  WalletError({required this.message});
}
