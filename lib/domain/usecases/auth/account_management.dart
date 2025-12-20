import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for sending email verification.
///
/// ## Example Usage
/// ```dart
/// final useCase = SendEmailVerificationUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (_) => showSuccess('Verification email sent'),
/// );
/// ```
class SendEmailVerificationUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;

  SendEmailVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.sendEmailVerification();
  }
}

/// Use case for checking if email is verified.
///
/// ## Example Usage
/// ```dart
/// final useCase = IsEmailVerifiedUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => handleError(failure),
///   (isVerified) {
///     if (isVerified) {
///       navigateToDashboard();
///     } else {
///       showVerificationPrompt();
///     }
///   },
/// );
/// ```
class IsEmailVerifiedUseCase extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsEmailVerifiedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.isEmailVerified();
  }
}

/// Use case for updating user email.
///
/// Requires password for security verification.
class UpdateEmailUseCase extends UseCase<void, UpdateEmailParams> {
  final AuthRepository repository;

  UpdateEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateEmailParams params) async {
    if (params.newEmail.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'New email is required',
          code: 'MISSING_EMAIL',
        ),
      );
    }

    if (!_isValidEmail(params.newEmail)) {
      return const Left(
        ValidationFailure(
          message: 'Please enter a valid email address',
          code: 'INVALID_EMAIL',
        ),
      );
    }

    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Password is required for verification',
          code: 'MISSING_PASSWORD',
        ),
      );
    }

    return repository.updateEmail(
      newEmail: params.newEmail.trim().toLowerCase(),
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parameters for [UpdateEmailUseCase].
class UpdateEmailParams extends Equatable {
  final String newEmail;
  final String password;

  const UpdateEmailParams({required this.newEmail, required this.password});

  @override
  List<Object?> get props => [newEmail, password];
}

/// Use case for deleting user account.
///
/// ⚠️ WARNING: This permanently deletes the account and all associated data.
/// Requires password confirmation for security.
class DeleteAuthAccountUseCase extends UseCase<void, DeleteAuthAccountParams> {
  final AuthRepository repository;

  DeleteAuthAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAuthAccountParams params) async {
    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Password is required for account deletion',
          code: 'MISSING_PASSWORD',
        ),
      );
    }

    if (!params.confirmDeletion) {
      return const Left(
        ValidationFailure(
          message: 'Account deletion must be confirmed',
          code: 'DELETION_NOT_CONFIRMED',
        ),
      );
    }

    return repository.deleteAccount(password: params.password);
  }
}

/// Parameters for [DeleteAccountUseCase].
class DeleteAuthAccountParams extends Equatable {
  final String password;
  final bool confirmDeletion;

  const DeleteAuthAccountParams({
    required this.password,
    this.confirmDeletion = false,
  });

  @override
  List<Object?> get props => [password, confirmDeletion];
}

/// Use case for re-authenticating the user.
///
/// Required before sensitive operations like email/password change.
class ReauthenticateUseCase extends UseCase<void, ReauthenticateParams> {
  final AuthRepository repository;

  ReauthenticateUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ReauthenticateParams params) async {
    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Password is required',
          code: 'MISSING_PASSWORD',
        ),
      );
    }

    return repository.reauthenticate(password: params.password);
  }
}

/// Parameters for [ReauthenticateUseCase].
class ReauthenticateParams extends Equatable {
  final String password;

  const ReauthenticateParams({required this.password});

  @override
  List<Object?> get props => [password];
}
