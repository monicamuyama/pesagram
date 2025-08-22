abstract class WalletEvent {}

class WalletLoadRequested extends WalletEvent {}

class WalletCreateRequested extends WalletEvent {
  final String currency;

  WalletCreateRequested({required this.currency});
}

class WalletSwapRequested extends WalletEvent {
  final String fromCurrency;
  final String toCurrency;
  final double amount;

  WalletSwapRequested({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
  });
}
