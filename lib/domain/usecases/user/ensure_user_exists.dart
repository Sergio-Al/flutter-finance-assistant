import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/user_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for ensuring a user exists in the local database.
///
/// This use case should be called after successful authentication to guarantee
/// the user record exists in the local database, satisfying foreign key
/// constraints for other tables (categories, budgets, transactions, etc.).
///
/// If the user already exists, this is a no-op.
/// If the user doesn't exist, a minimal user record is created.
///
/// ## Example Usage
/// ```dart
/// final useCase = EnsureUserExistsUseCase(userRepository);
///
/// final result = await useCase(
///   EnsureUserExistsParams(
///     userId: 'firebase-user-id',
///     email: 'user@example.com',
///   ),
/// );
///
/// result.fold(
///   (failure) => log('Failed to ensure user exists: ${failure.message}'),
///   (_) => log('User exists in local database'),
/// );
/// ```
class EnsureUserExistsUseCase extends UseCase<void, EnsureUserExistsParams> {
  final UserRepository repository;

  EnsureUserExistsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EnsureUserExistsParams params) async {
    if (params.userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.ensureUserExists(params.userId, email: params.email);
  }
}

/// Parameters for [EnsureUserExistsUseCase].
class EnsureUserExistsParams extends Equatable {
  /// The Firebase user ID.
  final String userId;

  /// Optional email address for the user record.
  final String? email;

  const EnsureUserExistsParams({required this.userId, this.email});

  @override
  List<Object?> get props => [userId, email];
}
