import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';

/// Mock implementation of AuthRepository for UI testing.
///
/// Replace this with your real implementation (Firebase, etc.)
/// when you're ready to connect to a backend.
class MockAuthRepository implements AuthRepository {
  String? _currentUserId;

  @override
  Future<Either<Failure, String>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation - use test@test.com / password123 to login
    if (email == 'test@test.com' && password == 'password123') {
      _currentUserId = 'mock-user-123';
      return const Right('mock-user-123');
    }

    return const Left(
      InvalidCredentialsFailure(),
    );
  }

  @override
  Future<Either<Failure, String>> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUserId = 'mock-user-${DateTime.now().millisecondsSinceEpoch}';
    return Right(_currentUserId!);
  }

  @override
  Future<Either<Failure, String>> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUserId = 'mock-google-user';
    return const Right('mock-google-user');
  }

  @override
  Future<Either<Failure, String>> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUserId = 'mock-apple-user';
    return const Right('mock-apple-user');
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUserId = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, String?>> getCurrentUserId() async {
    return Right(_currentUserId);
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    return Right(_currentUserId != null);
  }

  @override
  Stream<Either<Failure, String?>> watchAuthState() {
    return Stream.value(Right(_currentUserId));
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> reloadUser() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUserId = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reauthenticate({
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isBiometricAvailable() async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, bool>> authenticateWithBiometrics() async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, List<BiometricType>>> getAvailableBiometrics() async {
    return const Right([]);
  }
}
