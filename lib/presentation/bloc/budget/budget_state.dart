import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/budget/check_budget_status.dart';

/// Base class for all budget states.
abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// BASIC STATES
// ═══════════════════════════════════════════════════════════════════════════

/// Initial state before any action.
class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

/// Loading state while fetching budgets.
class BudgetLoading extends BudgetState {
  final String? message;

  const BudgetLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADED STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when budgets are loaded successfully.
class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final BudgetSummary? summary;
  final List<Budget> exceededBudgets;
  final List<Budget> warningBudgets;
  final DateTime lastUpdated;

  const BudgetLoaded({
    required this.budgets,
    this.summary,
    this.exceededBudgets = const [],
    this.warningBudgets = const [],
    required this.lastUpdated,
  });

  /// Get budgets filtered by status
  List<Budget> get safeBudgets =>
      budgets.where((b) => b.status == BudgetStatus.safe).toList();

  List<Budget> get activeBudgets => budgets.where((b) => b.isActive).toList();

  /// Get total budgeted amount
  double get totalBudgeted =>
      budgets.fold(0.0, (sum, budget) => sum + budget.amount);

  /// Get total spent amount
  double get totalSpent =>
      budgets.fold(0.0, (sum, budget) => sum + budget.spentAmount);

  /// Get overall progress percentage
  double get overallProgress =>
      totalBudgeted > 0 ? totalSpent / totalBudgeted : 0.0;

  /// Check if any budget needs attention
  bool get hasAlerts => exceededBudgets.isNotEmpty || warningBudgets.isNotEmpty;

  /// Create a copy with updated fields
  BudgetLoaded copyWith({
    List<Budget>? budgets,
    BudgetSummary? summary,
    List<Budget>? exceededBudgets,
    List<Budget>? warningBudgets,
    DateTime? lastUpdated,
  }) {
    return BudgetLoaded(
      budgets: budgets ?? this.budgets,
      summary: summary ?? this.summary,
      exceededBudgets: exceededBudgets ?? this.exceededBudgets,
      warningBudgets: warningBudgets ?? this.warningBudgets,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    budgets,
    summary,
    exceededBudgets,
    warningBudgets,
    lastUpdated,
  ];
}

/// State when a single budget is loaded (for detail view).
class BudgetDetailLoaded extends BudgetState {
  final Budget budget;
  final BudgetCheckResult? status;

  const BudgetDetailLoaded({required this.budget, this.status});

  @override
  List<Object?> get props => [budget, status];
}

// ═══════════════════════════════════════════════════════════════════════════
// OPERATION STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when a budget is being created/updated/deleted.
class BudgetOperationInProgress extends BudgetState {
  final BudgetOperationType operation;
  final String? budgetId;

  const BudgetOperationInProgress({required this.operation, this.budgetId});

  @override
  List<Object?> get props => [operation, budgetId];
}

/// State when a budget operation succeeds.
class BudgetOperationSuccess extends BudgetState {
  final BudgetOperationType operation;
  final Budget? budget;
  final String message;

  const BudgetOperationSuccess({
    required this.operation,
    this.budget,
    required this.message,
  });

  @override
  List<Object?> get props => [operation, budget, message];
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when an error occurs.
class BudgetError extends BudgetState {
  final BudgetErrorType errorType;
  final String message;
  final String? code;

  const BudgetError({
    required this.errorType,
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [errorType, message, code];
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Types of budget operations.
enum BudgetOperationType {
  create,
  update,
  delete,
  resetPeriod,
  rollover,
  recalculate,
}

/// Types of budget errors.
enum BudgetErrorType {
  loadFailed,
  createFailed,
  updateFailed,
  deleteFailed,
  validationError,
  categoryAlreadyHasBudget,
  budgetNotFound,
  networkError,
  unknown,
}

/// Extension for user-friendly error messages.
extension BudgetErrorTypeExtension on BudgetErrorType {
  String get defaultMessage {
    switch (this) {
      case BudgetErrorType.loadFailed:
        return 'Failed to load budgets. Please try again.';
      case BudgetErrorType.createFailed:
        return 'Failed to create budget. Please try again.';
      case BudgetErrorType.updateFailed:
        return 'Failed to update budget. Please try again.';
      case BudgetErrorType.deleteFailed:
        return 'Failed to delete budget. Please try again.';
      case BudgetErrorType.validationError:
        return 'Please check your input and try again.';
      case BudgetErrorType.categoryAlreadyHasBudget:
        return 'This category already has a budget.';
      case BudgetErrorType.budgetNotFound:
        return 'Budget not found.';
      case BudgetErrorType.networkError:
        return 'Network error. Please check your connection.';
      case BudgetErrorType.unknown:
        return 'An unexpected error occurred.';
    }
  }
}

/// Extension for operation success messages.
extension BudgetOperationTypeExtension on BudgetOperationType {
  String get successMessage {
    switch (this) {
      case BudgetOperationType.create:
        return 'Budget created successfully!';
      case BudgetOperationType.update:
        return 'Budget updated successfully!';
      case BudgetOperationType.delete:
        return 'Budget deleted successfully!';
      case BudgetOperationType.resetPeriod:
        return 'Budget period reset successfully!';
      case BudgetOperationType.rollover:
        return 'Budget rolled over successfully!';
      case BudgetOperationType.recalculate:
        return 'Budget recalculated successfully!';
    }
  }
}
