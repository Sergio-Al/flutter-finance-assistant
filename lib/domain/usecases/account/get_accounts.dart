import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for retrieving all accounts for a user.
///
/// Returns all accounts (active and inactive) by default.
/// Use [GetActiveAccountsUseCase] for active accounts only.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetAccountsUseCase(accountRepository);
///
/// final result = await useCase(
///   GetAccountsParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (accounts) => displayAccounts(accounts),
/// );
/// ```
class GetAccountsUseCase extends UseCase<List<Account>, GetAccountsParams> {
  final AccountRepository repository;

  GetAccountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Account>>> call(GetAccountsParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getAccounts(params.userId);
  }
}

/// Parameters for [GetAccountsUseCase].
class GetAccountsParams extends Equatable {
  final String userId;

  const GetAccountsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for retrieving only active accounts.
///
/// Filters out deleted/inactive accounts.
class GetActiveAccountsUseCase
    extends UseCase<List<Account>, GetActiveAccountsParams> {
  final AccountRepository repository;

  GetActiveAccountsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Account>>> call(
    GetActiveAccountsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getActiveAccounts(params.userId);
  }
}

/// Parameters for [GetActiveAccountsUseCase].
class GetActiveAccountsParams extends Equatable {
  final String userId;

  const GetActiveAccountsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for retrieving accounts by type.
///
/// Useful for showing grouped accounts (e.g., all bank accounts).
class GetAccountsByTypeUseCase
    extends UseCase<List<Account>, GetAccountsByTypeParams> {
  final AccountRepository repository;

  GetAccountsByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, List<Account>>> call(
    GetAccountsByTypeParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getAccountsByType(params.userId, params.type);
  }
}

/// Parameters for [GetAccountsByTypeUseCase].
class GetAccountsByTypeParams extends Equatable {
  final String userId;
  final AccountType type;

  const GetAccountsByTypeParams({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}
