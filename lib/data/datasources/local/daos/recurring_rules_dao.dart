import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'recurring_rules_dao.g.dart';

/// Data Access Object for RecurringRules table.
@DriftAccessor(tables: [RecurringRules, Transactions])
class RecurringRulesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRulesDaoMixin {
  RecurringRulesDao(super.db);

  /// Get all recurring rules
  Future<List<RecurringRuleEntry>> getAllRules() {
    return select(recurringRules).get();
  }

  /// Get rule by ID
  Future<RecurringRuleEntry?> getRuleById(String id) {
    return (select(recurringRules)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get rule by transaction ID
  Future<RecurringRuleEntry?> getRuleByTransactionId(String transactionId) {
    return (select(recurringRules)
          ..where((r) => r.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  /// Get active rules
  Future<List<RecurringRuleEntry>> getActiveRules() {
    return (select(recurringRules)..where((r) => r.isActive.equals(true)))
        .get();
  }

  /// Get due rules (next date is past or today)
  Future<List<RecurringRuleEntry>> getDueRules() {
    final now = DateTime.now();
    return (select(recurringRules)
          ..where((r) =>
              r.isActive.equals(true) & r.nextDate.isSmallerOrEqualValue(now)))
        .get();
  }

  /// Watch due rules
  Stream<List<RecurringRuleEntry>> watchDueRules() {
    final now = DateTime.now();
    return (select(recurringRules)
          ..where((r) =>
              r.isActive.equals(true) & r.nextDate.isSmallerOrEqualValue(now)))
        .watch();
  }

  /// Watch active rules
  Stream<List<RecurringRuleEntry>> watchActiveRules() {
    return (select(recurringRules)
          ..where((r) => r.isActive.equals(true))
          ..orderBy([(r) => OrderingTerm.asc(r.nextDate)]))
        .watch();
  }

  /// Insert new rule
  Future<void> insertRule(RecurringRulesCompanion rule) {
    return into(recurringRules).insert(rule);
  }

  /// Update rule
  Future<bool> updateRule(RecurringRulesCompanion rule) {
    return (update(recurringRules)..where((r) => r.id.equals(rule.id.value)))
        .write(rule)
        .then((rows) => rows > 0);
  }

  /// Update next date after processing
  Future<bool> updateNextDate(String id, DateTime nextDate) {
    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        nextDate: Value(nextDate),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Increment occurrence count
  Future<bool> incrementOccurrenceCount(String id) async {
    final rule = await getRuleById(id);
    if (rule == null) return false;

    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        occurrenceCount: Value(rule.occurrenceCount + 1),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Deactivate rule
  Future<bool> deactivateRule(String id) {
    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Activate rule
  Future<bool> activateRule(String id) {
    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Delete rule
  Future<int> deleteRule(String id) {
    return (delete(recurringRules)..where((r) => r.id.equals(id))).go();
  }

  /// Get rules pending sync
  Future<List<RecurringRuleEntry>> getPendingSync() {
    return (select(recurringRules)
          ..where((r) => r.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
