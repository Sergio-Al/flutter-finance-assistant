import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'transactions_dao.g.dart';

/// Data Access Object for Transactions table.
@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  /// Get all transactions for a user (via account)
  Future<List<TransactionEntry>> getAllTransactions(String accountId) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transaction by ID
  Future<TransactionEntry?> getTransactionById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get transactions by date range
  Future<List<TransactionEntry>> getByDateRange(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by category
  Future<List<TransactionEntry>> getByCategory(
    String accountId,
    String categoryId,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) & t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by type (expense/income/transfer)
  Future<List<TransactionEntry>> getByType(String accountId, String type) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get recent transactions (limited)
  Future<List<TransactionEntry>> getRecentTransactions(
    String accountId, {
    int limit = 10,
  }) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  /// Watch all transactions (reactive stream)
  Stream<List<TransactionEntry>> watchAllTransactions(String accountId) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Watch recent transactions
  Stream<List<TransactionEntry>> watchRecentTransactions(
    String accountId, {
    int limit = 10,
  }) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  /// Search transactions by description
  Future<List<TransactionEntry>> search(String accountId, String query) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.description.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Insert new transaction
  Future<void> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  /// Update transaction
  Future<bool> updateTransaction(TransactionsCompanion transaction) {
    return (update(transactions)
          ..where((t) => t.id.equals(transaction.id.value)))
        .write(transaction)
        .then((rows) => rows > 0);
  }

  /// Delete transaction
  Future<int> deleteTransaction(String id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Get sum of amounts by type for an account
  Future<double> getSumByType(
    String accountId,
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.type.equals(type) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate)))
        .get();
    return result.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get sum by category for a date range
  Future<Map<String, double>> getSumByCategory(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate)))
        .get();

    final Map<String, double> sums = {};
    for (final t in result) {
      sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
    }
    return sums;
  }

  /// Get recurring transactions
  Future<List<TransactionEntry>> getRecurringTransactions(String accountId) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.equals(accountId) & t.isRecurring.equals(true)))
        .get();
  }

  /// Get transactions pending sync
  Future<List<TransactionEntry>> getPendingSync() {
    return (select(transactions)..where((t) => t.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }

  /// Get transactions for multiple accounts (for user-level queries)
  Future<List<TransactionEntry>> getForAccounts(
    List<String> accountIds,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(transactions)
          ..where((t) =>
              t.accountId.isIn(accountIds) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }
}
