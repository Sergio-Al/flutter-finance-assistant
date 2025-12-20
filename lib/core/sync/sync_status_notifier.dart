import 'dart:async';

import 'package:flutter_finance_assistant/core/sync/sync_manager.dart';

/// Notifies listeners about sync state changes and progress.
///
/// Provides a stream-based API for UI components to react to
/// sync status updates in real-time.
class SyncStatusNotifier {
  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  SyncState _currentState = SyncState.initial;
  int _processedItems = 0;
  int _totalItems = 0;
  String? _errorMessage;
  DateTime? _lastSyncTime;

  /// Stream of sync state changes.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Current sync state.
  SyncState get currentState => _currentState;

  /// Number of items processed in current sync.
  int get processedItems => _processedItems;

  /// Total items to sync in current operation.
  int get totalItems => _totalItems;

  /// Progress percentage (0.0 - 1.0).
  double get progress {
    if (_totalItems == 0) return 0.0;
    return _processedItems / _totalItems;
  }

  /// Last error message if sync failed.
  String? get errorMessage => _errorMessage;

  /// Time of last successful sync.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Human-readable status message.
  String get statusMessage {
    switch (_currentState) {
      case SyncState.initial:
        return 'Ready to sync';
      case SyncState.offline:
        return 'Offline - Changes saved locally';
      case SyncState.syncing:
        return 'Syncing... $_processedItems/$_totalItems';
      case SyncState.synced:
        return _lastSyncTime != null
            ? 'Synced ${_formatLastSync(_lastSyncTime!)}'
            : 'All synced';
      case SyncState.partialSuccess:
        return 'Synced with some errors';
      case SyncState.error:
        return 'Sync failed: ${_errorMessage ?? "Unknown error"}';
    }
  }

  /// Update the current sync state.
  void updateState(SyncState state, {String? errorMessage}) {
    _currentState = state;
    _errorMessage = errorMessage;

    if (state == SyncState.synced) {
      _lastSyncTime = DateTime.now();
      _resetProgress();
    }

    if (state == SyncState.error || state == SyncState.partialSuccess) {
      _errorMessage = errorMessage;
    }

    _stateController.add(state);
  }

  /// Update sync progress.
  void updateProgress(int processed, int total) {
    _processedItems = processed;
    _totalItems = total;
  }

  /// Reset progress counters.
  void _resetProgress() {
    _processedItems = 0;
    _totalItems = 0;
  }

  /// Format last sync time as human-readable string.
  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    }
  }

  /// Dispose resources.
  void dispose() {
    _stateController.close();
  }
}

/// Extension to provide additional sync state utilities.
extension SyncStateExtension on SyncState {
  /// Whether sync is currently active.
  bool get isActive => this == SyncState.syncing;

  /// Whether there's an issue that needs attention.
  bool get needsAttention =>
      this == SyncState.error ||
      this == SyncState.partialSuccess ||
      this == SyncState.offline;

  /// Whether all data is synced.
  bool get isFullySynced => this == SyncState.synced;

  /// Icon name for this state.
  String get iconName {
    switch (this) {
      case SyncState.initial:
        return 'cloud_queue';
      case SyncState.offline:
        return 'cloud_off';
      case SyncState.syncing:
        return 'cloud_sync';
      case SyncState.synced:
        return 'cloud_done';
      case SyncState.partialSuccess:
        return 'cloud_queue';
      case SyncState.error:
        return 'cloud_off';
    }
  }
}
