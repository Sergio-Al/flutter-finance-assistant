import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check initial auth state.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to sign in with email and password.
class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to register with email and password.
class AuthRegisterWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthRegisterWithEmailRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Event to sign in with Google.
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Event to sign in with Apple.
class AuthSignInWithAppleRequested extends AuthEvent {
  const AuthSignInWithAppleRequested();
}

/// Event to sign out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to send password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to send email verification.
class AuthEmailVerificationRequested extends AuthEvent {
  const AuthEmailVerificationRequested();
}

/// Event when auth state changes (from stream).
class AuthStateChanged extends AuthEvent {
  final String? userId;

  const AuthStateChanged({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to authenticate with biometrics.
class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}

/// Event to clear any error state.
class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
