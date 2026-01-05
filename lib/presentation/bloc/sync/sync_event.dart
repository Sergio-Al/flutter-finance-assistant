import 'package:equatable/equatable.dart';

/// Base class for all sync events.
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start full synchronization (push local changes + pull remote).
class SyncAllRequested extends SyncEvent {
  const SyncAllRequested();
}

/// Event to push local changes to remote only.
class SyncPushRequested extends SyncEvent {
  const SyncPushRequested();
}

/// Event to pull changes from remote only.
class SyncPullRequested extends SyncEvent {
  const SyncPullRequested();
}

/// Event to sync a specific table only.
class SyncTableRequested extends SyncEvent {
  final String tableName;

  const SyncTableRequested({required this.tableName});

  @override
  List<Object?> get props => [tableName];
}

/// Event to retry failed sync items.
class SyncRetryFailedRequested extends SyncEvent {
  const SyncRetryFailedRequested();
}

/// Event when sync state changes (from stream).
class SyncStateUpdated extends SyncEvent {
  final SyncStatus status;
  final int? processedItems;
  final int? totalItems;
  final String? errorMessage;

  const SyncStateUpdated({
    required this.status,
    this.processedItems,
    this.totalItems,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, processedItems, totalItems, errorMessage];
}

/// Event to initialize sync manager and start listening.
class SyncInitialized extends SyncEvent {
  const SyncInitialized();
}

/// Event to check pending sync items count.
class SyncPendingCountRequested extends SyncEvent {
  const SyncPendingCountRequested();
}

/// Sync status enum for events.
enum SyncStatus {
  initial,
  offline,
  syncing,
  synced,
  partialSuccess,
  error,
}
