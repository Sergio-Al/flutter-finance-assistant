import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for getting budget summary/overview.
///
/// Returns aggregated data about all budgets for a user.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetBudgetSummaryUseCase(budgetRepository);
///
/// final result = await useCase(
///   GetBudgetSummaryParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => handleError(failure),
///   (summary) {
///     print('Total Budgeted: \$${summary.totalBudgeted}');
///     print('Total Spent: \$${summary.totalSpent}');
///     print('Exceeded: ${summary.exceededBudgets}');
///   },
/// );
/// ```
class GetBudgetSummaryUseCase
    extends UseCase<BudgetSummary, GetBudgetSummaryParams> {
  final BudgetRepository repository;

  GetBudgetSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, BudgetSummary>> call(
    GetBudgetSummaryParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getBudgetSummary(params.userId);
  }
}

/// Parameters for [GetBudgetSummaryUseCase].
class GetBudgetSummaryParams extends Equatable {
  final String userId;

  const GetBudgetSummaryParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting budget history.
///
/// Returns past periods for a specific budget.
class GetBudgetHistoryUseCase
    extends UseCase<List<BudgetHistory>, GetBudgetHistoryParams> {
  final BudgetRepository repository;

  GetBudgetHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<BudgetHistory>>> call(
    GetBudgetHistoryParams params,
  ) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    return repository.getBudgetHistory(params.budgetId, limit: params.limit);
  }
}

/// Parameters for [GetBudgetHistoryUseCase].
class GetBudgetHistoryParams extends Equatable {
  final String budgetId;
  final int limit;

  const GetBudgetHistoryParams({required this.budgetId, this.limit = 12});

  @override
  List<Object?> get props => [budgetId, limit];
}

/// Use case for resetting a budget for a new period.
class ResetBudgetPeriodUseCase
    extends UseCase<Budget, ResetBudgetPeriodParams> {
  final BudgetRepository repository;

  ResetBudgetPeriodUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(ResetBudgetPeriodParams params) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    return repository.resetBudgetPeriod(params.budgetId);
  }
}

/// Parameters for [ResetBudgetPeriodUseCase].
class ResetBudgetPeriodParams extends Equatable {
  final String budgetId;

  const ResetBudgetPeriodParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Use case for rolling over unused budget to next period.
class RolloverBudgetUseCase extends UseCase<Budget, RolloverBudgetParams> {
  final BudgetRepository repository;

  RolloverBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(RolloverBudgetParams params) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    return repository.rolloverBudget(params.budgetId);
  }
}

/// Parameters for [RolloverBudgetUseCase].
class RolloverBudgetParams extends Equatable {
  final String budgetId;

  const RolloverBudgetParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}
