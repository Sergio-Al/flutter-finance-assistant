import 'package:equatable/equatable.dart';

/// Base class for all sync states.
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Initial state before sync initialization.
class SyncInitial extends SyncState {
  const SyncInitial();
}

/// State when device is offline.
class SyncOffline extends SyncState {
  final int pendingCount;
  final DateTime? lastSyncTime;

  const SyncOffline({
    this.pendingCount = 0,
    this.lastSyncTime,
  });

  @override
  List<Object?> get props => [pendingCount, lastSyncTime];
}

/// State when sync is in progress.
class SyncInProgress extends SyncState {
  final int processedItems;
  final int totalItems;
  final String? currentTable;

  const SyncInProgress({
    this.processedItems = 0,
    this.totalItems = 0,
    this.currentTable,
  });

  /// Progress percentage (0.0 - 1.0).
  double get progress {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  @override
  List<Object?> get props => [processedItems, totalItems, currentTable];
}

/// State when sync completed successfully.
class SyncCompleted extends SyncState {
  final DateTime syncedAt;
  final int itemsSynced;

  const SyncCompleted({
    required this.syncedAt,
    this.itemsSynced = 0,
  });

  @override
  List<Object?> get props => [syncedAt, itemsSynced];
}

/// State when sync completed with some errors.
class SyncPartialSuccess extends SyncState {
  final int successCount;
  final int failedCount;
  final DateTime? lastSyncTime;

  const SyncPartialSuccess({
    required this.successCount,
    required this.failedCount,
    this.lastSyncTime,
  });

  @override
  List<Object?> get props => [successCount, failedCount, lastSyncTime];
}

/// State when sync failed.
class SyncError extends SyncState {
  final String message;
  final SyncErrorType type;
  final int pendingCount;
  final DateTime? lastSyncTime;

  const SyncError({
    required this.message,
    this.type = SyncErrorType.unknown,
    this.pendingCount = 0,
    this.lastSyncTime,
  });

  @override
  List<Object?> get props => [message, type, pendingCount, lastSyncTime];
}

/// Types of sync errors.
enum SyncErrorType {
  /// No network connection.
  noConnection,

  /// Server/Firebase error.
  serverError,

  /// Authentication required.
  authRequired,

  /// Data conflict that couldn't be resolved.
  conflictError,

  /// Unknown error.
  unknown,
}
