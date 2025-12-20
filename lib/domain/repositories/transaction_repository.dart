import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';

/// Repository interface for transaction operations.
///
/// Defines the contract for financial transaction data access.
/// Implementation will be in the data layer.
abstract class TransactionRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all transactions for an account.
  Future<Either<Failure, List<Transaction>>> getTransactions(String accountId);

  /// Get transaction by ID.
  Future<Either<Failure, Transaction>> getTransactionById(String transactionId);

  /// Create a new transaction.
  Future<Either<Failure, Transaction>> createTransaction(
    Transaction transaction,
  );

  /// Update an existing transaction.
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  );

  /// Delete a transaction.
  Future<Either<Failure, void>> deleteTransaction(String transactionId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get transactions by type.
  Future<Either<Failure, List<Transaction>>> getTransactionsByType(
    String accountId,
    TransactionType type,
  );

  /// Get transactions by category.
  Future<Either<Failure, List<Transaction>>> getTransactionsByCategory(
    String accountId,
    String categoryId,
  );

  /// Get transactions within a date range.
  Future<Either<Failure, List<Transaction>>> getTransactionsByDateRange(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get transactions for a specific month.
  Future<Either<Failure, List<Transaction>>> getTransactionsByMonth(
    String accountId,
    int year,
    int month,
  );

  /// Get recent transactions.
  Future<Either<Failure, List<Transaction>>> getRecentTransactions(
    String accountId, {
    int limit = 10,
  });

  /// Get all transactions across all accounts for a user.
  Future<Either<Failure, List<Transaction>>> getAllUserTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Search & Filter
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search transactions by description or tags.
  Future<Either<Failure, List<Transaction>>> searchTransactions(
    String accountId,
    String query,
  );

  /// Get transactions with filters.
  Future<Either<Failure, List<Transaction>>> getFilteredTransactions({
    required String accountId,
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    int? limit,
    int? offset,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Aggregations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total spent in a period.
  Future<Either<Failure, double>> getTotalSpent(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get total income in a period.
  Future<Either<Failure, double>> getTotalIncome(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get spending by category for a period.
  Future<Either<Failure, Map<String, double>>> getSpendingByCategory(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get daily spending totals for a period.
  Future<Either<Failure, Map<DateTime, double>>> getDailySpending(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get monthly spending totals for a year.
  Future<Either<Failure, Map<int, double>>> getMonthlySpending(
    String accountId,
    int year,
  );

  /// Get transaction count by category.
  Future<Either<Failure, Map<String, int>>> getTransactionCountByCategory(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Recurring Transactions
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get recurring transactions.
  Future<Either<Failure, List<Transaction>>> getRecurringTransactions(
    String accountId,
  );

  /// Get transactions by recurring rule ID.
  Future<Either<Failure, List<Transaction>>> getTransactionsByRecurringRule(
    String recurringId,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of transactions for real-time updates.
  Stream<Either<Failure, List<Transaction>>> watchTransactions(String accountId);

  /// Stream of recent transactions.
  Stream<Either<Failure, List<Transaction>>> watchRecentTransactions(
    String accountId, {
    int limit = 10,
  });
}
