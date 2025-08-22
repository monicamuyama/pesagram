import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/bitnob_service.dart';
import '../../models/wallet.dart';
import 'payments_event.dart';
import 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final BitnobService _bitnobService;

  PaymentsBloc(this._bitnobService) : super(PaymentsInitial()) {
    on<PaymentSendRequested>(_onSendRequested);
    on<PaymentSwapRequested>(_onSwapRequested);
    on<TransactionHistoryRequested>(_onHistoryRequested);
  }

  /// Helper method to find wallet ID by currency
  Future<String?> _getWalletIdByCurrency(String currency) async {
    try {
      final List<Wallet> wallets = await _bitnobService.getWallets();
      final wallet = wallets.firstWhere(
        (w) => w.currency.toUpperCase() == currency.toUpperCase() && w.isActive,
        orElse: () => throw Exception('No active wallet found for currency: $currency'),
      );
      return wallet.id;
    } catch (e) {
      print('Error finding wallet for currency $currency: $e');
      return null;
    }
  }

  void _onSendRequested(
    PaymentSendRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(PaymentsLoading());
    try {
      // Get the wallet ID for the specified currency
      final walletId = await _getWalletIdByCurrency(event.fromCurrency);
      if (walletId == null) {
        emit(PaymentsError(message: 'No active wallet found for currency: ${event.fromCurrency}'));
        return;
      }

      final transaction = await _bitnobService.sendTransaction(
        fromWalletId: walletId,
        toAddress: event.recipient,
        amount: event.amount,
        currency: event.fromCurrency,
      );
      emit(PaymentsSuccess(transaction: transaction));
    } catch (e) {
      emit(PaymentsError(message: e.toString()));
    }
  }

  void _onSwapRequested(
    PaymentSwapRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(PaymentsLoading());
    try {
      // Get wallet IDs for both currencies
      final fromWalletId = await _getWalletIdByCurrency(event.fromCurrency);
      final toWalletId = await _getWalletIdByCurrency(event.toCurrency);
      
      if (fromWalletId == null) {
        emit(PaymentsError(message: 'No active wallet found for currency: ${event.fromCurrency}'));
        return;
      }
      
      if (toWalletId == null) {
        emit(PaymentsError(message: 'No active wallet found for currency: ${event.toCurrency}'));
        return;
      }

      final transaction = await _bitnobService.swapCurrency(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
        amount: event.amount,
      );
      emit(PaymentsSuccess(transaction: transaction));
    } catch (e) {
      emit(PaymentsError(message: e.toString()));
    }
  }

  void _onHistoryRequested(
    TransactionHistoryRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(PaymentsLoading());
    try {
      final transactions = await _bitnobService.getTransactions();
      emit(TransactionHistoryLoaded(transactions: transactions));
    } catch (e) {
      emit(PaymentsError(message: e.toString()));
    }
  }
}
