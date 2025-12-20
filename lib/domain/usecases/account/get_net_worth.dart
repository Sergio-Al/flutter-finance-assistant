import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Financial summary containing balance aggregations.
class FinancialSummary extends Equatable {
  /// Total balance across all accounts
  final double totalBalance;

  /// Net worth (assets - liabilities)
  final double netWorth;

  /// Total assets (bank accounts, cash, savings, investments)
  final double totalAssets;

  /// Total liabilities (credit cards, loans)
  final double totalLiabilities;

  const FinancialSummary({
    required this.totalBalance,
    required this.netWorth,
    required this.totalAssets,
    required this.totalLiabilities,
  });

  @override
  List<Object?> get props => [
    totalBalance,
    netWorth,
    totalAssets,
    totalLiabilities,
  ];

  static const empty = FinancialSummary(
    totalBalance: 0,
    netWorth: 0,
    totalAssets: 0,
    totalLiabilities: 0,
  );
}

/// Use case for calculating net worth and financial summary.
///
/// Aggregates all accounts to compute:
/// - Total balance
/// - Net worth (assets - liabilities)
/// - Total assets
/// - Total liabilities
///
/// ## Example Usage
/// ```dart
/// final useCase = GetNetWorthUseCase(accountRepository);
///
/// final result = await useCase(
///   GetNetWorthParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (summary) {
///     print('Net Worth: \$${summary.netWorth}');
///     print('Assets: \$${summary.totalAssets}');
///     print('Liabilities: \$${summary.totalLiabilities}');
///   },
/// );
/// ```
class GetNetWorthUseCase extends UseCase<FinancialSummary, GetNetWorthParams> {
  final AccountRepository repository;

  GetNetWorthUseCase(this.repository);

  @override
  Future<Either<Failure, FinancialSummary>> call(
    GetNetWorthParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    try {
      // Fetch all required data in parallel
      final results = await Future.wait([
        repository.getTotalBalance(params.userId),
        repository.getNetWorth(params.userId),
        repository.getAccounts(params.userId),
      ]);

      final totalBalanceResult = results[0] as Either<Failure, double>;
      final netWorthResult = results[1] as Either<Failure, double>;
      final accountsResult = results[2] as Either<Failure, List<dynamic>>;

      // Check for failures
      if (totalBalanceResult.isLeft()) {
        return Left((totalBalanceResult as Left<Failure, double>).value);
      }
      if (netWorthResult.isLeft()) {
        return Left((netWorthResult as Left<Failure, double>).value);
      }
      if (accountsResult.isLeft()) {
        return Left((accountsResult as Left<Failure, List<dynamic>>).value);
      }

      final totalBalance = (totalBalanceResult as Right<Failure, double>).value;
      final netWorth = (netWorthResult as Right<Failure, double>).value;
      final accounts = (accountsResult as Right<Failure, List<dynamic>>).value;

      // Calculate assets and liabilities from accounts
      double totalAssets = 0;
      double totalLiabilities = 0;

      for (final account in accounts) {
        // Check if account is a liability type
        final isLiability =
            account.type.toString().contains('creditCard') ||
            account.type.toString().contains('loan');

        if (isLiability) {
          totalLiabilities += account.balance.abs();
        } else {
          totalAssets += account.balance;
        }
      }

      return Right(
        FinancialSummary(
          totalBalance: totalBalance,
          netWorth: netWorth,
          totalAssets: totalAssets,
          totalLiabilities: totalLiabilities,
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(
          message: 'Failed to calculate net worth: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}

/// Parameters for [GetNetWorthUseCase].
class GetNetWorthParams extends Equatable {
  final String userId;

  const GetNetWorthParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
