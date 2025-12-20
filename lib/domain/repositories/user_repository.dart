import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/user.dart';

/// Repository interface for user operations.
///
/// Defines the contract for user data access.
/// Implementation will be in the data layer.
abstract class UserRepository {
  /// Get the currently authenticated user.
  Future<Either<Failure, User?>> getCurrentUser();

  /// Get user by ID.
  Future<Either<Failure, User>> getUserById(String userId);

  /// Ensure a user exists in the local database.
  /// Creates a minimal user record if it doesn't exist.
  /// Used to satisfy foreign key constraints.
  Future<Either<Failure, void>> ensureUserExists(
    String userId, {
    String? email,
  });

  /// Create a new user profile.
  Future<Either<Failure, User>> createUser(User user);

  /// Update user profile.
  Future<Either<Failure, User>> updateUser(User user);

  /// Delete user account and all associated data.
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Update user preferences.
  Future<Either<Failure, User>> updatePreferences({
    required String userId,
    String? preferredCurrency,
    bool? biometricEnabled,
    ThemePreference? themePreference,
  });

  /// Stream of current user changes.
  Stream<Either<Failure, User?>> watchCurrentUser();
}
