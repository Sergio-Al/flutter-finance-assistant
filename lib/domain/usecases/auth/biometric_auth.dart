import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for checking if biometric authentication is available.
///
/// ## Example Usage
/// ```dart
/// final useCase = IsBiometricAvailableUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => handleError(failure),
///   (isAvailable) {
///     if (isAvailable) {
///       showBiometricOption();
///     }
///   },
/// );
/// ```
class IsBiometricAvailableUseCase extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsBiometricAvailableUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.isBiometricAvailable();
  }
}

/// Use case for authenticating with biometrics (fingerprint, Face ID).
///
/// ## Example Usage
/// ```dart
/// final useCase = AuthenticateWithBiometricsUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (success) {
///     if (success) {
///       unlockApp();
///     } else {
///       showRetryPrompt();
///     }
///   },
/// );
/// ```
class AuthenticateWithBiometricsUseCase extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  AuthenticateWithBiometricsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.authenticateWithBiometrics();
  }
}

/// Use case for getting available biometric types.
///
/// Returns a list of available biometric options (fingerprint, Face ID, etc.)
///
/// ## Example Usage
/// ```dart
/// final useCase = GetAvailableBiometricsUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => handleError(failure),
///   (biometrics) {
///     for (final type in biometrics) {
///       print('Available: ${type.displayName}');
///     }
///   },
/// );
/// ```
class GetAvailableBiometricsUseCase
    extends UseCase<List<BiometricType>, NoParams> {
  final AuthRepository repository;

  GetAvailableBiometricsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BiometricType>>> call(NoParams params) {
    return repository.getAvailableBiometrics();
  }
}
