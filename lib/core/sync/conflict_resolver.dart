import 'package:logger/logger.dart';

/// Handles conflict resolution between local and remote data.
///
/// Provides different strategies for resolving sync conflicts
/// when both local and remote data have been modified.
class ConflictResolver {
  final Logger _logger;
  final ConflictResolutionStrategy _defaultStrategy;

  /// Creates a [ConflictResolver] with optional custom strategy.
  ConflictResolver({
    ConflictResolutionStrategy defaultStrategy =
        ConflictResolutionStrategy.remoteWins,
    Logger? logger,
  })  : _defaultStrategy = defaultStrategy,
        _logger = logger ?? Logger();

  /// Resolve a conflict between local and remote data.
  ///
  /// Returns the resolved data that should be persisted.
  Future<ConflictResolution> resolve({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictResolutionStrategy? strategy,
  }) async {
    final effectiveStrategy = strategy ?? _defaultStrategy;

    _logger.d(
      'ConflictResolver: Resolving conflict for $tableName/$recordId '
      'using strategy: ${effectiveStrategy.name}',
    );

    switch (effectiveStrategy) {
      case ConflictResolutionStrategy.localWins:
        return _resolveLocalWins(localData, remoteData);
      case ConflictResolutionStrategy.remoteWins:
        return _resolveRemoteWins(localData, remoteData);
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveLastWriteWins(localData, remoteData);
      case ConflictResolutionStrategy.merge:
        return _resolveMerge(localData, remoteData);
      case ConflictResolutionStrategy.manual:
        return _resolveManual(localData, remoteData);
    }
  }

  /// Local data wins - keep local, overwrite remote.
  ConflictResolution _resolveLocalWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    return ConflictResolution(
      resolvedData: localData,
      action: ConflictAction.pushLocal,
      strategy: ConflictResolutionStrategy.localWins,
    );
  }

  /// Remote data wins - overwrite local with remote.
  ConflictResolution _resolveRemoteWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    return ConflictResolution(
      resolvedData: remoteData,
      action: ConflictAction.pullRemote,
      strategy: ConflictResolutionStrategy.remoteWins,
    );
  }

  /// Most recent update wins based on timestamp.
  ConflictResolution _resolveLastWriteWins(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final localUpdatedAt = _parseTimestamp(localData['updated_at']);
    final remoteUpdatedAt = _parseTimestamp(remoteData['updated_at']);

    if (localUpdatedAt == null && remoteUpdatedAt == null) {
      // No timestamps, default to remote wins
      return _resolveRemoteWins(localData, remoteData);
    }

    if (localUpdatedAt == null) {
      return _resolveRemoteWins(localData, remoteData);
    }

    if (remoteUpdatedAt == null) {
      return _resolveLocalWins(localData, remoteData);
    }

    if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return ConflictResolution(
        resolvedData: localData,
        action: ConflictAction.pushLocal,
        strategy: ConflictResolutionStrategy.lastWriteWins,
      );
    } else {
      return ConflictResolution(
        resolvedData: remoteData,
        action: ConflictAction.pullRemote,
        strategy: ConflictResolutionStrategy.lastWriteWins,
      );
    }
  }

  /// Merge both versions - combine non-conflicting fields.
  ConflictResolution _resolveMerge(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final merged = <String, dynamic>{};

    // Start with remote as base
    merged.addAll(remoteData);

    // Get timestamps
    final localUpdatedAt = _parseTimestamp(localData['updated_at']);
    final remoteUpdatedAt = _parseTimestamp(remoteData['updated_at']);

    // Overlay local changes for fields that were modified more recently locally
    for (final key in localData.keys) {
      if (_shouldPreferLocalField(
        key,
        localData,
        remoteData,
        localUpdatedAt,
        remoteUpdatedAt,
      )) {
        merged[key] = localData[key];
      }
    }

    // Update timestamp to now
    merged['updated_at'] = DateTime.now().toIso8601String();

    return ConflictResolution(
      resolvedData: merged,
      action: ConflictAction.mergeAndPush,
      strategy: ConflictResolutionStrategy.merge,
    );
  }

  /// Manual resolution required - flag for user review.
  ConflictResolution _resolveManual(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    return ConflictResolution(
      resolvedData: localData, // Keep local for now
      action: ConflictAction.requiresManualResolution,
      strategy: ConflictResolutionStrategy.manual,
      localVersion: localData,
      remoteVersion: remoteData,
    );
  }

  /// Determine if local field value should be preferred.
  bool _shouldPreferLocalField(
    String key,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
  ) {
    // Skip system fields
    if (_isSystemField(key)) return false;

    // If values are the same, no preference needed
    if (localData[key] == remoteData[key]) return false;

    // If local is newer, prefer local
    if (localUpdatedAt != null &&
        remoteUpdatedAt != null &&
        localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return true;
    }

    return false;
  }

  /// Check if a field is a system field (not user-editable).
  bool _isSystemField(String key) {
    return const [
      'id',
      'created_at',
      'sync_status',
      'synced_at',
      '_sync_id',
      '_queued_at',
    ].contains(key);
  }

  /// Parse timestamp from various formats.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }
}

/// Strategies for resolving sync conflicts.
enum ConflictResolutionStrategy {
  /// Local changes always win
  localWins,

  /// Remote changes always win
  remoteWins,

  /// Most recent modification wins (based on timestamp)
  lastWriteWins,

  /// Attempt to merge both versions
  merge,

  /// Require manual user resolution
  manual,
}

/// Action to take after conflict resolution.
enum ConflictAction {
  /// Push local data to remote
  pushLocal,

  /// Pull remote data to local
  pullRemote,

  /// Merge and push merged result
  mergeAndPush,

  /// Requires user to manually resolve
  requiresManualResolution,
}

/// Result of conflict resolution.
class ConflictResolution {
  /// The resolved data to persist.
  final Map<String, dynamic> resolvedData;

  /// The action to take.
  final ConflictAction action;

  /// The strategy that was used.
  final ConflictResolutionStrategy strategy;

  /// Original local version (for manual resolution).
  final Map<String, dynamic>? localVersion;

  /// Original remote version (for manual resolution).
  final Map<String, dynamic>? remoteVersion;

  const ConflictResolution({
    required this.resolvedData,
    required this.action,
    required this.strategy,
    this.localVersion,
    this.remoteVersion,
  });

  /// Whether manual resolution is required.
  bool get requiresManualResolution =>
      action == ConflictAction.requiresManualResolution;
}
