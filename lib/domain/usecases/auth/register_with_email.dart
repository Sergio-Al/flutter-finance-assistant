import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for registering a new user with email and password.
///
/// Returns the new user ID on successful registration.
///
/// ## Example Usage
/// ```dart
/// final useCase = RegisterWithEmailUseCase(authRepository);
///
/// final result = await useCase(
///   RegisterWithEmailParams(
///     email: 'newuser@example.com',
///     password: 'securePassword123',
///     confirmPassword: 'securePassword123',
///     displayName: 'John Doe',
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (userId) => navigateToVerification(userId),
/// );
/// ```
class RegisterWithEmailUseCase
    extends UseCase<String, RegisterWithEmailParams> {
  final AuthRepository repository;

  RegisterWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RegisterWithEmailParams params) async {
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

    if (params.password.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Password must be at least 8 characters',
          code: 'PASSWORD_TOO_SHORT',
        ),
      );
    }

    if (!_isStrongPassword(params.password)) {
      return const Left(
        ValidationFailure(
          message:
              'Password must contain at least one uppercase letter, one lowercase letter, and one number',
          code: 'WEAK_PASSWORD',
        ),
      );
    }

    // Validate password confirmation
    if (params.password != params.confirmPassword) {
      return const Left(
        ValidationFailure(
          message: 'Passwords do not match',
          code: 'PASSWORD_MISMATCH',
        ),
      );
    }

    return repository.registerWithEmailPassword(
      email: params.email.trim().toLowerCase(),
      password: params.password,
      displayName: params.displayName?.trim(),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    // At least one uppercase, one lowercase, one digit
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password);
  }
}

/// Parameters for [RegisterWithEmailUseCase].
class RegisterWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String confirmPassword;
  final String? displayName;

  const RegisterWithEmailParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword, displayName];
}
