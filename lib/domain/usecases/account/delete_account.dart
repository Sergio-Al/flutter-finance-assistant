import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for deleting an account (soft delete).
///
/// Marks the account as inactive but preserves data.
/// Use [PermanentlyDeleteAccountUseCase] for hard delete.
///
/// ## Example Usage
/// ```dart
/// final useCase = DeleteAccountUseCase(accountRepository);
///
/// final result = await useCase(
///   DeleteAccountParams(accountId: 'account-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (_) => showSuccess('Account deleted'),
/// );
/// ```
class DeleteAccountUseCase extends UseCase<void, DeleteAccountParams> {
  final AccountRepository repository;

  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    return repository.deleteAccount(params.accountId);
  }
}

/// Parameters for [DeleteAccountUseCase].
class DeleteAccountParams extends Equatable {
  final String accountId;

  const DeleteAccountParams({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

/// Use case for permanently deleting an account.
///
/// ⚠️ WARNING: This permanently removes the account and ALL associated
/// transactions. This action cannot be undone.
///
/// ## Example Usage
/// ```dart
/// final useCase = PermanentlyDeleteAccountUseCase(accountRepository);
///
/// // Always confirm with user before calling!
/// final result = await useCase(
///   PermanentlyDeleteAccountParams(
///     accountId: 'account-123',
///     confirmDeletion: true, // Must be true
///   ),
/// );
/// ```
class PermanentlyDeleteAccountUseCase
    extends UseCase<void, PermanentlyDeleteAccountParams> {
  final AccountRepository repository;

  PermanentlyDeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(
    PermanentlyDeleteAccountParams params,
  ) async {
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    if (!params.confirmDeletion) {
      return const Left(
        ValidationFailure(
          message: 'Deletion must be confirmed',
          code: 'DELETION_NOT_CONFIRMED',
        ),
      );
    }

    return repository.permanentlyDeleteAccount(params.accountId);
  }
}

/// Parameters for [PermanentlyDeleteAccountUseCase].
class PermanentlyDeleteAccountParams extends Equatable {
  final String accountId;

  /// Must be true to proceed with deletion
  final bool confirmDeletion;

  const PermanentlyDeleteAccountParams({
    required this.accountId,
    this.confirmDeletion = false,
  });

  @override
  List<Object?> get props => [accountId, confirmDeletion];
}

/// Use case for updating account details.
///
/// Updates non-balance fields like name, icon, color, etc.
/// For balance updates, use [UpdateAccountBalanceUseCase].
class UpdateAccountUseCase extends UseCase<Account, UpdateAccountParams> {
  final AccountRepository repository;

  UpdateAccountUseCase(this.repository);

  @override
  Future<Either<Failure, Account>> call(UpdateAccountParams params) async {
    if (params.account.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    if (params.account.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account name is required',
          code: 'MISSING_ACCOUNT_NAME',
        ),
      );
    }

    // Update timestamp
    final updatedAccount = params.account.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    return repository.updateAccount(updatedAccount);
  }
}

/// Parameters for [UpdateAccountUseCase].
class UpdateAccountParams extends Equatable {
  final Account account;

  const UpdateAccountParams({required this.account});

  @override
  List<Object?> get props => [account];
}
