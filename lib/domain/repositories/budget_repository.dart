import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';

/// Repository interface for budget operations.
///
/// Defines the contract for budget data access.
/// Implementation will be in the data layer.
abstract class BudgetRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all budgets for a user.
  Future<Either<Failure, List<Budget>>> getBudgets(String userId);

  /// Get budget by ID.
  Future<Either<Failure, Budget>> getBudgetById(String budgetId);

  /// Get budget for a specific category.
  Future<Either<Failure, Budget?>> getBudgetByCategory(
    String userId,
    String categoryId,
  );

  /// Create a new budget.
  Future<Either<Failure, Budget>> createBudget(Budget budget);

  /// Update an existing budget.
  Future<Either<Failure, Budget>> updateBudget(Budget budget);

  /// Delete a budget.
  Future<Either<Failure, void>> deleteBudget(String budgetId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get active budgets (within current period).
  Future<Either<Failure, List<Budget>>> getActiveBudgets(String userId);

  /// Get budgets by period type.
  Future<Either<Failure, List<Budget>>> getBudgetsByPeriod(
    String userId,
    BudgetPeriod period,
  );

  /// Get budgets for a specific account.
  Future<Either<Failure, List<Budget>>> getBudgetsByAccount(String accountId);

  /// Get budgets that are exceeded.
  Future<Either<Failure, List<Budget>>> getExceededBudgets(String userId);

  /// Get budgets at warning level.
  Future<Either<Failure, List<Budget>>> getWarningBudgets(String userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Spending Updates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update spent amount for a budget.
  Future<Either<Failure, Budget>> updateSpentAmount(
    String budgetId,
    double spentAmount,
  );

  /// Add to spent amount (increment).
  Future<Either<Failure, Budget>> addSpending(
    String budgetId,
    double amount,
  );

  /// Subtract from spent amount (decrement).
  Future<Either<Failure, Budget>> subtractSpending(
    String budgetId,
    double amount,
  );

  /// Recalculate spent amount from transactions.
  Future<Either<Failure, Budget>> recalculateSpentAmount(String budgetId);

  /// Recalculate all budgets for a user.
  Future<Either<Failure, List<Budget>>> recalculateAllBudgets(String userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Period Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset budget for new period.
  Future<Either<Failure, Budget>> resetBudgetPeriod(String budgetId);

  /// Roll over unused amount to next period.
  Future<Either<Failure, Budget>> rolloverBudget(String budgetId);

  /// Get budget history (past periods).
  Future<Either<Failure, List<BudgetHistory>>> getBudgetHistory(
    String budgetId, {
    int limit = 12,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Aggregations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total budgeted amount across all budgets.
  Future<Either<Failure, double>> getTotalBudgetedAmount(String userId);

  /// Get total spent across all budgets.
  Future<Either<Failure, double>> getTotalSpentAmount(String userId);

  /// Get budget utilization summary.
  Future<Either<Failure, BudgetSummary>> getBudgetSummary(String userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of budgets for real-time updates.
  Stream<Either<Failure, List<Budget>>> watchBudgets(String userId);

  /// Stream of single budget changes.
  Stream<Either<Failure, Budget>> watchBudget(String budgetId);

  /// Stream of exceeded budgets for alerts.
  Stream<Either<Failure, List<Budget>>> watchExceededBudgets(String userId);
}

/// Historical budget record for a past period.
class BudgetHistory {
  final String budgetId;
  final double amount;
  final double spentAmount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  const BudgetHistory({
    required this.budgetId,
    required this.amount,
    required this.spentAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  double get utilizationPercent => amount > 0 ? spentAmount / amount : 0;
  double get remainingAmount => amount - spentAmount;
  bool get wasExceeded => spentAmount > amount;
}

/// Summary of all budgets for a user.
class BudgetSummary {
  final int totalBudgets;
  final int activeBudgets;
  final int exceededBudgets;
  final int warningBudgets;
  final double totalBudgeted;
  final double totalSpent;
  final double overallUtilization;

  const BudgetSummary({
    required this.totalBudgets,
    required this.activeBudgets,
    required this.exceededBudgets,
    required this.warningBudgets,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.overallUtilization,
  });

  double get remainingTotal => totalBudgeted - totalSpent;
  bool get isOnTrack => overallUtilization <= 0.8;
}
