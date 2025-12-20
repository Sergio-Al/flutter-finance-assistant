import 'dart:async';

import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/core/sync/connectivity_service.dart';
import 'package:flutter_finance_assistant/core/sync/sync_queue_processor.dart';
import 'package:flutter_finance_assistant/core/sync/sync_status_notifier.dart';
import 'package:logger/logger.dart';

/// Central manager for offline-first data synchronization.
///
/// Coordinates sync operations between local Drift database and Firebase
/// Firestore. Handles:
/// - Automatic sync when connectivity changes
/// - Manual sync triggers
/// - Conflict resolution
/// - Retry logic for failed operations
class SyncManager {
  final ConnectivityService _connectivityService;
  final SyncQueueProcessor _queueProcessor;
  final SyncStatusNotifier _statusNotifier;
  final Logger _logger;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  /// Creates a [SyncManager] with required dependencies.
  SyncManager({
    required ConnectivityService connectivityService,
    required SyncQueueProcessor queueProcessor,
    required SyncStatusNotifier statusNotifier,
    Logger? logger,
  })  : _connectivityService = connectivityService,
        _queueProcessor = queueProcessor,
        _statusNotifier = statusNotifier,
        _logger = logger ?? Logger();

  /// Current sync status stream for UI updates.
  Stream<SyncState> get syncStateStream => _statusNotifier.stateStream;

  /// Current sync state.
  SyncState get currentState => _statusNotifier.currentState;

  /// Whether a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Initialize the sync manager and start listening for connectivity changes.
  Future<void> initialize() async {
    _logger.i('SyncManager: Initializing...');

    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen(_handleConnectivityChange);

    // Start periodic sync (every 5 minutes when online)
    _startPeriodicSync();

    // Perform initial sync if online
    if (await _connectivityService.isConnected) {
      await syncAll();
    }

    _logger.i('SyncManager: Initialization complete');
  }

  /// Dispose resources and cancel subscriptions.
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _statusNotifier.dispose();
    _logger.i('SyncManager: Disposed');
  }

  /// Handle connectivity state changes.
  void _handleConnectivityChange(bool isConnected) {
    _logger.d('SyncManager: Connectivity changed - isConnected: $isConnected');

    if (isConnected && !_isSyncing) {
      // Connection restored, trigger sync
      syncAll();
    }
  }

  /// Start periodic background sync.
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        if (await _connectivityService.isConnected && !_isSyncing) {
          await syncAll();
        }
      },
    );
  }

  /// Synchronize all pending changes with remote.
  ///
  /// Returns `true` if sync completed successfully, `false` otherwise.
  Future<bool> syncAll() async {
    if (_isSyncing) {
      _logger.w('SyncManager: Sync already in progress, skipping...');
      return false;
    }

    if (!await _connectivityService.isConnected) {
      _logger.w('SyncManager: No connectivity, skipping sync');
      _statusNotifier.updateState(SyncState.offline);
      return false;
    }

    _isSyncing = true;
    _statusNotifier.updateState(SyncState.syncing);

    try {
      _logger.i('SyncManager: Starting full sync...');

      // Process pending items in sync queue
      final pendingCount = await _queueProcessor.getPendingCount();
      _statusNotifier.updateProgress(0, pendingCount);

      var processedCount = 0;
      var hasErrors = false;

      // Process in batches
      while (true) {
        final batch = await _queueProcessor.getNextBatch(
          DatabaseConfig.syncBatchSize,
        );

        if (batch.isEmpty) break;

        for (final item in batch) {
          final success = await _queueProcessor.processItem(item);
          processedCount++;
          _statusNotifier.updateProgress(processedCount, pendingCount);

          if (!success) {
            hasErrors = true;
          }
        }
      }

      // Update final state
      if (hasErrors) {
        _statusNotifier.updateState(SyncState.partialSuccess);
        _logger.w('SyncManager: Sync completed with some errors');
      } else {
        _statusNotifier.updateState(SyncState.synced);
        _logger.i('SyncManager: Sync completed successfully');
      }

      return !hasErrors;
    } catch (e, stackTrace) {
      _logger.e('SyncManager: Sync failed', error: e, stackTrace: stackTrace);
      _statusNotifier.updateState(SyncState.error, errorMessage: e.toString());
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a specific table only.
  Future<bool> syncTable(String tableName) async {
    if (_isSyncing) {
      _logger.w('SyncManager: Sync already in progress');
      return false;
    }

    if (!await _connectivityService.isConnected) {
      _logger.w('SyncManager: No connectivity');
      return false;
    }

    _isSyncing = true;

    try {
      _logger.i('SyncManager: Syncing table: $tableName');
      await _queueProcessor.processTableItems(tableName);
      return true;
    } catch (e, stackTrace) {
      _logger.e(
        'SyncManager: Table sync failed for $tableName',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Force retry all failed sync items.
  Future<void> retryFailedItems() async {
    _logger.i('SyncManager: Retrying failed items...');
    await _queueProcessor.resetFailedItems();
    await syncAll();
  }

  /// Clear all pending sync items (use with caution).
  Future<void> clearSyncQueue() async {
    _logger.w('SyncManager: Clearing sync queue...');
    await _queueProcessor.clearQueue();
    _statusNotifier.updateState(SyncState.synced);
  }

  /// Get count of pending sync items.
  Future<int> getPendingCount() async {
    return _queueProcessor.getPendingCount();
  }

  /// Get count of failed sync items.
  Future<int> getFailedCount() async {
    return _queueProcessor.getFailedCount();
  }
}

/// Represents the current state of synchronization.
enum SyncState {
  /// Initial state, sync status unknown
  initial,

  /// No network connectivity
  offline,

  /// Sync in progress
  syncing,

  /// All items synced successfully
  synced,

  /// Some items failed to sync
  partialSuccess,

  /// Sync failed with error
  error,
}
