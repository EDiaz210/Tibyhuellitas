import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;
  final String? accountType;

  const SignUpRequested({
    required this.email,
    required this.password,
    this.displayName,
    this.accountType,
  });

  @override
  List<Object?> get props => [email, password, displayName, accountType];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
