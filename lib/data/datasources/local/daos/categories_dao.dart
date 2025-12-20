import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'categories_dao.g.dart';

/// Data Access Object for Categories table.
@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Get all categories (system + user)
  Future<List<CategoryEntry>> getAllCategories(String? userId) {
    return (select(categories)
          ..where((c) => c.userId.isNull() | c.userId.equals(userId ?? '')))
        .get();
  }

  /// Get system categories only
  Future<List<CategoryEntry>> getSystemCategories() {
    return (select(categories)..where((c) => c.isSystem.equals(true))).get();
  }

  /// Get user-created categories only
  Future<List<CategoryEntry>> getUserCategories(String userId) {
    return (select(categories)
          ..where((c) => c.userId.equals(userId) & c.isSystem.equals(false)))
        .get();
  }

  /// Get categories by type (expense/income)
  Future<List<CategoryEntry>> getByType(String? userId, String type) {
    return (select(categories)
          ..where((c) =>
              c.type.equals(type) &
              (c.userId.isNull() | c.userId.equals(userId ?? '')))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Get expense categories
  Future<List<CategoryEntry>> getExpenseCategories(String? userId) {
    return getByType(userId, 'expense');
  }

  /// Get income categories
  Future<List<CategoryEntry>> getIncomeCategories(String? userId) {
    return getByType(userId, 'income');
  }

  /// Get category by ID
  Future<CategoryEntry?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch all categories (reactive stream)
  Stream<List<CategoryEntry>> watchAllCategories(String? userId) {
    return (select(categories)
          ..where((c) => c.userId.isNull() | c.userId.equals(userId ?? ''))
          ..orderBy([
            (c) => OrderingTerm.asc(c.type),
            (c) => OrderingTerm.asc(c.name),
          ]))
        .watch();
  }

  /// Watch categories by type
  Stream<List<CategoryEntry>> watchByType(String? userId, String type) {
    return (select(categories)
          ..where((c) =>
              c.type.equals(type) &
              (c.userId.isNull() | c.userId.equals(userId ?? '')))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  /// Get subcategories of a parent
  Future<List<CategoryEntry>> getSubcategories(String parentId) {
    return (select(categories)..where((c) => c.parentId.equals(parentId)))
        .get();
  }

  /// Insert new category
  Future<void> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// Insert multiple categories (batch)
  Future<void> insertCategories(List<CategoriesCompanion> categoryList) {
    return batch((batch) {
      batch.insertAll(categories, categoryList);
    });
  }

  /// Update category
  Future<bool> updateCategory(CategoriesCompanion category) {
    return (update(categories)..where((c) => c.id.equals(category.id.value)))
        .write(category)
        .then((rows) => rows > 0);
  }

  /// Delete category (only user categories)
  Future<int> deleteCategory(String id) {
    return (delete(categories)
          ..where((c) => c.id.equals(id) & c.isSystem.equals(false)))
        .go();
  }

  /// Get categories pending sync
  Future<List<CategoryEntry>> getPendingSync() {
    return (select(categories)..where((c) => c.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
