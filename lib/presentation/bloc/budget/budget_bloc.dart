import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/usecases/budget/budget_usecases.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_state.dart';

/// BLoC for handling budget logic.
///
/// Manages budget CRUD operations, spending tracking, alerts,
/// and real-time updates.
///
/// Uses **Use Case Composition** pattern via [GetBudgetsWithRelationsUseCase]
/// to fetch budgets with populated category relations.
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final CreateBudgetUseCase createBudget;
  final GetBudgetsWithRelationsUseCase getBudgetsWithRelations;
  final GetActiveBudgetsUseCase getActiveBudgets;
  final UpdateBudgetUseCase updateBudget;
  final DeleteBudgetUseCase deleteBudget;
  final GetBudgetSummaryUseCase getBudgetSummary;
  final CheckBudgetStatusUseCase checkBudgetStatus;
  final WatchBudgetsWithRelationsUseCase watchBudgetsWithRelations;

  StreamSubscription? _budgetSubscription;
  String? _currentUserId;

  BudgetBloc({
    required this.createBudget,
    required this.getBudgetsWithRelations,
    required this.getActiveBudgets,
    required this.updateBudget,
    required this.deleteBudget,
    required this.getBudgetSummary,
    required this.checkBudgetStatus,
    required this.watchBudgetsWithRelations,
  }) : super(const BudgetInitial()) {
    // Load events
    on<BudgetLoadRequested>(_onLoadRequested);
    on<BudgetLoadActiveRequested>(_onLoadActiveRequested);
    on<BudgetSummaryRequested>(_onSummaryRequested);
    on<BudgetWatchRequested>(_onWatchRequested);

    // CRUD events
    on<BudgetCreateRequested>(_onCreateRequested);
    on<BudgetUpdateRequested>(_onUpdateRequested);
    on<BudgetDeleteRequested>(_onDeleteRequested);

    // Status events
    on<BudgetCheckStatusRequested>(_onCheckStatusRequested);
    on<BudgetLoadExceededRequested>(_onLoadExceededRequested);
    on<BudgetLoadWarningRequested>(_onLoadWarningRequested);

    // Internal events
    on<BudgetDataChanged>(_onDataChanged);
    on<BudgetErrorCleared>(_onErrorCleared);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onLoadRequested(
    BudgetLoadRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading(message: 'Loading budgets...'));
    _currentUserId = event.userId;

    // Use composed use case to get budgets with category relations
    final result = await getBudgetsWithRelations(
      GetBudgetsWithRelationsParams(
        userId: event.userId,
        includeCategory: true,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          BudgetError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (budgets) async {
        // Also fetch summary
        final summaryResult = await getBudgetSummary(
          GetBudgetSummaryParams(userId: event.userId),
        );

        final summary = summaryResult.fold((failure) => null, (s) => s);

        // Separate exceeded and warning budgets
        final exceededBudgets = budgets.where((b) => b.isExceeded).toList();
        final warningBudgets = budgets.where((b) => b.isWarning).toList();

        emit(
          BudgetLoaded(
            budgets: budgets,
            summary: summary,
            exceededBudgets: exceededBudgets,
            warningBudgets: warningBudgets,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onLoadActiveRequested(
    BudgetLoadActiveRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(const BudgetLoading(message: 'Loading active budgets...'));
    _currentUserId = event.userId;

    final result = await getActiveBudgets(
      GetActiveBudgetsParams(userId: event.userId),
    );

    result.fold(
      (failure) => emit(
        BudgetError(
          errorType: _mapFailureToErrorType(failure),
          message: failure.message,
          code: failure.code,
        ),
      ),
      (budgets) {
        final exceededBudgets = budgets.where((b) => b.isExceeded).toList();
        final warningBudgets = budgets.where((b) => b.isWarning).toList();

        emit(
          BudgetLoaded(
            budgets: budgets,
            exceededBudgets: exceededBudgets,
            warningBudgets: warningBudgets,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onSummaryRequested(
    BudgetSummaryRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BudgetLoaded) {
      emit(const BudgetLoading(message: 'Loading summary...'));
    }

    final result = await getBudgetSummary(
      GetBudgetSummaryParams(userId: event.userId),
    );

    result.fold(
      (failure) => emit(
        BudgetError(
          errorType: _mapFailureToErrorType(failure),
          message: failure.message,
          code: failure.code,
        ),
      ),
      (summary) {
        if (currentState is BudgetLoaded) {
          emit(
            currentState.copyWith(
              summary: summary,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  Future<void> _onWatchRequested(
    BudgetWatchRequested event,
    Emitter<BudgetState> emit,
  ) async {
    _currentUserId = event.userId;
    _budgetSubscription?.cancel();

    // Use composed watch use case to get real-time budgets with categories
    _budgetSubscription =
        watchBudgetsWithRelations(
          WatchBudgetsWithRelationsParams(
            userId: event.userId,
            includeCategory: true,
          ),
        ).listen((result) {
          result.fold(
            (failure) {
              // Handle failure silently or log
            },
            (budgets) {
              add(BudgetDataChanged(budgets: budgets));
            },
          );
        });

    // Also do initial load
    add(BudgetLoadRequested(userId: event.userId));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onCreateRequested(
    BudgetCreateRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(
      const BudgetOperationInProgress(operation: BudgetOperationType.create),
    );

    final result = await createBudget(
      CreateBudgetParams(
        accountId: event.accountId,
        categoryId: event.categoryId,
        amount: event.amount,
        period: event.period,
        startDate: event.startDate,
        rollover: event.rollover,
        alertsEnabled: event.alertsEnabled,
        alertThreshold: event.alertThreshold,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          BudgetError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (budget) async {
        emit(
          BudgetOperationSuccess(
            operation: BudgetOperationType.create,
            budget: budget,
            message: BudgetOperationType.create.successMessage,
          ),
        );

        // Reload budgets if we have a user ID
        if (_currentUserId != null) {
          add(BudgetLoadRequested(userId: _currentUserId!));
        }
      },
    );
  }

  Future<void> _onUpdateRequested(
    BudgetUpdateRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(
      BudgetOperationInProgress(
        operation: BudgetOperationType.update,
        budgetId: event.budget.id,
      ),
    );

    final result = await updateBudget(UpdateBudgetParams(budget: event.budget));

    await result.fold(
      (failure) async {
        emit(
          BudgetError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (budget) async {
        emit(
          BudgetOperationSuccess(
            operation: BudgetOperationType.update,
            budget: budget,
            message: BudgetOperationType.update.successMessage,
          ),
        );

        // Reload budgets
        if (_currentUserId != null) {
          add(BudgetLoadRequested(userId: _currentUserId!));
        }
      },
    );
  }

  Future<void> _onDeleteRequested(
    BudgetDeleteRequested event,
    Emitter<BudgetState> emit,
  ) async {
    emit(
      BudgetOperationInProgress(
        operation: BudgetOperationType.delete,
        budgetId: event.budgetId,
      ),
    );

    final result = await deleteBudget(
      DeleteBudgetParams(budgetId: event.budgetId),
    );

    await result.fold(
      (failure) async {
        emit(
          BudgetError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (_) async {
        emit(
          BudgetOperationSuccess(
            operation: BudgetOperationType.delete,
            message: BudgetOperationType.delete.successMessage,
          ),
        );

        // Reload budgets
        if (_currentUserId != null) {
          add(BudgetLoadRequested(userId: _currentUserId!));
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onCheckStatusRequested(
    BudgetCheckStatusRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final result = await checkBudgetStatus(
      CheckBudgetStatusParams(budgetId: event.budgetId),
    );

    result.fold(
      (failure) => emit(
        BudgetError(
          errorType: _mapFailureToErrorType(failure),
          message: failure.message,
          code: failure.code,
        ),
      ),
      (status) =>
          emit(BudgetDetailLoaded(budget: status.budget, status: status)),
    );
  }

  Future<void> _onLoadExceededRequested(
    BudgetLoadExceededRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final currentState = state;

    final result = await getBudgetsWithRelations(
      GetBudgetsWithRelationsParams(
        userId: event.userId,
        includeCategory: true,
      ),
    );

    result.fold(
      (failure) {
        // Keep current state on failure
      },
      (budgets) {
        final exceededBudgets = budgets.where((b) => b.isExceeded).toList();

        if (currentState is BudgetLoaded) {
          emit(
            currentState.copyWith(
              exceededBudgets: exceededBudgets,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadWarningRequested(
    BudgetLoadWarningRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final currentState = state;

    final result = await getBudgetsWithRelations(
      GetBudgetsWithRelationsParams(
        userId: event.userId,
        includeCategory: true,
      ),
    );

    result.fold(
      (failure) {
        // Keep current state on failure
      },
      (budgets) {
        final warningBudgets = budgets.where((b) => b.isWarning).toList();

        if (currentState is BudgetLoaded) {
          emit(
            currentState.copyWith(
              warningBudgets: warningBudgets,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDataChanged(BudgetDataChanged event, Emitter<BudgetState> emit) {
    final currentState = state;

    final exceededBudgets = event.budgets.where((b) => b.isExceeded).toList();
    final warningBudgets = event.budgets.where((b) => b.isWarning).toList();

    if (currentState is BudgetLoaded) {
      emit(
        currentState.copyWith(
          budgets: event.budgets,
          exceededBudgets: exceededBudgets,
          warningBudgets: warningBudgets,
          lastUpdated: DateTime.now(),
        ),
      );
    } else {
      emit(
        BudgetLoaded(
          budgets: event.budgets,
          exceededBudgets: exceededBudgets,
          warningBudgets: warningBudgets,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  void _onErrorCleared(BudgetErrorCleared event, Emitter<BudgetState> emit) {
    emit(const BudgetInitial());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  BudgetErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is ValidationFailure) {
      if (failure.code == 'CATEGORY_HAS_BUDGET') {
        return BudgetErrorType.categoryAlreadyHasBudget;
      }
      return BudgetErrorType.validationError;
    } else if (failure is NotFoundFailure) {
      return BudgetErrorType.budgetNotFound;
    } else if (failure is NetworkFailure) {
      return BudgetErrorType.networkError;
    }
    return BudgetErrorType.unknown;
  }

  @override
  Future<void> close() {
    _budgetSubscription?.cancel();
    return super.close();
  }
}
