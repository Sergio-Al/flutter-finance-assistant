import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'users_dao.g.dart';

/// Data Access Object for Users table.
@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  /// Get user by ID
  Future<UserEntry?> getUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  /// Watch user by ID (reactive stream)
  Stream<UserEntry?> watchUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id))).watchSingleOrNull();
  }

  /// Insert or update user (upsert)
  Future<void> upsertUser(UsersCompanion user) {
    return into(users).insertOnConflictUpdate(user);
  }

  /// Update user preferences
  Future<bool> updatePreferences({
    required String userId,
    String? preferredCurrency,
    bool? biometricEnabled,
    String? themePreference,
  }) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        preferredCurrency: preferredCurrency != null
            ? Value(preferredCurrency)
            : const Value.absent(),
        biometricEnabled: biometricEnabled != null
            ? Value(biometricEnabled)
            : const Value.absent(),
        themePreference: themePreference != null
            ? Value(themePreference)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  /// Update sync timestamp
  Future<bool> updateSyncedAt(String userId) {
    return (update(users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(syncedAt: Value(DateTime.now())),
    ).then((rows) => rows > 0);
  }

  /// Delete user
  Future<int> deleteUser(String id) {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }
}
