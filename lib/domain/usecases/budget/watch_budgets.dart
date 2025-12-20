import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for watching budgets in real-time.
///
/// Returns a [Stream] that emits whenever budgets change.
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchBudgetsUseCase(budgetRepository);
///
/// final stream = useCase(
///   WatchBudgetsParams(userId: 'user-123'),
/// );
///
/// stream.listen((result) {
///   result.fold(
///     (failure) => showError(failure.message),
///     (budgets) => updateBudgetList(budgets),
///   );
/// });
/// ```
class WatchBudgetsUseCase
    extends StreamUseCase<List<Budget>, WatchBudgetsParams> {
  final BudgetRepository repository;

  WatchBudgetsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Budget>>> call(WatchBudgetsParams params) {
    if (params.userId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            code: 'MISSING_USER_ID',
          ),
        ),
      );
    }

    return repository.watchBudgets(params.userId);
  }
}

/// Parameters for [WatchBudgetsUseCase].
class WatchBudgetsParams extends Equatable {
  final String userId;

  const WatchBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for watching a single budget in real-time.
class WatchBudgetUseCase extends StreamUseCase<Budget, WatchBudgetParams> {
  final BudgetRepository repository;

  WatchBudgetUseCase(this.repository);

  @override
  Stream<Either<Failure, Budget>> call(WatchBudgetParams params) {
    if (params.budgetId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Budget ID is required',
            code: 'MISSING_BUDGET_ID',
          ),
        ),
      );
    }

    return repository.watchBudget(params.budgetId);
  }
}

/// Parameters for [WatchBudgetUseCase].
class WatchBudgetParams extends Equatable {
  final String budgetId;

  const WatchBudgetParams({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Use case for watching exceeded budgets for alerts.
///
/// Useful for real-time budget alert notifications.
class WatchExceededBudgetsUseCase
    extends StreamUseCase<List<Budget>, WatchExceededBudgetsParams> {
  final BudgetRepository repository;

  WatchExceededBudgetsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Budget>>> call(
    WatchExceededBudgetsParams params,
  ) {
    if (params.userId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            code: 'MISSING_USER_ID',
          ),
        ),
      );
    }

    return repository.watchExceededBudgets(params.userId);
  }
}

/// Parameters for [WatchExceededBudgetsUseCase].
class WatchExceededBudgetsParams extends Equatable {
  final String userId;

  const WatchExceededBudgetsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
