import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
///
/// Uses functional error handling with dartz's Either type.
/// Specific failures extend this class for different error scenarios.
abstract class Failure extends Equatable {
  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  /// Original exception/error if available
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code];
}

// ═══════════════════════════════════════════════════════════════════════════
// Server/Network Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when server returns an error
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Failure when request times out
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache/Local Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when cache operation fails
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local storage.',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// Failure when database operation fails
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code = 'DATABASE_ERROR',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when user is not authenticated
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication required. Please sign in.',
    super.code = 'AUTH_REQUIRED',
    super.originalError,
  });
}

/// Failure when credentials are invalid
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Invalid email or password.',
    super.code = 'INVALID_CREDENTIALS',
    super.originalError,
  });
}

/// Failure when email is already in use
class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure({
    super.message = 'This email is already registered.',
    super.code = 'EMAIL_IN_USE',
    super.originalError,
  });
}

/// Failure when password is too weak
class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure({
    super.message = 'Password is too weak. Please use a stronger password.',
    super.code = 'WEAK_PASSWORD',
    super.originalError,
  });
}

/// Failure when user account is disabled
class AccountDisabledFailure extends Failure {
  const AccountDisabledFailure({
    super.message = 'This account has been disabled.',
    super.code = 'ACCOUNT_DISABLED',
    super.originalError,
  });
}

/// Failure when too many requests are made
class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure({
    super.message = 'Too many attempts. Please try again later.',
    super.code = 'TOO_MANY_REQUESTS',
    super.originalError,
  });
}

/// Failure when biometric authentication fails
class BiometricFailure extends Failure {
  const BiometricFailure({
    super.message = 'Biometric authentication failed.',
    super.code = 'BIOMETRIC_FAILED',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when input validation fails
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Failure when a required resource is not found
class NotFoundFailure extends Failure {
  final String? resourceType;
  final String? resourceId;

  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code = 'NOT_FOUND',
    super.originalError,
    this.resourceType,
    this.resourceId,
  });

  @override
  List<Object?> get props => [message, code, resourceType, resourceId];
}

/// Failure when operation is not permitted
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action.',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Sync Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when sync operation fails
class SyncFailure extends Failure {
  final int? failedCount;
  final int? totalCount;

  const SyncFailure({
    required super.message,
    super.code = 'SYNC_ERROR',
    super.originalError,
    this.failedCount,
    this.totalCount,
  });

  @override
  List<Object?> get props => [message, code, failedCount, totalCount];
}

/// Failure when sync conflict occurs
class ConflictFailure extends Failure {
  final String? localVersion;
  final String? remoteVersion;

  const ConflictFailure({
    super.message = 'A sync conflict occurred. Please resolve manually.',
    super.code = 'SYNC_CONFLICT',
    super.originalError,
    this.localVersion,
    this.remoteVersion,
  });

  @override
  List<Object?> get props => [message, code, localVersion, remoteVersion];
}

// ═══════════════════════════════════════════════════════════════════════════
// AI/ML Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when AI service fails
class AIServiceFailure extends Failure {
  final String? model;

  const AIServiceFailure({
    required super.message,
    super.code = 'AI_ERROR',
    super.originalError,
    this.model,
  });

  @override
  List<Object?> get props => [message, code, model];
}

/// Failure when OCR processing fails
class OCRFailure extends Failure {
  const OCRFailure({
    super.message = 'Failed to process receipt image.',
    super.code = 'OCR_ERROR',
    super.originalError,
  });
}

/// Failure when ML model fails
class MLModelFailure extends Failure {
  final String? modelName;

  const MLModelFailure({
    required super.message,
    super.code = 'ML_ERROR',
    super.originalError,
    this.modelName,
  });

  @override
  List<Object?> get props => [message, code, modelName];
}

// ═══════════════════════════════════════════════════════════════════════════
// Storage Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when file upload fails
class UploadFailure extends Failure {
  final String? fileName;

  const UploadFailure({
    required super.message,
    super.code = 'UPLOAD_ERROR',
    super.originalError,
    this.fileName,
  });

  @override
  List<Object?> get props => [message, code, fileName];
}

/// Failure when file download fails
class DownloadFailure extends Failure {
  final String? fileName;

  const DownloadFailure({
    required super.message,
    super.code = 'DOWNLOAD_ERROR',
    super.originalError,
    this.fileName,
  });

  @override
  List<Object?> get props => [message, code, fileName];
}

// ═══════════════════════════════════════════════════════════════════════════
// Generic Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Generic unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNEXPECTED_ERROR',
    super.originalError,
  });
}

/// Failure for cancelled operations
class CancelledFailure extends Failure {
  const CancelledFailure({
    super.message = 'Operation was cancelled.',
    super.code = 'CANCELLED',
    super.originalError,
  });
}
