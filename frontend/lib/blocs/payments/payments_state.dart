import '../../models/transaction.dart';

abstract class PaymentsState {}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsSuccess extends PaymentsState {
  final Transaction transaction;

  PaymentsSuccess({required this.transaction});
}

class TransactionHistoryLoaded extends PaymentsState {
  final List<Transaction> transactions;

  TransactionHistoryLoaded({required this.transactions});
}

class PaymentsError extends PaymentsState {
  final String message;

  PaymentsError({required this.message});
}
