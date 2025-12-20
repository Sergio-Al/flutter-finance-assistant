import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for retrieving all budgets for a user.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetBudgetsUseCase(budgetRepository);
///
/// final result = await useCase(
///   GetBudgetsParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (budgets) => displayBudgets(budgets),
/// );
/// ```
class GetBudgetsUseCase extends UseCase<List<Budget>, GetBudgetsParams> {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(GetBudgetsParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getBudgets(params.userId);
  }
}

/// Parameters for [GetBudgetsUseCase].
class GetBudgetsParams extends Equatable {
  final String userId;

  const GetBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for retrieving active budgets only.
///
/// Returns budgets that are currently within their active period.
class GetActiveBudgetsUseCase
    extends UseCase<List<Budget>, GetActiveBudgetsParams> {
  final BudgetRepository repository;

  GetActiveBudgetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(
    GetActiveBudgetsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getActiveBudgets(params.userId);
  }
}

/// Parameters for [GetActiveBudgetsUseCase].
class GetActiveBudgetsParams extends Equatable {
  final String userId;

  const GetActiveBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting a budget by category.
///
/// Useful for checking if a category already has a budget.
class GetBudgetByCategoryUseCase
    extends UseCase<Budget?, GetBudgetByCategoryParams> {
  final BudgetRepository repository;

  GetBudgetByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Budget?>> call(
    GetBudgetByCategoryParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.categoryId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category ID is required',
          code: 'MISSING_CATEGORY_ID',
        ),
      );
    }

    return repository.getBudgetByCategory(params.userId, params.categoryId);
  }
}

/// Parameters for [GetBudgetByCategoryUseCase].
class GetBudgetByCategoryParams extends Equatable {
  final String userId;
  final String categoryId;

  const GetBudgetByCategoryParams({
    required this.userId,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [userId, categoryId];
}

/// Use case for getting budgets by period type.
class GetBudgetsByPeriodUseCase
    extends UseCase<List<Budget>, GetBudgetsByPeriodParams> {
  final BudgetRepository repository;

  GetBudgetsByPeriodUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(
    GetBudgetsByPeriodParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getBudgetsByPeriod(params.userId, params.period);
  }
}

/// Parameters for [GetBudgetsByPeriodUseCase].
class GetBudgetsByPeriodParams extends Equatable {
  final String userId;
  final BudgetPeriod period;

  const GetBudgetsByPeriodParams({required this.userId, required this.period});

  @override
  List<Object?> get props => [userId, period];
}
