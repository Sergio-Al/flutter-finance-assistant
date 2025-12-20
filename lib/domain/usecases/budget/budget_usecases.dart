/// Barrel export for all budget-related use cases.
///
/// Import this file to access all budget use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/budget/budget_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### CRUD Operations
/// - [CreateBudgetUseCase] - Create a new budget
/// - [UpdateBudgetUseCase] - Update budget details
/// - [DeleteBudgetUseCase] - Delete a budget
///
/// ### Query Operations
/// - [GetBudgetsUseCase] - Get all budgets for a user
/// - [GetActiveBudgetsUseCase] - Get only active budgets
/// - [GetBudgetByCategoryUseCase] - Get budget for a specific category
/// - [GetBudgetsByPeriodUseCase] - Get budgets by period type
/// - [GetBudgetsWithRelationsUseCase] - Get budgets with composed relations
///
/// ### Budget Status
/// - [GetExceededBudgetsUseCase] - Get budgets that are exceeded
/// - [GetWarningBudgetsUseCase] - Get budgets at warning level
/// - [CheckBudgetStatusUseCase] - Check detailed status of a budget
///
/// ### Spending Management
/// - [AddSpendingToBudgetUseCase] - Add spending to a budget
/// - [SubtractSpendingFromBudgetUseCase] - Subtract spending from a budget
/// - [RecalculateBudgetUseCase] - Recalculate budget from transactions
///
/// ### Aggregations & History
/// - [GetBudgetSummaryUseCase] - Get overall budget summary
/// - [GetBudgetHistoryUseCase] - Get past budget periods
///
/// ### Period Management
/// - [ResetBudgetPeriodUseCase] - Reset budget for new period
/// - [RolloverBudgetUseCase] - Roll over unused amount
///
/// ### Real-time Streams
/// - [WatchBudgetsUseCase] - Stream all budgets
/// - [WatchBudgetUseCase] - Stream single budget
/// - [WatchExceededBudgetsUseCase] - Stream exceeded budgets for alerts
/// - [WatchBudgetsWithRelationsUseCase] - Stream budgets with composed relations
library;

export 'check_budget_status.dart';
export 'create_budget.dart';
export 'get_budget_summary.dart';
export 'get_budgets.dart';
export 'get_budgets_with_relations.dart';
export 'update_budget.dart';
export 'watch_budgets.dart';
