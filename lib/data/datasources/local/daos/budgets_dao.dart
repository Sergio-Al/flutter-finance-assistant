import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'budgets_dao.g.dart';

/// Data Access Object for Budgets table.
@DriftAccessor(tables: [Budgets, Categories])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  /// Get all budgets for an account
  Future<List<BudgetEntry>> getAllBudgets(String? accountId) {
    if (accountId == null) {
      return select(budgets).get();
    }
    return (select(budgets)
          ..where((b) => b.accountId.equals(accountId) | b.accountId.isNull()))
        .get();
  }

  /// Get budget by ID
  Future<BudgetEntry?> getBudgetById(String id) {
    return (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
  }

  /// Get active budgets (current period)
  Future<List<BudgetEntry>> getActiveBudgets(String? accountId) {
    final now = DateTime.now();
    return (select(budgets)
          ..where((b) =>
              (accountId == null
                  ? const Constant(true)
                  : (b.accountId.equals(accountId) | b.accountId.isNull())) &
              b.startDate.isSmallerOrEqualValue(now) &
              b.endDate.isBiggerOrEqualValue(now)))
        .get();
  }

  /// Get budget by category
  Future<BudgetEntry?> getBudgetByCategory(
    String categoryId, {
    String? accountId,
  }) {
    final now = DateTime.now();
    return (select(budgets)
          ..where((b) =>
              b.categoryId.equals(categoryId) &
              (accountId == null
                  ? const Constant(true)
                  : (b.accountId.equals(accountId) | b.accountId.isNull())) &
              b.startDate.isSmallerOrEqualValue(now) &
              b.endDate.isBiggerOrEqualValue(now)))
        .getSingleOrNull();
  }

  /// Watch all budgets (reactive stream)
  Stream<List<BudgetEntry>> watchAllBudgets(String? accountId) {
    if (accountId == null) {
      return select(budgets).watch();
    }
    return (select(budgets)
          ..where((b) => b.accountId.equals(accountId) | b.accountId.isNull()))
        .watch();
  }

  /// Watch active budgets
  Stream<List<BudgetEntry>> watchActiveBudgets(String? accountId) {
    final now = DateTime.now();
    return (select(budgets)
          ..where((b) =>
              (accountId == null
                  ? const Constant(true)
                  : (b.accountId.equals(accountId) | b.accountId.isNull())) &
              b.startDate.isSmallerOrEqualValue(now) &
              b.endDate.isBiggerOrEqualValue(now)))
        .watch();
  }

  /// Insert new budget
  Future<void> insertBudget(BudgetsCompanion budget) {
    return into(budgets).insert(budget);
  }

  /// Update budget
  Future<bool> updateBudget(BudgetsCompanion budget) {
    return (update(budgets)..where((b) => b.id.equals(budget.id.value)))
        .write(budget)
        .then((rows) => rows > 0);
  }

  /// Update spent amount
  Future<bool> updateSpentAmount(String id, double spentAmount) {
    return (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        spentAmount: Value(spentAmount),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Increment spent amount
  Future<bool> incrementSpentAmount(String id, double amount) async {
    final budget = await getBudgetById(id);
    if (budget == null) return false;

    return updateSpentAmount(id, budget.spentAmount + amount);
  }

  /// Reset spent amount (for new period)
  Future<bool> resetSpentAmount(String id) {
    return updateSpentAmount(id, 0.0);
  }

  /// Delete budget
  Future<int> deleteBudget(String id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  /// Get exceeded budgets
  Future<List<BudgetEntry>> getExceededBudgets(String? accountId) async {
    final activeBudgets = await getActiveBudgets(accountId);
    return activeBudgets.where((b) => b.spentAmount > b.amount).toList();
  }

  /// Get warning budgets (above threshold)
  Future<List<BudgetEntry>> getWarningBudgets(String? accountId) async {
    final activeBudgets = await getActiveBudgets(accountId);
    return activeBudgets
        .where((b) =>
            b.spentAmount >= (b.amount * b.alertThreshold) &&
            b.spentAmount <= b.amount)
        .toList();
  }

  /// Get budgets pending sync
  Future<List<BudgetEntry>> getPendingSync() {
    return (select(budgets)..where((b) => b.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
