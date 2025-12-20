import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/recurring_rule.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';

/// Repository interface for recurring transaction rule operations.
///
/// Defines the contract for recurring rule data access.
/// Implementation will be in the data layer.
abstract class RecurringRuleRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all recurring rules for a user.
  Future<Either<Failure, List<RecurringRule>>> getRecurringRules(String userId);

  /// Get recurring rule by ID.
  Future<Either<Failure, RecurringRule>> getRecurringRuleById(String ruleId);

  /// Create a new recurring rule.
  Future<Either<Failure, RecurringRule>> createRecurringRule(
    RecurringRule rule,
  );

  /// Update an existing recurring rule.
  Future<Either<Failure, RecurringRule>> updateRecurringRule(
    RecurringRule rule,
  );

  /// Delete a recurring rule.
  Future<Either<Failure, void>> deleteRecurringRule(String ruleId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get active recurring rules.
  Future<Either<Failure, List<RecurringRule>>> getActiveRules(String userId);

  /// Get inactive/paused recurring rules.
  Future<Either<Failure, List<RecurringRule>>> getInactiveRules(String userId);

  /// Get completed recurring rules.
  Future<Either<Failure, List<RecurringRule>>> getCompletedRules(String userId);

  /// Get rules by frequency.
  Future<Either<Failure, List<RecurringRule>>> getRulesByFrequency(
    String userId,
    RecurringFrequency frequency,
  );

  /// Get rules due today or earlier.
  Future<Either<Failure, List<RecurringRule>>> getDueRules(String userId);

  /// Get rules due within a date range.
  Future<Either<Failure, List<RecurringRule>>> getRulesDueInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Rule Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activate a recurring rule.
  Future<Either<Failure, RecurringRule>> activateRule(String ruleId);

  /// Deactivate/pause a recurring rule.
  Future<Either<Failure, RecurringRule>> deactivateRule(String ruleId);

  /// Skip the next occurrence.
  Future<Either<Failure, RecurringRule>> skipNextOccurrence(String ruleId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Processing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process a recurring rule (create transaction and update next date).
  Future<Either<Failure, Transaction>> processRule(String ruleId);

  /// Process all due rules.
  Future<Either<Failure, List<Transaction>>> processAllDueRules(String userId);

  /// Update the next occurrence date after processing.
  Future<Either<Failure, RecurringRule>> updateNextDate(String ruleId);

  /// Increment occurrence count.
  Future<Either<Failure, RecurringRule>> incrementOccurrenceCount(
    String ruleId,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Projections
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get projected transactions for upcoming period.
  Future<Either<Failure, List<ProjectedTransaction>>> getProjectedTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get total projected income for a period.
  Future<Either<Failure, double>> getProjectedIncome(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get total projected expenses for a period.
  Future<Either<Failure, double>> getProjectedExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of recurring rules for real-time updates.
  Stream<Either<Failure, List<RecurringRule>>> watchRecurringRules(
    String userId,
  );

  /// Stream of due rules for processing notifications.
  Stream<Either<Failure, List<RecurringRule>>> watchDueRules(String userId);
}

/// Represents a projected future transaction from recurring rules.
class ProjectedTransaction {
  final String recurringRuleId;
  final DateTime projectedDate;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? description;
  final bool isExpense;

  const ProjectedTransaction({
    required this.recurringRuleId,
    required this.projectedDate,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.description,
    required this.isExpense,
  });

  double get signedAmount => isExpense ? -amount : amount;
}
