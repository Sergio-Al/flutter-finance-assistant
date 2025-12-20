import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for getting exceeded budgets.
///
/// Returns budgets where spent amount exceeds the limit.
/// Useful for alerts and dashboard warnings.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetExceededBudgetsUseCase(budgetRepository);
///
/// final result = await useCase(
///   GetExceededBudgetsParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => handleError(failure),
///   (budgets) {
///     if (budgets.isNotEmpty) {
///       showWarning('${budgets.length} budgets exceeded!');
///     }
///   },
/// );
/// ```
class GetExceededBudgetsUseCase
    extends UseCase<List<Budget>, GetExceededBudgetsParams> {
  final BudgetRepository repository;

  GetExceededBudgetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(
    GetExceededBudgetsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getExceededBudgets(params.userId);
  }
}

/// Parameters for [GetExceededBudgetsUseCase].
class GetExceededBudgetsParams extends Equatable {
  final String userId;

  const GetExceededBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting budgets at warning level.
///
/// Returns budgets that have reached their alert threshold but not exceeded.
class GetWarningBudgetsUseCase
    extends UseCase<List<Budget>, GetWarningBudgetsParams> {
  final BudgetRepository repository;

  GetWarningBudgetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(
    GetWarningBudgetsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getWarningBudgets(params.userId);
  }
}

/// Parameters for [GetWarningBudgetsUseCase].
class GetWarningBudgetsParams extends Equatable {
  final String userId;

  const GetWarningBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Represents the status of a budget check.
class BudgetCheckResult extends Equatable {
  final Budget budget;
  final bool isExceeded;
  final bool isWarning;
  final double remainingAmount;
  final double dailyBudgetRemaining;
  final int daysRemaining;
  final String message;

  const BudgetCheckResult({
    required this.budget,
    required this.isExceeded,
    required this.isWarning,
    required this.remainingAmount,
    required this.dailyBudgetRemaining,
    required this.daysRemaining,
    required this.message,
  });

  @override
  List<Object?> get props => [
    budget,
    isExceeded,
    isWarning,
    remainingAmount,
    dailyBudgetRemaining,
    daysRemaining,
    message,
  ];
}

/// Use case for checking budget status.
///
/// Returns detailed status information for a specific budget.
class CheckBudgetStatusUseCase
    extends UseCase<BudgetCheckResult, CheckBudgetStatusParams> {
  final BudgetRepository repository;

  CheckBudgetStatusUseCase(this.repository);

  @override
  Future<Either<Failure, BudgetCheckResult>> call(
    CheckBudgetStatusParams params,
  ) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    final budgetResult = await repository.getBudgetById(params.budgetId);

    return budgetResult.fold((failure) => Left(failure), (budget) {
      final isExceeded = budget.isExceeded;
      final isWarning = budget.isWarning;

      String message;
      if (isExceeded) {
        final overAmount = budget.spentAmount - budget.amount;
        message = 'Budget exceeded by \$${overAmount.toStringAsFixed(2)}';
      } else if (isWarning) {
        message =
            '${budget.progressPercent}% of budget used. '
            '\$${budget.remainingAmount.toStringAsFixed(2)} remaining';
      } else {
        message =
            '\$${budget.remainingAmount.toStringAsFixed(2)} remaining '
            '(${budget.daysRemaining} days left)';
      }

      return Right(
        BudgetCheckResult(
          budget: budget,
          isExceeded: isExceeded,
          isWarning: isWarning,
          remainingAmount: budget.remainingAmount,
          dailyBudgetRemaining: budget.dailyBudgetRemaining,
          daysRemaining: budget.daysRemaining,
          message: message,
        ),
      );
    });
  }
}

/// Parameters for [CheckBudgetStatusUseCase].
class CheckBudgetStatusParams extends Equatable {
  final String budgetId;

  const CheckBudgetStatusParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}
