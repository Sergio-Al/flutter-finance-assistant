import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/budget.dart';

/// Base class for all budget events.
abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// LOAD EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to load all budgets for the current user.
class BudgetLoadRequested extends BudgetEvent {
  final String userId;

  const BudgetLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to load only active budgets.
class BudgetLoadActiveRequested extends BudgetEvent {
  final String userId;

  const BudgetLoadActiveRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to load budget summary.
class BudgetSummaryRequested extends BudgetEvent {
  final String userId;

  const BudgetSummaryRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to start watching budgets in real-time.
class BudgetWatchRequested extends BudgetEvent {
  final String userId;

  const BudgetWatchRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ═══════════════════════════════════════════════════════════════════════════
// CRUD EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to create a new budget.
class BudgetCreateRequested extends BudgetEvent {
  final String? accountId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime? startDate;
  final bool rollover;
  final bool alertsEnabled;
  final double alertThreshold;

  const BudgetCreateRequested({
    this.accountId,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.startDate,
    this.rollover = false,
    this.alertsEnabled = true,
    this.alertThreshold = 0.80,
  });

  @override
  List<Object?> get props => [
    accountId,
    categoryId,
    amount,
    period,
    startDate,
    rollover,
    alertsEnabled,
    alertThreshold,
  ];
}

/// Event to update an existing budget.
class BudgetUpdateRequested extends BudgetEvent {
  final Budget budget;

  const BudgetUpdateRequested({required this.budget});

  @override
  List<Object?> get props => [budget];
}

/// Event to delete a budget.
class BudgetDeleteRequested extends BudgetEvent {
  final String budgetId;

  const BudgetDeleteRequested({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to check status of a specific budget.
class BudgetCheckStatusRequested extends BudgetEvent {
  final String budgetId;

  const BudgetCheckStatusRequested({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Event to load exceeded budgets for alerts.
class BudgetLoadExceededRequested extends BudgetEvent {
  final String userId;

  const BudgetLoadExceededRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to load budgets at warning level.
class BudgetLoadWarningRequested extends BudgetEvent {
  final String userId;

  const BudgetLoadWarningRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ═══════════════════════════════════════════════════════════════════════════
// SPENDING EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event when spending is added to a budget (from new transaction).
class BudgetSpendingAdded extends BudgetEvent {
  final String budgetId;
  final double amount;

  const BudgetSpendingAdded({required this.budgetId, required this.amount});

  @override
  List<Object?> get props => [budgetId, amount];
}

/// Event when spending is removed from a budget (transaction deleted).
class BudgetSpendingRemoved extends BudgetEvent {
  final String budgetId;
  final double amount;

  const BudgetSpendingRemoved({required this.budgetId, required this.amount});

  @override
  List<Object?> get props => [budgetId, amount];
}

/// Event to recalculate budget from transactions.
class BudgetRecalculateRequested extends BudgetEvent {
  final String budgetId;

  const BudgetRecalculateRequested({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

// ═══════════════════════════════════════════════════════════════════════════
// PERIOD EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to reset budget for a new period.
class BudgetResetPeriodRequested extends BudgetEvent {
  final String budgetId;

  const BudgetResetPeriodRequested({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

/// Event to rollover unused budget amount.
class BudgetRolloverRequested extends BudgetEvent {
  final String budgetId;

  const BudgetRolloverRequested({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERNAL EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Internal event when budgets change from stream.
class BudgetDataChanged extends BudgetEvent {
  final List<Budget> budgets;

  const BudgetDataChanged({required this.budgets});

  @override
  List<Object?> get props => [budgets];
}

/// Event to clear any error state.
class BudgetErrorCleared extends BudgetEvent {
  const BudgetErrorCleared();
}
