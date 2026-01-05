import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_finance_assistant/core/sync/connectivity_service.dart';
import 'package:flutter_finance_assistant/core/sync/sync_manager.dart'
    as sync_mgr;
import 'package:flutter_finance_assistant/presentation/bloc/sync/sync_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/sync/sync_state.dart';

/// BLoC for managing data synchronization between local and remote databases.
///
/// Coordinates with [sync_mgr.SyncManager] to:
/// - Push local changes to Firestore
/// - Pull remote changes to local Drift database
/// - Handle offline/online state transitions
/// - Report sync progress to UI
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final sync_mgr.SyncManager _syncManager;
  final ConnectivityService _connectivityService;

  StreamSubscription<sync_mgr.SyncState>? _syncStateSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  /// Creates a [SyncBloc] with required dependencies.
  SyncBloc({
    required sync_mgr.SyncManager syncManager,
    required ConnectivityService connectivityService,
  }) : _syncManager = syncManager,
       _connectivityService = connectivityService,
       super(const SyncInitial()) {
    // Register event handlers
    on<SyncInitialized>(_onInitialized);
    on<SyncAllRequested>(_onSyncAllRequested);
    on<SyncPushRequested>(_onSyncPushRequested);
    on<SyncPullRequested>(_onSyncPullRequested);
    on<SyncTableRequested>(_onSyncTableRequested);
    on<SyncRetryFailedRequested>(_onRetryFailedRequested);
    on<SyncStateUpdated>(_onStateUpdated);
    on<SyncPendingCountRequested>(_onPendingCountRequested);
  }

  /// Initialize sync manager and start listening for state changes.
  Future<void> _onInitialized(
    SyncInitialized event,
    Emitter<SyncState> emit,
  ) async {
    // Listen to sync state changes from SyncManager
    _syncStateSubscription = _syncManager.syncStateStream.listen(
      (syncState) => _handleSyncManagerState(syncState),
    );

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (!isConnected) {
            add(const SyncStateUpdated(status: SyncStatus.offline));
          }
        });

    // Check initial connectivity and emit appropriate state
    final isConnected = await _connectivityService.isConnected;
    if (!isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
    } else {
      // Trigger initial sync
      add(const SyncAllRequested());
    }
  }

  /// Handle sync state changes from SyncManager.
  void _handleSyncManagerState(sync_mgr.SyncState managerState) {
    switch (managerState) {
      case sync_mgr.SyncState.initial:
        add(const SyncStateUpdated(status: SyncStatus.initial));
        break;
      case sync_mgr.SyncState.offline:
        add(const SyncStateUpdated(status: SyncStatus.offline));
        break;
      case sync_mgr.SyncState.syncing:
        add(const SyncStateUpdated(status: SyncStatus.syncing));
        break;
      case sync_mgr.SyncState.synced:
        add(const SyncStateUpdated(status: SyncStatus.synced));
        break;
      case sync_mgr.SyncState.partialSuccess:
        add(const SyncStateUpdated(status: SyncStatus.partialSuccess));
        break;
      case sync_mgr.SyncState.error:
        add(const SyncStateUpdated(status: SyncStatus.error));
        break;
    }
  }

  /// Handle full sync request (push + pull).
  Future<void> _onSyncAllRequested(
    SyncAllRequested event,
    Emitter<SyncState> emit,
  ) async {
    // Check connectivity first
    if (!await _connectivityService.isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
      return;
    }

    // Emit syncing state
    final pendingCount = await _syncManager.getPendingCount();
    print("the pending count ${pendingCount}");
    emit(SyncInProgress(totalItems: pendingCount));

    // Trigger sync
    final success = await _syncManager.syncAll();

    if (success) {
      emit(SyncCompleted(syncedAt: DateTime.now(), itemsSynced: pendingCount));
    } else {
      // Check if partial success or full failure
      final failedCount = await _syncManager.getFailedCount();
      if (failedCount > 0 && failedCount < pendingCount) {
        emit(
          SyncPartialSuccess(
            successCount: pendingCount - failedCount,
            failedCount: failedCount,
            lastSyncTime: DateTime.now(),
          ),
        );
      } else {
        emit(
          SyncError(
            message: 'Sync failed. Please try again.',
            type: SyncErrorType.unknown,
            pendingCount: await _syncManager.getPendingCount(),
          ),
        );
      }
    }
  }

  /// Handle push-only sync request.
  Future<void> _onSyncPushRequested(
    SyncPushRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!await _connectivityService.isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
      return;
    }

    final pendingCount = await _syncManager.getPendingCount();
    emit(SyncInProgress(totalItems: pendingCount));

    final success = await _syncManager.syncAll();

    if (success) {
      emit(SyncCompleted(syncedAt: DateTime.now(), itemsSynced: pendingCount));
    } else {
      emit(
        SyncError(
          message: 'Failed to push changes to server.',
          type: SyncErrorType.serverError,
          pendingCount: await _syncManager.getPendingCount(),
        ),
      );
    }
  }

  /// Handle pull-only sync request.
  Future<void> _onSyncPullRequested(
    SyncPullRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!await _connectivityService.isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
      return;
    }

    emit(const SyncInProgress());

    // For now, syncAll handles both push and pull
    final success = await _syncManager.syncAll();

    if (success) {
      emit(SyncCompleted(syncedAt: DateTime.now()));
    } else {
      emit(
        SyncError(
          message: 'Failed to pull changes from server.',
          type: SyncErrorType.serverError,
          pendingCount: await _syncManager.getPendingCount(),
        ),
      );
    }
  }

  /// Handle table-specific sync request.
  Future<void> _onSyncTableRequested(
    SyncTableRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!await _connectivityService.isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
      return;
    }

    emit(SyncInProgress(currentTable: event.tableName));

    final success = await _syncManager.syncTable(event.tableName);

    if (success) {
      emit(SyncCompleted(syncedAt: DateTime.now()));
    } else {
      emit(
        SyncError(
          message: 'Failed to sync ${event.tableName}.',
          type: SyncErrorType.serverError,
          pendingCount: await _syncManager.getPendingCount(),
        ),
      );
    }
  }

  /// Handle retry failed items request.
  Future<void> _onRetryFailedRequested(
    SyncRetryFailedRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (!await _connectivityService.isConnected) {
      final pendingCount = await _syncManager.getPendingCount();
      emit(SyncOffline(pendingCount: pendingCount));
      return;
    }

    final failedCount = await _syncManager.getFailedCount();
    emit(SyncInProgress(totalItems: failedCount));

    await _syncManager.retryFailedItems();

    final remainingFailed = await _syncManager.getFailedCount();
    if (remainingFailed == 0) {
      emit(SyncCompleted(syncedAt: DateTime.now(), itemsSynced: failedCount));
    } else {
      emit(
        SyncPartialSuccess(
          successCount: failedCount - remainingFailed,
          failedCount: remainingFailed,
          lastSyncTime: DateTime.now(),
        ),
      );
    }
  }

  /// Handle state update from SyncManager stream.
  Future<void> _onStateUpdated(
    SyncStateUpdated event,
    Emitter<SyncState> emit,
  ) async {
    switch (event.status) {
      case SyncStatus.initial:
        emit(const SyncInitial());
        break;
      case SyncStatus.offline:
        final pendingCount = await _syncManager.getPendingCount();
        emit(SyncOffline(pendingCount: pendingCount));
        break;
      case SyncStatus.syncing:
        emit(
          SyncInProgress(
            processedItems: event.processedItems ?? 0,
            totalItems: event.totalItems ?? 0,
          ),
        );
        break;
      case SyncStatus.synced:
        emit(SyncCompleted(syncedAt: DateTime.now()));
        break;
      case SyncStatus.partialSuccess:
        final failedCount = await _syncManager.getFailedCount();
        emit(
          SyncPartialSuccess(
            successCount: event.processedItems ?? 0,
            failedCount: failedCount,
            lastSyncTime: DateTime.now(),
          ),
        );
        break;
      case SyncStatus.error:
        emit(
          SyncError(
            message: event.errorMessage ?? 'Unknown sync error',
            pendingCount: await _syncManager.getPendingCount(),
          ),
        );
        break;
    }
  }

  /// Handle pending count request.
  Future<void> _onPendingCountRequested(
    SyncPendingCountRequested event,
    Emitter<SyncState> emit,
  ) async {
    final pendingCount = await _syncManager.getPendingCount();
    final isConnected = await _connectivityService.isConnected;

    if (!isConnected) {
      emit(SyncOffline(pendingCount: pendingCount));
    } else if (state is SyncCompleted) {
      emit(
        SyncCompleted(
          syncedAt: (state as SyncCompleted).syncedAt,
          itemsSynced: 0,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _syncStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
