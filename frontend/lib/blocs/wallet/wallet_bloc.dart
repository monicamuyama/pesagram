import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/bitnob_service.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final BitnobService _bitnobService;

  WalletBloc(this._bitnobService) : super(WalletInitial()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletCreateRequested>(_onCreateRequested);
    on<WalletSwapRequested>(_onSwapRequested);
  }

  void _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final wallets = await _bitnobService.getWallets();
      final totalUgx = wallets.fold<double>(
        0,
        (sum, wallet) => sum + wallet.ugxEquivalent,
      );
      emit(WalletLoaded(wallets: wallets, totalUgxBalance: totalUgx));
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  void _onCreateRequested(
    WalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _bitnobService.createWallet(event.currency);
      add(WalletLoadRequested()); // Reload wallets
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }

  void _onSwapRequested(
    WalletSwapRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      // For now, we'll need to implement a simplified swap that doesn't require specific wallet IDs
      // In a real implementation, you'd need to modify the event to include wallet IDs
      // or implement logic to find the appropriate wallets by currency

      // This is a placeholder - you'll need to implement proper wallet selection logic
      await _bitnobService.swapCurrency(
        fromWalletId:
            'placeholder_from_wallet', // Should be determined from available wallets
        toWalletId:
            'placeholder_to_wallet', // Should be determined from available wallets
        fromCurrency: event.fromCurrency,
        toCurrency: event.toCurrency,
        amount: event.amount,
      );
      emit(WalletSwapSuccess());
      add(WalletLoadRequested()); // Reload wallets after swap
    } catch (e) {
      emit(WalletError(message: e.toString()));
    }
  }
}
