import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for updating an account's balance.
///
/// Used when:
/// - Manual balance correction
/// - Reconciliation
/// - Setting initial balance
///
/// ## Example Usage
/// ```dart
/// final useCase = UpdateAccountBalanceUseCase(accountRepository);
///
/// final result = await useCase(
///   UpdateAccountBalanceParams(
///     accountId: 'account-123',
///     newBalance: 1500.00,
///   ),
/// );
/// ```
class UpdateAccountBalanceUseCase
    extends UseCase<Account, UpdateAccountBalanceParams> {
  final AccountRepository repository;

  UpdateAccountBalanceUseCase(this.repository);

  @override
  Future<Either<Failure, Account>> call(
    UpdateAccountBalanceParams params,
  ) async {
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    return repository.updateBalance(params.accountId, params.newBalance);
  }
}

/// Parameters for [UpdateAccountBalanceUseCase].
class UpdateAccountBalanceParams extends Equatable {
  final String accountId;
  final double newBalance;

  const UpdateAccountBalanceParams({
    required this.accountId,
    required this.newBalance,
  });

  @override
  List<Object?> get props => [accountId, newBalance];
}

/// Use case for adjusting an account balance by an amount.
///
/// Adds or subtracts from current balance (use negative for subtraction).
/// Used for quick adjustments without knowing the current balance.
///
/// ## Example Usage
/// ```dart
/// // Add $100
/// await useCase(AdjustAccountBalanceParams(accountId: 'acc-1', amount: 100));
///
/// // Subtract $50
/// await useCase(AdjustAccountBalanceParams(accountId: 'acc-1', amount: -50));
/// ```
class AdjustAccountBalanceUseCase
    extends UseCase<Account, AdjustAccountBalanceParams> {
  final AccountRepository repository;

  AdjustAccountBalanceUseCase(this.repository);

  @override
  Future<Either<Failure, Account>> call(
    AdjustAccountBalanceParams params,
  ) async {
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    if (params.amount == 0) {
      return const Left(
        ValidationFailure(
          message: 'Adjustment amount cannot be zero',
          code: 'ZERO_ADJUSTMENT',
        ),
      );
    }

    return repository.adjustBalance(params.accountId, params.amount);
  }
}

/// Parameters for [AdjustAccountBalanceUseCase].
class AdjustAccountBalanceParams extends Equatable {
  final String accountId;
  final double amount;

  const AdjustAccountBalanceParams({
    required this.accountId,
    required this.amount,
  });

  @override
  List<Object?> get props => [accountId, amount];
}
