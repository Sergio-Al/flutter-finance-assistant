import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/transaction_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// A summary of spending data for a given period.
///
/// Contains aggregated financial data useful for dashboards and reports.
class SpendingSummary extends Equatable {
  /// Total amount spent (expenses)
  final double totalSpent;

  /// Total amount earned (income)
  final double totalIncome;

  /// Net balance (income - expenses)
  final double netBalance;

  /// Spending broken down by category (categoryId -> amount)
  final Map<String, double> spendingByCategory;

  /// Number of transactions in the period
  final int transactionCount;

  const SpendingSummary({
    required this.totalSpent,
    required this.totalIncome,
    required this.netBalance,
    required this.spendingByCategory,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [
    totalSpent,
    totalIncome,
    netBalance,
    spendingByCategory,
    transactionCount,
  ];

  /// Empty summary for initial/error states
  static const empty = SpendingSummary(
    totalSpent: 0,
    totalIncome: 0,
    netBalance: 0,
    spendingByCategory: {},
    transactionCount: 0,
  );
}

/// Use case for generating a comprehensive spending summary.
///
/// Aggregates multiple repository calls to build a complete
/// financial overview for a given period.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetSpendingSummaryUseCase(transactionRepository);
///
/// final result = await useCase(
///   GetSpendingSummaryParams(
///     accountId: 'account-123',
///     startDate: DateTime(2024, 1, 1),
///     endDate: DateTime(2024, 1, 31),
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (summary) {
///     print('Total Spent: \$${summary.totalSpent}');
///     print('Total Income: \$${summary.totalIncome}');
///     print('Net Balance: \$${summary.netBalance}');
///   },
/// );
/// ```
class GetSpendingSummaryUseCase
    extends UseCase<SpendingSummary, GetSpendingSummaryParams> {
  final TransactionRepository repository;

  GetSpendingSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, SpendingSummary>> call(
    GetSpendingSummaryParams params,
  ) async {
    // Validate inputs
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure(
          message: 'Start date must be before or equal to end date',
          code: 'INVALID_DATE_RANGE',
        ),
      );
    }

    try {
      // Fetch all required data in parallel for better performance
      final results = await Future.wait([
        repository.getTotalSpent(
          params.accountId,
          params.startDate,
          params.endDate,
        ),
        repository.getTotalIncome(
          params.accountId,
          params.startDate,
          params.endDate,
        ),
        repository.getSpendingByCategory(
          params.accountId,
          params.startDate,
          params.endDate,
        ),
        repository.getTransactionsByDateRange(
          params.accountId,
          params.startDate,
          params.endDate,
        ),
      ]);

      // Extract results
      final spentResult = results[0] as Either<Failure, double>;
      final incomeResult = results[1] as Either<Failure, double>;
      final categoryResult = results[2] as Either<Failure, Map<String, double>>;
      final transactionsResult = results[3] as Either<Failure, List<dynamic>>;

      // Check for failures
      if (spentResult.isLeft()) {
        return Left((spentResult as Left<Failure, double>).value);
      }
      if (incomeResult.isLeft()) {
        return Left((incomeResult as Left<Failure, double>).value);
      }
      if (categoryResult.isLeft()) {
        return Left(
          (categoryResult as Left<Failure, Map<String, double>>).value,
        );
      }
      if (transactionsResult.isLeft()) {
        return Left((transactionsResult as Left<Failure, List<dynamic>>).value);
      }

      // Extract values
      final totalSpent = (spentResult as Right<Failure, double>).value;
      final totalIncome = (incomeResult as Right<Failure, double>).value;
      final spendingByCategory =
          (categoryResult as Right<Failure, Map<String, double>>).value;
      final transactions =
          (transactionsResult as Right<Failure, List<dynamic>>).value;

      return Right(
        SpendingSummary(
          totalSpent: totalSpent,
          totalIncome: totalIncome,
          netBalance: totalIncome - totalSpent,
          spendingByCategory: spendingByCategory,
          transactionCount: transactions.length,
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(
          message: 'Failed to generate spending summary: ${e.toString()}',
          originalError: e,
        ),
      );
    }
  }
}

/// Parameters for [GetSpendingSummaryUseCase].
class GetSpendingSummaryParams extends Equatable {
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const GetSpendingSummaryParams({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [accountId, startDate, endDate];

  /// Helper to create params for current month
  factory GetSpendingSummaryParams.currentMonth(String accountId) {
    final now = DateTime.now();
    return GetSpendingSummaryParams(
      accountId: accountId,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0), // Last day of month
    );
  }

  /// Helper to create params for last 30 days
  factory GetSpendingSummaryParams.last30Days(String accountId) {
    final now = DateTime.now();
    return GetSpendingSummaryParams(
      accountId: accountId,
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
    );
  }
}
