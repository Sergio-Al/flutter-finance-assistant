import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Firebase Auth and local_auth.
///
/// Handles all authentication operations including email/password,
/// social sign-in, biometrics, and account management.
class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _auth;
  final local_auth.LocalAuthentication _localAuth;
  final GoogleSignIn _googleSignIn;

  /// Creates [AuthRepositoryImpl] with required dependencies.
  AuthRepositoryImpl({
    fb_auth.FirebaseAuth? auth,
    local_auth.LocalAuthentication? localAuth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? fb_auth.FirebaseAuth.instance,
       _localAuth = localAuth ?? local_auth.LocalAuthentication(),
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  // ═══════════════════════════════════════════════════════════════════════════
  // Authentication State
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, String?>> getCurrentUserId() async {
    try {
      return Right(_auth.currentUser?.uid);
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to get current user: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      return Right(_auth.currentUser != null);
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to check authentication status: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, String?>> watchAuthState() {
    return _auth.authStateChanges().map((user) {
      try {
        return Right<Failure, String?>(user?.uid);
      } catch (e) {
        return Left<Failure, String?>(
          AuthenticationFailure(
            message: 'Error watching auth state: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Email/Password Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, String>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = credential.user?.uid;
      if (userId == null) {
        return Left(
          AuthenticationFailure(
            message: 'Sign in succeeded but user ID is null',
          ),
        );
      }

      return Right(userId);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(message: 'Sign in failed: $e', originalError: e),
      );
    }
  }

  @override
  Future<Either<Failure, String>> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return Left(
          AuthenticationFailure(
            message: 'Registration succeeded but user is null',
          ),
        );
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Send email verification
      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      return Right(user.uid);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Registration failed: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(message: 'Sign out failed: $e', originalError: e),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Social Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, String>> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return Left(
          AuthenticationFailure(
            message: 'Google sign-in was cancelled',
            code: 'SIGN_IN_CANCELLED',
          ),
        );
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      final userId = userCredential.user?.uid;
      if (userId == null) {
        return Left(
          AuthenticationFailure(
            message: 'Google sign-in succeeded but user ID is null',
          ),
        );
      }

      return Right(userId);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Google sign-in failed: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> signInWithApple() async {
    try {
      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = fb_auth.OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in to Firebase with Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      if (user == null) {
        return Left(
          AuthenticationFailure(
            message: 'Apple sign-in succeeded but user is null',
          ),
        );
      }

      // Update display name if provided by Apple (only on first sign-in)
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final displayName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].where((name) => name != null && name.isNotEmpty).join(' ');

        if (displayName.isNotEmpty && user.displayName == null) {
          await user.updateDisplayName(displayName);
        }
      }

      return Right(user.uid);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return Left(
          AuthenticationFailure(
            message: 'Apple sign-in was cancelled',
            code: 'SIGN_IN_CANCELLED',
          ),
        );
      }
      return Left(
        AuthenticationFailure(
          message: 'Apple sign-in failed: ${e.message}',
          code: e.code.toString(),
          originalError: e,
        ),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Apple sign-in failed: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns SHA256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Password Management
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to send password reset email: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      // Re-authenticate first
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to update password: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to confirm password reset: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Email Verification
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      await user.sendEmailVerification();
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to send email verification: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      return Right(user.emailVerified);
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to check email verification status: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      await user.reload();
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to reload user: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Account Management
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, void>> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      // Re-authenticate first
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email (sends verification to new email)
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to update email: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      // Re-authenticate first
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete account
      await user.delete();
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Failed to delete account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticate({
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return Left(
          AuthenticationFailure(message: 'No authenticated user found'),
        );
      }

      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(
        AuthenticationFailure(
          message: 'Re-authentication failed: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Biometric Authentication
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return Right(canAuthenticate && isDeviceSupported);
    } catch (e) {
      return Left(
        BiometricFailure(
          message: 'Failed to check biometric availability: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();

      return isAvailable.fold((failure) => Left(failure), (available) async {
        if (!available) {
          return Left(
            BiometricFailure(
              message:
                  'Biometric authentication is not available on this device',
            ),
          );
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access your finance data',
          options: const local_auth.AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        return Right(authenticated);
      });
    } catch (e) {
      return Left(
        BiometricFailure(
          message: 'Biometric authentication failed: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<BiometricType>>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      final biometricTypes = availableBiometrics.map((biometric) {
        switch (biometric) {
          case local_auth.BiometricType.fingerprint:
            return BiometricType.fingerprint;
          case local_auth.BiometricType.face:
            return BiometricType.faceId;
          case local_auth.BiometricType.iris:
            return BiometricType.iris;
          case local_auth.BiometricType.strong:
          case local_auth.BiometricType.weak:
            // Default to fingerprint for generic strong/weak biometrics
            return BiometricType.fingerprint;
        }
      }).toList();

      return Right(biometricTypes);
    } catch (e) {
      return Left(
        BiometricFailure(
          message: 'Failed to get available biometrics: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Error Mapping
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maps Firebase Auth exceptions to application failures.
  Failure _mapFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      // Sign In Errors
      case 'user-not-found':
        return InvalidCredentialsFailure(
          message: 'No account found with this email address.',
          originalError: e,
        );
      case 'wrong-password':
        return InvalidCredentialsFailure(
          message: 'Incorrect password. Please try again.',
          originalError: e,
        );
      case 'invalid-credential':
        return InvalidCredentialsFailure(
          message: 'Invalid email or password.',
          originalError: e,
        );
      case 'invalid-email':
        return ValidationFailure(
          message: 'Please enter a valid email address.',
          originalError: e,
        );

      // Registration Errors
      case 'email-already-in-use':
        return EmailAlreadyInUseFailure(
          message: 'An account with this email already exists.',
          originalError: e,
        );
      case 'weak-password':
        return WeakPasswordFailure(
          message: 'Password is too weak. Please use at least 6 characters.',
          originalError: e,
        );

      // Account Status Errors
      case 'user-disabled':
        return AccountDisabledFailure(
          message: 'This account has been disabled. Please contact support.',
          originalError: e,
        );
      case 'too-many-requests':
        return TooManyRequestsFailure(
          message: 'Too many failed attempts. Please try again later.',
          originalError: e,
        );

      // Network Errors
      case 'network-request-failed':
        return NetworkFailure(
          message: 'Network error. Please check your internet connection.',
          originalError: e,
        );

      // Operation Errors
      case 'operation-not-allowed':
        return AuthenticationFailure(
          message: 'This sign-in method is not enabled.',
          code: e.code,
          originalError: e,
        );
      case 'requires-recent-login':
        return AuthenticationFailure(
          message: 'Please sign in again to complete this action.',
          code: e.code,
          originalError: e,
        );

      // Token/Session Errors
      case 'expired-action-code':
        return AuthenticationFailure(
          message: 'This link has expired. Please request a new one.',
          code: e.code,
          originalError: e,
        );
      case 'invalid-action-code':
        return AuthenticationFailure(
          message: 'This link is invalid. Please request a new one.',
          code: e.code,
          originalError: e,
        );

      // Default
      default:
        return AuthenticationFailure(
          message: e.message ?? 'Authentication error occurred.',
          code: e.code,
          originalError: e,
        );
    }
  }
}
