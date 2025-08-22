abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  AuthLoginRequested({required this.email, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String phone;
  final String firstName;
  final String lastName;
  
  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.phone,
    required this.firstName,
    required this.lastName,
  });
}

class AuthLogoutRequested extends AuthEvent {}