import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/core/sync/sync_repository.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// Helper class to trigger sync operations when data changes.
///
/// Used by repositories to queue sync items when local data is modified.
/// Call [onCreate], [onUpdate], or [onDelete] after local database operations.
class SyncTrigger {
  final SyncRepository _syncRepository;
  final Logger _logger;
  final Uuid _uuid;

  /// Creates a [SyncTrigger] with required dependencies.
  SyncTrigger({
    required SyncRepository syncRepository,
    Logger? logger,
    Uuid? uuid,
  })  : _syncRepository = syncRepository,
        _logger = logger ?? Logger(),
        _uuid = uuid ?? const Uuid();

  /// Queue a sync operation for a newly created record.
  ///
  /// [tableName] - The table where the record was created.
  /// [recordId] - The ID of the new record.
  /// [data] - The complete record data as a map.
  Future<void> onCreate({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    _logger.d('SyncTrigger: onCreate - $tableName/$recordId');

    await _syncRepository.addToQueue(
      tableName: tableName,
      recordId: recordId,
      operation: SyncQueueTable.operationCreate,
      payload: _preparePayload(data),
    );
  }

  /// Queue a sync operation for an updated record.
  ///
  /// [tableName] - The table where the record was updated.
  /// [recordId] - The ID of the updated record.
  /// [data] - The updated record data as a map.
  Future<void> onUpdate({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    _logger.d('SyncTrigger: onUpdate - $tableName/$recordId');

    await _syncRepository.addToQueue(
      tableName: tableName,
      recordId: recordId,
      operation: SyncQueueTable.operationUpdate,
      payload: _preparePayload(data),
    );
  }

  /// Queue a sync operation for a deleted record.
  ///
  /// [tableName] - The table where the record was deleted.
  /// [recordId] - The ID of the deleted record.
  Future<void> onDelete({
    required String tableName,
    required String recordId,
  }) async {
    _logger.d('SyncTrigger: onDelete - $tableName/$recordId');

    await _syncRepository.addToQueue(
      tableName: tableName,
      recordId: recordId,
      operation: SyncQueueTable.operationDelete,
      payload: _preparePayload({
        'id': recordId,
        'deleted_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Prepare payload for sync queue.
  Map<String, dynamic> _preparePayload(Map<String, dynamic> data) {
    // Ensure required sync fields are present
    final payload = Map<String, dynamic>.from(data);

    // Add sync metadata
    payload['_sync_id'] = _uuid.v4();
    payload['_queued_at'] = DateTime.now().toIso8601String();

    return payload;
  }

  /// Generate a new UUID for records.
  String generateId() => _uuid.v4();
}

/// Mixin to add sync capabilities to repositories.
///
/// Usage:
/// ```dart
/// class TransactionRepositoryImpl extends TransactionRepository
///     with SyncCapable {
///   @override
///   SyncTrigger get syncTrigger => _syncTrigger;
///
///   Future<void> createTransaction(Transaction t) async {
///     await _localDataSource.insert(t);
///     await triggerSync(
///       tableName: TableNames.transactions,
///       recordId: t.id,
///       operation: SyncOperation.create,
///       data: t.toMap(),
///     );
///   }
/// }
/// ```
mixin SyncCapable {
  SyncTrigger get syncTrigger;

  /// Trigger a sync operation.
  Future<void> triggerSync({
    required String tableName,
    required String recordId,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    switch (operation) {
      case SyncOperation.create:
        await syncTrigger.onCreate(
          tableName: tableName,
          recordId: recordId,
          data: data,
        );
        break;
      case SyncOperation.update:
        await syncTrigger.onUpdate(
          tableName: tableName,
          recordId: recordId,
          data: data,
        );
        break;
      case SyncOperation.delete:
        await syncTrigger.onDelete(
          tableName: tableName,
          recordId: recordId,
        );
        break;
    }
  }
}

/// Types of sync operations.
enum SyncOperation {
  create,
  update,
  delete,
}
