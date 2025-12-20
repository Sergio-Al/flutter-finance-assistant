import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Log levels for controlling output verbosity.
enum LogLevel {
  debug(0, '🐛', 'DEBUG'),
  info(1, 'ℹ️', 'INFO'),
  warning(2, '⚠️', 'WARNING'),
  error(3, '❌', 'ERROR');

  final int priority;
  final String emoji;
  final String label;

  const LogLevel(this.priority, this.emoji, this.label);
}

/// Centralized logging utility for the application.
///
/// Features:
/// - Multiple log levels (debug, info, warning, error)
/// - Environment-aware (verbose in debug, minimal in release)
/// - Firebase Crashlytics integration for production error tracking
/// - Consistent formatting with timestamps and tags
///
/// ## Usage
/// ```dart
/// // Basic logging
/// AppLogger.debug('Loading budgets...');
/// AppLogger.info('User logged in', tag: 'Auth');
/// AppLogger.warning('API rate limit approaching');
/// AppLogger.error('Failed to sync', error: e, stackTrace: stack);
///
/// // With custom tag
/// AppLogger.d('Budget created', tag: 'BudgetRepo');
/// ```
class AppLogger {
  /// Minimum log level to display. Messages below this level are ignored.
  /// Defaults to [LogLevel.debug] in debug mode, [LogLevel.warning] in release.
  static LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Whether to include timestamps in log output.
  static bool showTimestamp = true;

  /// Whether to send errors to Firebase Crashlytics in release mode.
  static bool enableCrashlytics = true;

  /// Private constructor to prevent instantiation.
  AppLogger._();

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API - Shorthand methods
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log a debug message. Shorthand for [debug].
  static void d(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => debug(message, tag: tag, error: error, stackTrace: stackTrace);

  /// Log an info message. Shorthand for [info].
  static void i(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => info(message, tag: tag, error: error, stackTrace: stackTrace);

  /// Log a warning message. Shorthand for [warning].
  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) => warning(message, tag: tag, error: error, stackTrace: stackTrace);

  /// Log an error message. Shorthand for [error].
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      AppLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API - Full methods
  // ═══════════════════════════════════════════════════════════════════════════

  /// Log a debug message.
  ///
  /// Use for detailed information useful during development.
  /// These messages are typically filtered out in production.
  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an info message.
  ///
  /// Use for general information about app flow and state changes.
  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message.
  ///
  /// Use for potentially harmful situations that don't prevent operation.
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message.
  ///
  /// Use for error events that might still allow the app to continue.
  /// Errors are automatically sent to Firebase Crashlytics in release mode.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a fatal error and report to Crashlytics.
  ///
  /// Use for severe errors that cause the app to crash or become unusable.
  /// Always reported to Crashlytics regardless of [enableCrashlytics] setting.
  static void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      '🔥 FATAL: $message',
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    // Always report fatal errors to Crashlytics
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Crashlytics Integration
  // ═══════════════════════════════════════════════════════════════════════════

  /// Set a custom key-value pair for Crashlytics reports.
  ///
  /// Useful for adding context to crash reports.
  /// ```dart
  /// AppLogger.setUserProperty('subscription', 'premium');
  /// ```
  static Future<void> setUserProperty(String key, String value) async {
    if (!kDebugMode && enableCrashlytics) {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Set the user identifier for Crashlytics reports.
  static Future<void> setUserId(String userId) async {
    if (!kDebugMode && enableCrashlytics) {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  /// Log a message to Crashlytics (breadcrumb).
  ///
  /// Creates a trail of events leading up to a crash.
  static Future<void> logEvent(String message) async {
    if (!kDebugMode && enableCrashlytics) {
      await FirebaseCrashlytics.instance.log(message);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Internal Implementation
  // ═══════════════════════════════════════════════════════════════════════════

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Skip if below minimum level
    if (level.priority < minLevel.priority) return;

    final buffer = StringBuffer();

    // Timestamp
    if (showTimestamp) {
      final now = DateTime.now();
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}.'
          '${now.millisecond.toString().padLeft(3, '0')}';
      buffer.write('[$timestamp] ');
    }

    // Level indicator
    buffer.write('${level.emoji} ${level.label}');

    // Tag
    if (tag != null) {
      buffer.write(' [$tag]');
    }

    // Message
    buffer.write(': $message');

    // Error details
    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    final logMessage = buffer.toString();

    // Output based on environment
    if (kDebugMode) {
      // Use developer.log for better IDE integration
      developer.log(
        logMessage,
        name: tag ?? 'App',
        error: error,
        stackTrace: stackTrace,
        level: _mapLevelToDevLog(level),
      );
    } else {
      // In release, only print warnings and errors
      if (level.priority >= LogLevel.warning.priority) {
        debugPrint(logMessage);
      }
    }

    // Send errors to Crashlytics in release mode
    if (!kDebugMode &&
        enableCrashlytics &&
        level == LogLevel.error &&
        error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }

    // Log breadcrumb for warnings and errors
    if (!kDebugMode &&
        enableCrashlytics &&
        level.priority >= LogLevel.warning.priority) {
      FirebaseCrashlytics.instance.log('${level.label}: $message');
    }
  }

  /// Map our log levels to dart:developer log levels.
  static int _mapLevelToDevLog(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500; // FINE
      case LogLevel.info:
        return 800; // INFO
      case LogLevel.warning:
        return 900; // WARNING
      case LogLevel.error:
        return 1000; // SEVERE
    }
  }
}

/// Extension for easy logging from any class.
///
/// ```dart
/// class BudgetRepository with Loggable {
///   void loadBudgets() {
///     log.d('Loading budgets...'); // Uses class name as tag
///   }
/// }
/// ```
mixin Loggable {
  /// Logger instance with class name as default tag.
  _TaggedLogger get log => _TaggedLogger(runtimeType.toString());
}

/// Logger wrapper that automatically includes a tag.
class _TaggedLogger {
  final String tag;

  const _TaggedLogger(this.tag);

  void d(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.debug(message, tag: tag, error: error, stackTrace: stackTrace);

  void i(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.info(message, tag: tag, error: error, stackTrace: stackTrace);

  void w(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.warning(
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      AppLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);
}
