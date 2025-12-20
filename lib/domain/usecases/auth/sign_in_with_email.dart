import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for signing in with email and password.
///
/// Returns the user ID on successful authentication.
///
/// ## Example Usage
/// ```dart
/// final useCase = SignInWithEmailUseCase(authRepository);
///
/// final result = await useCase(
///   SignInWithEmailParams(
///     email: 'user@example.com',
///     password: 'securePassword123',
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (userId) => navigateToDashboard(userId),
/// );
/// ```
class SignInWithEmailUseCase extends UseCase<String, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(SignInWithEmailParams params) async {
    // Validate email
    if (params.email.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email is required', code: 'MISSING_EMAIL'),
      );
    }

    if (!_isValidEmail(params.email)) {
      return const Left(
        ValidationFailure(
          message: 'Please enter a valid email address',
          code: 'INVALID_EMAIL',
        ),
      );
    }

    // Validate password
    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Password is required',
          code: 'MISSING_PASSWORD',
        ),
      );
    }

    return repository.signInWithEmailPassword(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parameters for [SignInWithEmailUseCase].
class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
