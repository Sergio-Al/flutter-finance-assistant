import 'package:equatable/equatable.dart';

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State while checking authentication status.
class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when user is authenticated.
class AuthAuthenticated extends AuthState {
  final String userId;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;

  const AuthAuthenticated({
    required this.userId,
    this.email,
    this.displayName,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props => [userId, email, displayName, isEmailVerified];
}

/// State when user is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when authentication operation fails.
class AuthError extends AuthState {
  final String message;
  final String? code;
  final AuthErrorType type;

  const AuthError({
    required this.message,
    this.code,
    this.type = AuthErrorType.unknown,
  });

  @override
  List<Object?> get props => [message, code, type];
}

/// State when password reset email was sent.
class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// State when email verification was sent.
class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}

/// State when registration is successful but email needs verification.
class AuthRegistrationSuccess extends AuthState {
  final String userId;
  final String email;
  final bool requiresEmailVerification;

  const AuthRegistrationSuccess({
    required this.userId,
    required this.email,
    this.requiresEmailVerification = true,
  });

  @override
  List<Object?> get props => [userId, email, requiresEmailVerification];
}

/// Types of auth errors for better handling.
enum AuthErrorType {
  invalidCredentials,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  tooManyRequests,
  userDisabled,
  operationNotAllowed,
  biometricNotAvailable,
  biometricFailed,
  unknown,
}

/// Extension for error type messages.
extension AuthErrorTypeExtension on AuthErrorType {
  String get userFriendlyMessage {
    switch (this) {
      case AuthErrorType.invalidCredentials:
        return 'Invalid email or password. Please try again.';
      case AuthErrorType.userNotFound:
        return 'No account found with this email.';
      case AuthErrorType.emailAlreadyInUse:
        return 'An account already exists with this email.';
      case AuthErrorType.weakPassword:
        return 'Password is too weak. Use at least 8 characters.';
      case AuthErrorType.networkError:
        return 'Network error. Please check your connection.';
      case AuthErrorType.tooManyRequests:
        return 'Too many attempts. Please try again later.';
      case AuthErrorType.userDisabled:
        return 'This account has been disabled.';
      case AuthErrorType.operationNotAllowed:
        return 'This sign-in method is not enabled.';
      case AuthErrorType.biometricNotAvailable:
        return 'Biometric authentication is not available.';
      case AuthErrorType.biometricFailed:
        return 'Biometric authentication failed.';
      case AuthErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
