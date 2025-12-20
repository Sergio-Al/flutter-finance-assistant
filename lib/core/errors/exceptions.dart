/// Custom exceptions for the Finance Assistant app.
///
/// These are thrown by data sources and caught by repositories
/// to be converted into Failures.

// ═══════════════════════════════════════════════════════════════════════════
// Server/Network Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when server returns an error
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Exception when there's no internet connection
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception when request times out
class TimeoutException implements Exception {
  final String message;
  final Duration? duration;

  const TimeoutException([this.message = 'Request timed out', this.duration]);

  @override
  String toString() => 'TimeoutException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache/Local Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when cache operation fails
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache operation failed']);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception when database operation fails
class DatabaseException implements Exception {
  final String message;
  final String? query;

  const DatabaseException(this.message, [this.query]);

  @override
  String toString() => 'DatabaseException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when authentication is required
class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException([this.message = 'Authentication required']);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Exception when credentials are invalid
class InvalidCredentialsException implements Exception {
  final String message;

  const InvalidCredentialsException([this.message = 'Invalid credentials']);

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// Exception when user is not found
class UserNotFoundException implements Exception {
  final String message;

  const UserNotFoundException([this.message = 'User not found']);

  @override
  String toString() => 'UserNotFoundException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when validation fails
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException(this.message, [this.fieldErrors]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception when resource is not found
class NotFoundException implements Exception {
  final String message;
  final String? resourceType;
  final String? resourceId;

  const NotFoundException(
    this.message, [
    this.resourceType,
    this.resourceId,
  ]);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception when operation is not permitted
class PermissionException implements Exception {
  final String message;

  const PermissionException([this.message = 'Permission denied']);

  @override
  String toString() => 'PermissionException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// Sync Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when sync fails
class SyncException implements Exception {
  final String message;
  final int? failedCount;

  const SyncException(this.message, [this.failedCount]);

  @override
  String toString() => 'SyncException: $message';
}

/// Exception when sync conflict occurs
class ConflictException implements Exception {
  final String message;
  final dynamic localData;
  final dynamic remoteData;

  const ConflictException(this.message, [this.localData, this.remoteData]);

  @override
  String toString() => 'ConflictException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// AI/ML Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when AI service fails
class AIServiceException implements Exception {
  final String message;
  final String? model;

  const AIServiceException(this.message, [this.model]);

  @override
  String toString() => 'AIServiceException: $message';
}

/// Exception when OCR fails
class OCRException implements Exception {
  final String message;

  const OCRException([this.message = 'OCR processing failed']);

  @override
  String toString() => 'OCRException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// Storage Exceptions
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when file upload fails
class UploadException implements Exception {
  final String message;
  final String? fileName;

  const UploadException(this.message, [this.fileName]);

  @override
  String toString() => 'UploadException: $message';
}

/// Exception when file download fails
class DownloadException implements Exception {
  final String message;
  final String? fileName;

  const DownloadException(this.message, [this.fileName]);

  @override
  String toString() => 'DownloadException: $message';
}
