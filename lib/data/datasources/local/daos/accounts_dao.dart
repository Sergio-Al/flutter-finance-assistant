import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'accounts_dao.g.dart';

/// Data Access Object for Accounts table.
@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  /// Get all accounts for a user
  Future<List<AccountEntry>> getAllAccounts(String userId) {
    return (select(accounts)..where((a) => a.userId.equals(userId))).get();
  }

  /// Get all active accounts for a user
  Future<List<AccountEntry>> getActiveAccounts(String userId) {
    return (select(accounts)
          ..where((a) => a.userId.equals(userId) & a.isActive.equals(true)))
        .get();
  }

  /// Get account by ID
  Future<AccountEntry?> getAccountById(String id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  /// Watch all accounts (reactive stream)
  Stream<List<AccountEntry>> watchAllAccounts(String userId) {
    return (select(accounts)..where((a) => a.userId.equals(userId))).watch();
  }

  /// Watch active accounts (reactive stream)
  Stream<List<AccountEntry>> watchActiveAccounts(String userId) {
    return (select(accounts)
          ..where((a) => a.userId.equals(userId) & a.isActive.equals(true))
          ..orderBy([(a) => OrderingTerm.asc(a.name)]))
        .watch();
  }

  /// Insert new account
  Future<void> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  /// Update account
  Future<bool> updateAccount(AccountsCompanion account) {
    return (update(accounts)..where((a) => a.id.equals(account.id.value)))
        .write(account)
        .then((rows) => rows > 0);
  }

  /// Update account balance
  Future<bool> updateBalance(String id, double newBalance) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        balance: Value(newBalance),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Adjust account balance by amount (add/subtract)
  Future<bool> adjustBalance(String id, double adjustment) async {
    final account = await getAccountById(id);
    if (account == null) return false;

    return updateBalance(id, account.balance + adjustment);
  }

  /// Soft delete account (set inactive)
  Future<bool> deactivateAccount(String id) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Hard delete account
  Future<int> deleteAccount(String id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  /// Get total balance across all active accounts
  Future<double> getTotalBalance(String userId) async {
    final result = await (select(accounts)
          ..where((a) => a.userId.equals(userId) & a.isActive.equals(true)))
        .get();
    return result.fold<double>(0.0, (sum, acc) => sum + acc.balance);
  }

  /// Get accounts by type
  Future<List<AccountEntry>> getAccountsByType(String userId, String type) {
    return (select(accounts)
          ..where((a) => a.userId.equals(userId) & a.type.equals(type)))
        .get();
  }

  /// Get accounts pending sync
  Future<List<AccountEntry>> getPendingSync() {
    return (select(accounts)..where((a) => a.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
