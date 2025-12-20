import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for sending a password reset email.
///
/// ## Example Usage
/// ```dart
/// final useCase = SendPasswordResetEmailUseCase(authRepository);
///
/// final result = await useCase(
///   SendPasswordResetEmailParams(email: 'user@example.com'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (_) => showSuccess('Password reset email sent'),
/// );
/// ```
class SendPasswordResetEmailUseCase
    extends UseCase<void, SendPasswordResetEmailParams> {
  final AuthRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    SendPasswordResetEmailParams params,
  ) async {
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

    return repository.sendPasswordResetEmail(params.email.trim().toLowerCase());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parameters for [SendPasswordResetEmailUseCase].
class SendPasswordResetEmailParams extends Equatable {
  final String email;

  const SendPasswordResetEmailParams({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Use case for updating the user's password.
///
/// Requires current password for security verification.
///
/// ## Example Usage
/// ```dart
/// final useCase = UpdatePasswordUseCase(authRepository);
///
/// final result = await useCase(
///   UpdatePasswordParams(
///     currentPassword: 'oldPassword123',
///     newPassword: 'newSecurePassword123',
///     confirmNewPassword: 'newSecurePassword123',
///   ),
/// );
/// ```
class UpdatePasswordUseCase extends UseCase<void, UpdatePasswordParams> {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePasswordParams params) async {
    // Validate current password
    if (params.currentPassword.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Current password is required',
          code: 'MISSING_CURRENT_PASSWORD',
        ),
      );
    }

    // Validate new password
    if (params.newPassword.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'New password is required',
          code: 'MISSING_NEW_PASSWORD',
        ),
      );
    }

    if (params.newPassword.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'New password must be at least 8 characters',
          code: 'PASSWORD_TOO_SHORT',
        ),
      );
    }

    if (!_isStrongPassword(params.newPassword)) {
      return const Left(
        ValidationFailure(
          message:
              'Password must contain at least one uppercase letter, one lowercase letter, and one number',
          code: 'WEAK_PASSWORD',
        ),
      );
    }

    // Validate confirmation
    if (params.newPassword != params.confirmNewPassword) {
      return const Left(
        ValidationFailure(
          message: 'New passwords do not match',
          code: 'PASSWORD_MISMATCH',
        ),
      );
    }

    // Check not same as current
    if (params.currentPassword == params.newPassword) {
      return const Left(
        ValidationFailure(
          message: 'New password must be different from current password',
          code: 'SAME_PASSWORD',
        ),
      );
    }

    return repository.updatePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password);
  }
}

/// Parameters for [UpdatePasswordUseCase].
class UpdatePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  const UpdatePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmNewPassword];
}

/// Use case for confirming a password reset with code.
///
/// Used after user clicks the link in password reset email.
class ConfirmPasswordResetUseCase
    extends UseCase<void, ConfirmPasswordResetParams> {
  final AuthRepository repository;

  ConfirmPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ConfirmPasswordResetParams params) async {
    if (params.code.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Reset code is required',
          code: 'MISSING_RESET_CODE',
        ),
      );
    }

    if (params.newPassword.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'New password is required',
          code: 'MISSING_NEW_PASSWORD',
        ),
      );
    }

    if (params.newPassword.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'Password must be at least 8 characters',
          code: 'PASSWORD_TOO_SHORT',
        ),
      );
    }

    return repository.confirmPasswordReset(
      code: params.code,
      newPassword: params.newPassword,
    );
  }
}

/// Parameters for [ConfirmPasswordResetUseCase].
class ConfirmPasswordResetParams extends Equatable {
  final String code;
  final String newPassword;

  const ConfirmPasswordResetParams({
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [code, newPassword];
}
