import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/bitnob_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final BitnobService _bitnobService;

  AuthBloc(this._bitnobService) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      'DEBUG: AuthBloc._onLoginRequested called with email: ${event.email}',
    );
    emit(AuthLoading());
    try {
      print('DEBUG: Calling BitnobService.signIn...');
      final user = await _bitnobService.signIn(event.email, event.password);
      print('DEBUG: Login successful, emitting AuthAuthenticated');
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      print('DEBUG: Login failed with error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  void _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      'DEBUG: AuthBloc._onRegisterRequested called with email: ${event.email}',
    );
    emit(AuthLoading());
    try {
      print('DEBUG: Calling BitnobService.signUp...');
      final user = await _bitnobService.signUp(
        event.email,
        event.password,
        event.firstName,
        event.lastName,
      );
      print('DEBUG: Registration successful, emitting AuthAuthenticated');
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      print('DEBUG: Registration failed with error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }
}
