import 'package:flutter_finance_assistant/core/sync/sync_queue_processor.dart';

/// Abstract repository interface for sync operations.
///
/// Defines the contract for interacting with both local (Drift)
/// and remote (Firestore) data sources during synchronization.
/// Implementation will be in data layer.
abstract class SyncRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // Sync Queue Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get count of pending items in sync queue.
  Future<int> getPendingItemCount();

  /// Get count of failed items in sync queue.
  Future<int> getFailedItemCount();

  /// Get pending sync items, optionally limited.
  Future<List<SyncQueueItem>> getPendingItems({int? limit});

  /// Get sync items for a specific table.
  Future<List<SyncQueueItem>> getItemsByTable(String tableName);

  /// Mark a sync queue item as processed.
  Future<void> markItemProcessed(String itemId);

  /// Increment retry count for a failed item.
  Future<void> incrementRetryCount(String itemId, String errorMessage);

  /// Reset all failed items to pending for retry.
  Future<void> resetFailedItems();

  /// Clear all items from sync queue.
  Future<void> clearQueue();

  /// Add a new item to the sync queue.
  Future<void> addToQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote (Firestore) Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Push data to remote Firestore.
  Future<void> pushToRemote({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    required bool isNew,
  });

  /// Delete record from remote Firestore.
  Future<void> deleteFromRemote({
    required String tableName,
    required String recordId,
  });

  /// Fetch record from remote Firestore.
  Future<Map<String, dynamic>?> fetchFromRemote({
    required String tableName,
    required String recordId,
  });

  /// Check if remote record was modified after local update.
  Future<bool> checkRemoteConflict({
    required String tableName,
    required String recordId,
    required DateTime localUpdatedAt,
  });

  /// Pull all changes from remote since last sync.
  Future<List<Map<String, dynamic>>> pullChangesFromRemote({
    required String tableName,
    required DateTime? lastSyncTime,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Local (Drift) Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update local record with remote data.
  Future<void> updateLocal({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  });

  /// Delete local record.
  Future<void> deleteLocal({
    required String tableName,
    required String recordId,
  });

  /// Update sync status of a local record.
  Future<void> updateLocalSyncStatus({
    required String tableName,
    required String recordId,
    required String status,
  });

  /// Get all local records with pending sync status.
  Future<List<Map<String, dynamic>>> getLocalPendingRecords(String tableName);

  /// Get last sync timestamp for a table.
  Future<DateTime?> getLastSyncTime(String tableName);

  /// Update last sync timestamp for a table.
  Future<void> updateLastSyncTime(String tableName, DateTime time);
}
