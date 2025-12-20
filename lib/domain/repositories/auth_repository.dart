import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';

/// Repository interface for authentication operations.
///
/// Defines the contract for Firebase Auth operations.
/// Implementation will be in the data layer.
abstract class AuthRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // Authentication State
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current authenticated user ID.
  Future<Either<Failure, String?>> getCurrentUserId();

  /// Check if user is authenticated.
  Future<Either<Failure, bool>> isAuthenticated();

  /// Stream of authentication state changes.
  Stream<Either<Failure, String?>> watchAuthState();

  // ═══════════════════════════════════════════════════════════════════════════
  // Email/Password Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sign in with email and password.
  Future<Either<Failure, String>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Register with email and password.
  Future<Either<Failure, String>> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out current user.
  Future<Either<Failure, void>> signOut();

  // ═══════════════════════════════════════════════════════════════════════════
  // Social Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sign in with Google.
  Future<Either<Failure, String>> signInWithGoogle();

  /// Sign in with Apple.
  Future<Either<Failure, String>> signInWithApple();

  // ═══════════════════════════════════════════════════════════════════════════
  // Password Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send password reset email.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Update password for authenticated user.
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Confirm password reset with code.
  Future<Either<Failure, void>> confirmPasswordReset({
    required String code,
    required String newPassword,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Email Verification
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send email verification.
  Future<Either<Failure, void>> sendEmailVerification();

  /// Check if email is verified.
  Future<Either<Failure, bool>> isEmailVerified();

  /// Reload user to check verification status.
  Future<Either<Failure, void>> reloadUser();

  // ═══════════════════════════════════════════════════════════════════════════
  // Account Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update user email.
  Future<Either<Failure, void>> updateEmail({
    required String newEmail,
    required String password,
  });

  /// Delete user account.
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  });

  /// Re-authenticate user (required for sensitive operations).
  Future<Either<Failure, void>> reauthenticate({
    required String password,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Biometric Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if biometric authentication is available.
  Future<Either<Failure, bool>> isBiometricAvailable();

  /// Authenticate with biometrics.
  Future<Either<Failure, bool>> authenticateWithBiometrics();

  /// Get available biometric types.
  Future<Either<Failure, List<BiometricType>>> getAvailableBiometrics();
}

/// Types of biometric authentication.
enum BiometricType {
  fingerprint,
  faceId,
  iris,
}

/// Extension for BiometricType utilities.
extension BiometricTypeExtension on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.faceId:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
    }
  }

  String get icon {
    switch (this) {
      case BiometricType.fingerprint:
        return 'fingerprint';
      case BiometricType.faceId:
        return 'face';
      case BiometricType.iris:
        return 'remove_red_eye';
    }
  }
}
