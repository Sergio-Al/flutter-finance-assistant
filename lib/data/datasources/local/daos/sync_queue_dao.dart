import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'sync_queue_dao.g.dart';

/// Data Access Object for SyncQueue table.
///
/// Manages the queue of operations pending synchronization with Firebase.
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Get all pending operations
  Future<List<SyncQueueEntry>> getPendingOperations() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get all operations (including failed)
  Future<List<SyncQueueEntry>> getAllOperations() {
    return (select(syncQueue)..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get failed operations
  Future<List<SyncQueueEntry>> getFailedOperations() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('failed'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get operations by table
  Future<List<SyncQueueEntry>> getOperationsByTable(String tableName) {
    if (tableName.isEmpty) {
      return getAllOperations();
    }

    return (select(syncQueue)
          ..where((q) => q.tableNameColumn.equals(tableName))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Watch pending operations count
  Stream<int> watchPendingCount() {
    return (select(syncQueue)..where((q) => q.status.equals('pending')))
        .watch()
        .map((list) => list.length);
  }

  /// Watch all pending operations
  Stream<List<SyncQueueEntry>> watchPendingOperations() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .watch();
  }

  /// Enqueue a create operation
  Future<int> enqueueCreate({
    required String tableName,
    required String recordId,
    required String data,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        tableNameColumn: tableName,
        recordId: recordId,
        operation: 'create',
        data: Value(data),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Enqueue an update operation
  Future<int> enqueueUpdate({
    required String tableName,
    required String recordId,
    required String data,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        tableNameColumn: tableName,
        recordId: recordId,
        operation: 'update',
        data: Value(data),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Enqueue a delete operation
  Future<int> enqueueDelete({
    required String tableName,
    required String recordId,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        tableNameColumn: tableName,
        recordId: recordId,
        operation: 'delete',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Mark operation as processing
  Future<bool> markProcessing(int id) {
    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      const SyncQueueCompanion(status: Value('processing')),
    ).then((rows) => rows > 0);
  }

  /// Mark operation as failed
  Future<bool> markFailed(int id, String error) async {
    final entry = await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return false;

    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion(
        status: const Value('failed'),
        retryCount: Value(entry.retryCount + 1),
        lastError: Value(error),
      ),
    ).then((rows) => rows > 0);
  }

  /// Reset failed operation to pending (for retry)
  Future<bool> resetToPending(int id) {
    return (update(syncQueue)..where((q) => q.id.equals(id))).write(
      const SyncQueueCompanion(
        status: Value('pending'),
        lastError: Value(null),
      ),
    ).then((rows) => rows > 0);
  }

  /// Reset all failed operations to pending
  Future<int> resetAllFailed() {
    return (update(syncQueue)..where((q) => q.status.equals('failed'))).write(
      const SyncQueueCompanion(
        status: Value('pending'),
        lastError: Value(null),
      ),
    );
  }

  /// Remove completed operation
  Future<int> removeOperation(int id) {
    return (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Remove all completed operations for a record
  Future<int> removeOperationsForRecord(String tableName, String recordId) {
    return (delete(syncQueue)
          ..where((q) =>
              q.tableNameColumn.equals(tableName) & q.recordId.equals(recordId)))
        .go();
  }

  /// Clear all completed/synced operations
  Future<int> clearCompleted() {
    // Operations are removed after successful sync, this clears any stragglers
    return (delete(syncQueue)..where((q) => q.status.equals('synced'))).go();
  }

  /// Clear all operations (use with caution!)
  Future<int> clearAll() {
    return delete(syncQueue).go();
  }

  /// Get count of pending operations
  Future<int> getPendingCount() async {
    final result = await getPendingOperations();
    print('Pending operations count: ${result.length}');
    return result.length;
  }

  /// Get count of failed operations
  Future<int> getFailedCount() async {
    final result = await getFailedOperations();
    return result.length;
  }

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Get next batch of operations to process
  Future<List<SyncQueueEntry>> getNextBatch({int batchSize = 50}) {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)])
          ..limit(batchSize))
        .get();
  }
}
