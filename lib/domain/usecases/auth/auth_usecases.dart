/// Barrel export for all authentication-related use cases.
///
/// Import this file to access all auth use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/auth/auth_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### Email/Password Authentication
/// - [SignInWithEmailUseCase] - Sign in with email and password
/// - [RegisterWithEmailUseCase] - Register new account with email
///
/// ### Social Authentication
/// - [SignInWithGoogleUseCase] - Sign in with Google
/// - [SignInWithAppleUseCase] - Sign in with Apple
///
/// ### Auth State
/// - [SignOutUseCase] - Sign out current user
/// - [GetCurrentUserIdUseCase] - Get current user ID
/// - [IsAuthenticatedUseCase] - Check if authenticated
/// - [WatchAuthStateUseCase] - Stream auth state changes
///
/// ### Password Management
/// - [SendPasswordResetEmailUseCase] - Send password reset email
/// - [UpdatePasswordUseCase] - Update password
/// - [ConfirmPasswordResetUseCase] - Confirm reset with code
///
/// ### Account Management
/// - [SendEmailVerificationUseCase] - Send verification email
/// - [IsEmailVerifiedUseCase] - Check if email is verified
/// - [UpdateEmailUseCase] - Update email address
/// - [DeleteAccountUseCase] - Delete user account
/// - [ReauthenticateUseCase] - Re-authenticate for sensitive ops
///
/// ### Biometric Authentication
/// - [IsBiometricAvailableUseCase] - Check biometric availability
/// - [AuthenticateWithBiometricsUseCase] - Authenticate with biometrics
/// - [GetAvailableBiometricsUseCase] - Get available biometric types
library;

export 'account_management.dart';
export 'auth_state.dart';
export 'biometric_auth.dart';
export 'password_management.dart';
export 'register_with_email.dart';
export 'sign_in_with_email.dart';
export 'sign_in_with_social.dart';
