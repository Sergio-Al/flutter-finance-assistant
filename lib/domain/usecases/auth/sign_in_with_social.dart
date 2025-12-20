import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for signing in with Google.
///
/// Returns the user ID on successful authentication.
///
/// ## Example Usage
/// ```dart
/// final useCase = SignInWithGoogleUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (userId) => navigateToDashboard(userId),
/// );
/// ```
class SignInWithGoogleUseCase extends UseCase<String, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}

/// Use case for signing in with Apple.
///
/// Returns the user ID on successful authentication.
///
/// ## Example Usage
/// ```dart
/// final useCase = SignInWithAppleUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (userId) => navigateToDashboard(userId),
/// );
/// ```
class SignInWithAppleUseCase extends UseCase<String, NoParams> {
  final AuthRepository repository;

  SignInWithAppleUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return repository.signInWithApple();
  }
}
