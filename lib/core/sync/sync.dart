/// Sync module for offline-first data synchronization.
///
/// This module provides:
/// - [SyncManager] - Central coordination of sync operations
/// - [ConnectivityService] - Network status monitoring
/// - [SyncQueueProcessor] - Processing queued sync items
/// - [SyncStatusNotifier] - UI state notifications
/// - [SyncTrigger] - Queueing changes for sync
/// - [ConflictResolver] - Handling sync conflicts
/// - [SyncRepository] - Interface for sync data operations
///
/// Example usage:
/// ```dart
/// // Initialize sync manager
/// final syncManager = SyncManager(
///   connectivityService: connectivityService,
///   queueProcessor: queueProcessor,
///   statusNotifier: statusNotifier,
/// );
/// await syncManager.initialize();
///
/// // Listen for sync state changes
/// syncManager.syncStateStream.listen((state) {
///   print('Sync state: $state');
/// });
///
/// // Trigger manual sync
/// await syncManager.syncAll();
///
/// // In repositories, use SyncTrigger to queue changes
/// await syncTrigger.onCreate(
///   tableName: 'transactions',
///   recordId: transaction.id,
///   data: transaction.toMap(),
/// );
/// ```
library;

export 'conflict_resolver.dart';
export 'connectivity_service.dart';
export 'sync_manager.dart';
export 'sync_queue_processor.dart';
export 'sync_repository.dart';
export 'sync_status_notifier.dart';
export 'sync_trigger.dart';
