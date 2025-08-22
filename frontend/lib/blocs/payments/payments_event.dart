abstract class PaymentsEvent {}

class PaymentSendRequested extends PaymentsEvent {
  final String fromCurrency;
  final double amount;
  final String recipient;
  final String recipientType;
  
  PaymentSendRequested({
    required this.fromCurrency,
    required this.amount,
    required this.recipient,
    required this.recipientType,
  });
}

class PaymentSwapRequested extends PaymentsEvent {
  final String fromCurrency;
  final String toCurrency;
  final double amount;
  
  PaymentSwapRequested({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
  });
}

class TransactionHistoryRequested extends PaymentsEvent {}