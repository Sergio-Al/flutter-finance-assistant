import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/domain/usecases/auth/auth_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/user/user_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_state.dart';

/// BLoC for handling authentication logic.
///
/// Manages sign in, sign out, registration, password reset,
/// and auth state changes.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmailUseCase signInWithEmail;
  final RegisterWithEmailUseCase registerWithEmail;
  final SignInWithGoogleUseCase signInWithGoogle;
  final SignInWithAppleUseCase signInWithApple;
  final SignOutUseCase signOut;
  final GetCurrentUserIdUseCase getCurrentUserId;
  final IsAuthenticatedUseCase isAuthenticated;
  final WatchAuthStateUseCase watchAuthState;
  final SendPasswordResetEmailUseCase sendPasswordResetEmail;
  final SendEmailVerificationUseCase sendEmailVerification;
  final IsEmailVerifiedUseCase isEmailVerified;
  final IsBiometricAvailableUseCase isBiometricAvailable;
  final AuthenticateWithBiometricsUseCase authenticateWithBiometrics;
  final EnsureUserExistsUseCase ensureUserExists;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.registerWithEmail,
    required this.signInWithGoogle,
    required this.signInWithApple,
    required this.signOut,
    required this.getCurrentUserId,
    required this.isAuthenticated,
    required this.watchAuthState,
    required this.sendPasswordResetEmail,
    required this.sendEmailVerification,
    required this.isEmailVerified,
    required this.isBiometricAvailable,
    required this.authenticateWithBiometrics,
    required this.ensureUserExists,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmail);
    on<AuthRegisterWithEmailRequested>(_onRegisterWithEmail);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AuthSignInWithAppleRequested>(_onSignInWithApple);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthEmailVerificationRequested>(_onEmailVerification);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthBiometricRequested>(_onBiometricAuth);
    on<AuthErrorCleared>(_onErrorCleared);

    // Start listening to auth state changes
    _startAuthStateListener();
  }

  void _startAuthStateListener() {
    _authStateSubscription?.cancel();
    _authStateSubscription = watchAuthState(const NoParams()).listen((result) {
      result.fold(
        (failure) {
          // Handle failure silently or log
        },
        (userId) {
          add(AuthStateChanged(userId: userId));
        },
      );
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    final result = await isAuthenticated(const NoParams());

    await result.fold(
      (failure) async {
        emit(const AuthUnauthenticated());
      },
      (authenticated) async {
        if (authenticated) {
          final userIdResult = await getCurrentUserId(const NoParams());
          await userIdResult.fold(
            (failure) async => emit(const AuthUnauthenticated()),
            (userId) async {
              if (userId != null) {
                // Ensure user exists in local database for FK constraints
                await ensureUserExists(EnsureUserExistsParams(userId: userId));
                emit(AuthAuthenticated(userId: userId));
              } else {
                emit(const AuthUnauthenticated());
              }
            },
          );
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));

    final result = await signInWithEmail(
      SignInWithEmailParams(email: event.email, password: event.password),
    );

    await result.fold(
      (failure) async => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: _mapFailureToErrorType(failure.code),
        ),
      ),
      (userId) async {
        // Ensure user exists in local database for FK constraints
        await ensureUserExists(
          EnsureUserExistsParams(userId: userId, email: event.email),
        );
        emit(AuthAuthenticated(userId: userId, email: event.email));
      },
    );
  }

  Future<void> _onRegisterWithEmail(
    AuthRegisterWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));

    final result = await registerWithEmail(
      RegisterWithEmailParams(
        email: event.email,
        password: event.password,
        confirmPassword: event.password,
        displayName: event.displayName,
      ),
    );

    await result.fold(
      (failure) async => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: _mapFailureToErrorType(failure.code),
        ),
      ),
      (userId) async {
        // Ensure user exists in local database for FK constraints
        await ensureUserExists(
          EnsureUserExistsParams(userId: userId, email: event.email),
        );
        emit(
          AuthRegistrationSuccess(
            userId: userId,
            email: event.email,
            requiresEmailVerification: true,
          ),
        );
      },
    );
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in with Google...'));

    final result = await signInWithGoogle(const NoParams());

    await result.fold(
      (failure) async => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: _mapFailureToErrorType(failure.code),
        ),
      ),
      (userId) async {
        // Ensure user exists in local database for FK constraints
        await ensureUserExists(EnsureUserExistsParams(userId: userId));
        emit(AuthAuthenticated(userId: userId));
      },
    );
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in with Apple...'));

    final result = await signInWithApple(const NoParams());

    await result.fold(
      (failure) async => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: _mapFailureToErrorType(failure.code),
        ),
      ),
      (userId) async {
        // Ensure user exists in local database for FK constraints
        await ensureUserExists(EnsureUserExistsParams(userId: userId));
        emit(AuthAuthenticated(userId: userId));
      },
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing out...'));

    final result = await signOut(const NoParams());

    result.fold(
      (failure) =>
          emit(AuthError(message: failure.message, code: failure.code)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending reset email...'));

    final result = await sendPasswordResetEmail(
      SendPasswordResetEmailParams(email: event.email),
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: _mapFailureToErrorType(failure.code),
        ),
      ),
      (_) => emit(AuthPasswordResetSent(email: event.email)),
    );
  }

  Future<void> _onEmailVerification(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending verification email...'));

    final result = await sendEmailVerification(const NoParams());

    result.fold(
      (failure) =>
          emit(AuthError(message: failure.message, code: failure.code)),
      (_) => emit(const AuthEmailVerificationSent()),
    );
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.userId != null) {
      // Ensure user exists in local database for FK constraints
      await ensureUserExists(EnsureUserExistsParams(userId: event.userId!));
      emit(AuthAuthenticated(userId: event.userId!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onBiometricAuth(
    AuthBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Check if biometric is available
    final availableResult = await isBiometricAvailable(const NoParams());

    final isAvailable = availableResult.fold(
      (failure) => false,
      (available) => available,
    );

    if (!isAvailable) {
      emit(
        const AuthError(
          message: 'Biometric authentication is not available on this device.',
          type: AuthErrorType.biometricNotAvailable,
        ),
      );
      return;
    }

    emit(const AuthLoading(message: 'Authenticating...'));

    final result = await authenticateWithBiometrics(const NoParams());

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          code: failure.code,
          type: AuthErrorType.biometricFailed,
        ),
      ),
      (success) {
        if (success) {
          // Biometric auth successful, check if user is signed in
          add(const AuthCheckRequested());
        } else {
          emit(
            const AuthError(
              message: 'Biometric authentication failed.',
              type: AuthErrorType.biometricFailed,
            ),
          );
        }
      },
    );
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(const AuthUnauthenticated());
  }

  AuthErrorType _mapFailureToErrorType(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthErrorType.invalidCredentials;
      case 'USER_NOT_FOUND':
      case 'user-not-found':
        return AuthErrorType.userNotFound;
      case 'EMAIL_IN_USE':
      case 'email-already-in-use':
        return AuthErrorType.emailAlreadyInUse;
      case 'WEAK_PASSWORD':
      case 'weak-password':
        return AuthErrorType.weakPassword;
      case 'NETWORK_ERROR':
      case 'network-request-failed':
        return AuthErrorType.networkError;
      case 'TOO_MANY_REQUESTS':
      case 'too-many-requests':
        return AuthErrorType.tooManyRequests;
      case 'USER_DISABLED':
      case 'user-disabled':
        return AuthErrorType.userDisabled;
      case 'OPERATION_NOT_ALLOWED':
      case 'operation-not-allowed':
        return AuthErrorType.operationNotAllowed;
      default:
        return AuthErrorType.unknown;
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
