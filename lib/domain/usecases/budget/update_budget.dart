import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for updating a budget.
///
/// ## Example Usage
/// ```dart
/// final useCase = UpdateBudgetUseCase(budgetRepository);
///
/// final result = await useCase(
///   UpdateBudgetParams(budget: updatedBudget),
/// );
/// ```
class UpdateBudgetUseCase extends UseCase<Budget, UpdateBudgetParams> {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(UpdateBudgetParams params) async {
    if (params.budget.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    if (params.budget.amount <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Budget amount must be greater than zero',
          code: 'INVALID_AMOUNT',
        ),
      );
    }

    final updatedBudget = params.budget.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    return repository.updateBudget(updatedBudget);
  }
}

/// Parameters for [UpdateBudgetUseCase].
class UpdateBudgetParams extends Equatable {
  final Budget budget;

  const UpdateBudgetParams({required this.budget});

  @override
  List<Object?> get props => [budget];
}

/// Use case for deleting a budget.
class DeleteBudgetUseCase extends UseCase<void, DeleteBudgetParams> {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBudgetParams params) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    return repository.deleteBudget(params.budgetId);
  }
}

/// Parameters for [DeleteBudgetUseCase].
class DeleteBudgetParams extends Equatable {
  final String budgetId;

  const DeleteBudgetParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Use case for adding spending to a budget.
///
/// Used when a new transaction is created.
class AddSpendingToBudgetUseCase
    extends UseCase<Budget, AddSpendingToBudgetParams> {
  final BudgetRepository repository;

  AddSpendingToBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(AddSpendingToBudgetParams params) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    if (params.amount <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Amount must be greater than zero',
          code: 'INVALID_AMOUNT',
        ),
      );
    }

    return repository.addSpending(params.budgetId, params.amount);
  }
}

/// Parameters for [AddSpendingToBudgetUseCase].
class AddSpendingToBudgetParams extends Equatable {
  final String budgetId;
  final double amount;

  const AddSpendingToBudgetParams({
    required this.budgetId,
    required this.amount,
  });

  @override
  List<Object?> get props => [budgetId, amount];
}

/// Use case for subtracting spending from a budget.
///
/// Used when a transaction is deleted or refunded.
class SubtractSpendingFromBudgetUseCase
    extends UseCase<Budget, SubtractSpendingFromBudgetParams> {
  final BudgetRepository repository;

  SubtractSpendingFromBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(
    SubtractSpendingFromBudgetParams params,
  ) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    if (params.amount <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Amount must be greater than zero',
          code: 'INVALID_AMOUNT',
        ),
      );
    }

    return repository.subtractSpending(params.budgetId, params.amount);
  }
}

/// Parameters for [SubtractSpendingFromBudgetUseCase].
class SubtractSpendingFromBudgetParams extends Equatable {
  final String budgetId;
  final double amount;

  const SubtractSpendingFromBudgetParams({
    required this.budgetId,
    required this.amount,
  });

  @override
  List<Object?> get props => [budgetId, amount];
}

/// Use case for recalculating budget spent amount from transactions.
///
/// Useful for data correction or after bulk imports.
class RecalculateBudgetUseCase
    extends UseCase<Budget, RecalculateBudgetParams> {
  final BudgetRepository repository;

  RecalculateBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(RecalculateBudgetParams params) async {
    if (params.budgetId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Budget ID is required',
          code: 'MISSING_BUDGET_ID',
        ),
      );
    }

    return repository.recalculateSpentAmount(params.budgetId);
  }
}

/// Parameters for [RecalculateBudgetUseCase].
class RecalculateBudgetParams extends Equatable {
  final String budgetId;

  const RecalculateBudgetParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}
