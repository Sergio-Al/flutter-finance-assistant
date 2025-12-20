import 'dart:convert';

import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/core/sync/sync_repository.dart';
import 'package:logger/logger.dart';

/// Processes items from the sync queue and synchronizes with remote.
///
/// Handles batch processing, retry logic, and error tracking for
/// individual sync operations.
class SyncQueueProcessor {
  final SyncRepository _syncRepository;
  final Logger _logger;

  /// Creates a [SyncQueueProcessor] with required dependencies.
  SyncQueueProcessor({
    required SyncRepository syncRepository,
    Logger? logger,
  })  : _syncRepository = syncRepository,
        _logger = logger ?? Logger();

  /// Get count of pending sync items.
  Future<int> getPendingCount() async {
    return _syncRepository.getPendingItemCount();
  }

  /// Get count of failed sync items.
  Future<int> getFailedCount() async {
    return _syncRepository.getFailedItemCount();
  }

  /// Get next batch of items to sync.
  Future<List<SyncQueueItem>> getNextBatch(int batchSize) async {
    return _syncRepository.getPendingItems(limit: batchSize);
  }

  /// Process a single sync queue item.
  ///
  /// Returns `true` if processed successfully, `false` if failed.
  Future<bool> processItem(SyncQueueItem item) async {
    _logger.d(
      'SyncQueueProcessor: Processing item ${item.id} - '
      '${item.operation} on ${item.tableName}',
    );

    try {
      // Determine operation type and execute
      switch (item.operation) {
        case SyncQueueTable.operationCreate:
          await _processCreate(item);
          break;
        case SyncQueueTable.operationUpdate:
          await _processUpdate(item);
          break;
        case SyncQueueTable.operationDelete:
          await _processDelete(item);
          break;
        default:
          throw UnsupportedError('Unknown operation: ${item.operation}');
      }

      // Mark as processed successfully
      await _syncRepository.markItemProcessed(item.id);
      await _updateRecordSyncStatus(item, SyncStatus.synced);

      _logger.d('SyncQueueProcessor: Item ${item.id} processed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'SyncQueueProcessor: Failed to process item ${item.id}',
        error: e,
        stackTrace: stackTrace,
      );

      // Increment retry count and record error
      await _syncRepository.incrementRetryCount(
        item.id,
        e.toString(),
      );

      // Check if max retries exceeded
      if (item.retryCount + 1 >= DatabaseConfig.maxSyncRetries) {
        await _updateRecordSyncStatus(item, SyncStatus.failed);
      }

      return false;
    }
  }

  /// Process all items for a specific table.
  Future<void> processTableItems(String tableName) async {
    final items = await _syncRepository.getItemsByTable(tableName);

    for (final item in items) {
      await processItem(item);
    }
  }

  /// Reset all failed items to pending for retry.
  Future<void> resetFailedItems() async {
    _logger.i('SyncQueueProcessor: Resetting failed items...');
    await _syncRepository.resetFailedItems();
  }

  /// Clear all items from the sync queue.
  Future<void> clearQueue() async {
    _logger.w('SyncQueueProcessor: Clearing sync queue');
    await _syncRepository.clearQueue();
  }

  /// Process a create operation.
  Future<void> _processCreate(SyncQueueItem item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    await _syncRepository.pushToRemote(
      tableName: item.tableName,
      recordId: item.recordId,
      data: payload,
      isNew: true,
    );
  }

  /// Process an update operation.
  Future<void> _processUpdate(SyncQueueItem item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;

    // Check for conflicts before updating
    final hasConflict = await _syncRepository.checkRemoteConflict(
      tableName: item.tableName,
      recordId: item.recordId,
      localUpdatedAt: DateTime.parse(payload['updated_at'] as String),
    );

    if (hasConflict) {
      _logger.w(
        'SyncQueueProcessor: Conflict detected for ${item.tableName}/${item.recordId}',
      );
      await _handleConflict(item);
      return;
    }

    await _syncRepository.pushToRemote(
      tableName: item.tableName,
      recordId: item.recordId,
      data: payload,
      isNew: false,
    );
  }

  /// Process a delete operation.
  Future<void> _processDelete(SyncQueueItem item) async {
    await _syncRepository.deleteFromRemote(
      tableName: item.tableName,
      recordId: item.recordId,
    );
  }

  /// Handle sync conflict between local and remote.
  Future<void> _handleConflict(SyncQueueItem item) async {
    // Get remote version
    final remoteData = await _syncRepository.fetchFromRemote(
      tableName: item.tableName,
      recordId: item.recordId,
    );

    if (remoteData == null) {
      // Remote was deleted, delete locally too
      await _syncRepository.deleteLocal(
        tableName: item.tableName,
        recordId: item.recordId,
      );
      await _syncRepository.markItemProcessed(item.id);
      return;
    }

    // Default strategy: Remote wins (last write wins)
    // Can be extended for more sophisticated conflict resolution
    final localPayload = jsonDecode(item.payload) as Map<String, dynamic>;
    final localUpdatedAt = DateTime.parse(localPayload['updated_at'] as String);
    final remoteUpdatedAt = DateTime.parse(remoteData['updated_at'] as String);

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      // Remote is newer, update local
      await _syncRepository.updateLocal(
        tableName: item.tableName,
        recordId: item.recordId,
        data: remoteData,
      );
      await _syncRepository.markItemProcessed(item.id);
      _logger.i('SyncQueueProcessor: Conflict resolved - Remote wins');
    } else {
      // Local is newer, push to remote
      await _syncRepository.pushToRemote(
        tableName: item.tableName,
        recordId: item.recordId,
        data: localPayload,
        isNew: false,
      );
      await _syncRepository.markItemProcessed(item.id);
      _logger.i('SyncQueueProcessor: Conflict resolved - Local wins');
    }
  }

  /// Update the sync status of the original record.
  Future<void> _updateRecordSyncStatus(
    SyncQueueItem item,
    String status,
  ) async {
    await _syncRepository.updateLocalSyncStatus(
      tableName: item.tableName,
      recordId: item.recordId,
      status: status,
    );
  }
}

/// Represents an item in the sync queue.
class SyncQueueItem {
  final String id;
  final String tableName;
  final String recordId;
  final String operation;
  final String payload;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? processedAt;

  const SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
    this.processedAt,
  });

  /// Create from database map.
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map[SyncQueueTable.colId] as String,
      tableName: map[SyncQueueTable.colTableName] as String,
      recordId: map[SyncQueueTable.colRecordId] as String,
      operation: map[SyncQueueTable.colOperation] as String,
      payload: map[SyncQueueTable.colPayload] as String,
      retryCount: map[SyncQueueTable.colRetryCount] as int? ?? 0,
      lastError: map[SyncQueueTable.colLastError] as String?,
      createdAt: DateTime.parse(map[SyncQueueTable.colCreatedAt] as String),
      processedAt: map[SyncQueueTable.colProcessedAt] != null
          ? DateTime.parse(map[SyncQueueTable.colProcessedAt] as String)
          : null,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      SyncQueueTable.colId: id,
      SyncQueueTable.colTableName: tableName,
      SyncQueueTable.colRecordId: recordId,
      SyncQueueTable.colOperation: operation,
      SyncQueueTable.colPayload: payload,
      SyncQueueTable.colRetryCount: retryCount,
      SyncQueueTable.colLastError: lastError,
      SyncQueueTable.colCreatedAt: createdAt.toIso8601String(),
      SyncQueueTable.colProcessedAt: processedAt?.toIso8601String(),
    };
  }
}
