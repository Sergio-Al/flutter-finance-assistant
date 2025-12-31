import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/user_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/user_model.dart';
import 'package:flutter_finance_assistant/domain/entities/user.dart';
import 'package:flutter_finance_assistant/domain/repositories/user_repository.dart';

/// Implementation of [UserRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Handles user profile management and preferences.
class UserRepositoryImpl implements UserRepository {
  final AppDatabase _database;
  final UserRemoteDataSource _remoteDataSource;
  final FirebaseService _firebaseService;

  /// Creates [UserRepositoryImpl] with required data sources.
  UserRepositoryImpl({
    required AppDatabase database,
    required UserRemoteDataSource remoteDataSource,
    required FirebaseService firebaseService,
  }) : _database = database,
       _remoteDataSource = remoteDataSource,
       _firebaseService = firebaseService;

  // ═══════════════════════════════════════════════════════════════════════════
  // User Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) {
        return const Right(null);
      }

      // Try local first
      final entry = await _database.usersDao.getUserById(userId);
      if (entry != null) {
        return Right(_entryToEntity(entry));
      }

      // Fall back to remote
      final remoteUser = await _remoteDataSource.getUserById(userId);
      if (remoteUser != null) {
        // Cache locally
        await _database.usersDao.upsertUser(_modelToCompanion(remoteUser));
        return Right(remoteUser.toEntity());
      }

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get current user: ${e.message}',
          originalError: e,
        ),
      );
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to get current user from server: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting current user: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      // Try local first
      final entry = await _database.usersDao.getUserById(userId);
      if (entry != null) {
        return Right(_entryToEntity(entry));
      }

      // Fall back to remote
      final remoteUser = await _remoteDataSource.getUserById(userId);
      if (remoteUser == null) {
        return Left(NotFoundFailure(message: 'User not found: $userId'));
      }

      // Cache locally
      await _database.usersDao.upsertUser(_modelToCompanion(remoteUser));

      return Right(remoteUser.toEntity());
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get user: ${e.message}',
          originalError: e,
        ),
      );
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to get user from server: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting user: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> ensureUserExists(
    String userId, {
    String? email,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _database.usersDao.getUserById(userId);
      if (existingUser == null) {
        // Create a minimal user record
        final now = DateTime.now();
        final companion = UsersCompanion(
          id: Value(userId),
          email: Value(email ?? '$userId@placeholder.local'),
          displayName: const Value(null),
          photoUrl: const Value(null),
          preferredCurrency: const Value('USD'),
          biometricEnabled: const Value(false),
          themePreference: const Value('system'),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncedAt: const Value(null),
        );

        await _database.usersDao.upsertUser(companion);
      }

      // Ensure user has at least one default account
      final existingAccounts = await _database.accountsDao.getAllAccounts(
        userId,
      );
      if (existingAccounts.isEmpty) {
        final now = DateTime.now();
        final defaultAccountId = const Uuid().v4();
        final accountCompanion = AccountsCompanion(
          id: Value(defaultAccountId),
          userId: Value(userId),
          name: const Value('Main Account'),
          type: const Value('cash'),
          balance: const Value(0.0),
          currency: const Value('USD'),
          icon: const Value('account_balance_wallet'),
          color: const Value(0xFF2E7D6F),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        );
        await _database.accountsDao.insertAccount(accountCompanion);
      }

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to ensure user exists: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error ensuring user exists: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> createUser(User user) async {
    try {
      final now = DateTime.now();
      final newUser = user.copyWith(createdAt: now, updatedAt: now);

      // Save locally first
      await _database.usersDao.upsertUser(_entityToCompanion(newUser));

      // Create in remote
      try {
        final model = UserModel.fromEntity(newUser);
        await _remoteDataSource.createUser(model);

        // Update sync timestamp
        await _database.usersDao.updateSyncedAt(newUser.id);
      } on NetworkException {
        // Will sync later when online
      } on ServerException {
        // Will sync later
      }

      return Right(newUser);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create user: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating user: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());

      // Update locally first
      await _database.usersDao.upsertUser(_entityToCompanion(updatedUser));

      // Update in remote
      try {
        final model = UserModel.fromEntity(updatedUser);
        await _remoteDataSource.updateUser(model);

        // Update sync timestamp
        await _database.usersDao.updateSyncedAt(updatedUser.id);
      } on NetworkException {
        // Will sync later when online
      } on ServerException {
        // Will sync later
      }

      return Right(updatedUser);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update user: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating user: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      // Delete locally
      final deletedCount = await _database.usersDao.deleteUser(userId);
      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(message: 'User not found for deletion: $userId'),
        );
      }

      // Delete from remote
      try {
        await _remoteDataSource.deleteUser(userId);
      } on NetworkException {
        // User deleted locally, remote will be handled by Cloud Functions
      } on ServerException {
        // User deleted locally
      }

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete user: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting user: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Preferences
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, User>> updatePreferences({
    required String userId,
    String? preferredCurrency,
    bool? biometricEnabled,
    ThemePreference? themePreference,
  }) async {
    try {
      // Update locally
      final success = await _database.usersDao.updatePreferences(
        userId: userId,
        preferredCurrency: preferredCurrency,
        biometricEnabled: biometricEnabled,
        themePreference: themePreference != null
            ? _themePreferenceToString(themePreference)
            : null,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'User not found for preferences update: $userId',
          ),
        );
      }

      // Update in remote
      try {
        final preferences = <String, dynamic>{};
        if (preferredCurrency != null) {
          preferences['preferred_currency'] = preferredCurrency;
        }
        if (biometricEnabled != null) {
          preferences['biometric_enabled'] = biometricEnabled;
        }
        if (themePreference != null) {
          preferences['theme_preference'] = _themePreferenceToString(
            themePreference,
          );
        }

        if (preferences.isNotEmpty) {
          await _remoteDataSource.updatePreferences(
            userId: userId,
            preferences: preferences,
          );
        }
      } on NetworkException {
        // Will sync later when online
      } on ServerException {
        // Will sync later
      }

      // Return updated user
      final entry = await _database.usersDao.getUserById(userId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'User not found after update'));
      }

      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update preferences: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating preferences: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, User?>> watchCurrentUser() {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      return Stream.value(const Right(null));
    }

    return _database.usersDao.watchUserById(userId).map((entry) {
      try {
        if (entry == null) {
          return const Right<Failure, User?>(null);
        }
        return Right<Failure, User?>(_entryToEntity(entry));
      } catch (e) {
        return Left<Failure, User?>(
          CacheFailure(
            message: 'Error watching current user: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync user from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteUser = await _remoteDataSource.getUserById(userId);
      if (remoteUser == null) {
        return Left(
          NotFoundFailure(message: 'User not found in remote: $userId'),
        );
      }

      // Check if local data is newer
      final localEntry = await _database.usersDao.getUserById(userId);
      if (localEntry != null &&
          localEntry.updatedAt.isAfter(remoteUser.updatedAt)) {
        // Local is newer, push to remote instead
        return await syncToRemote(userId);
      }

      // Update local with remote data
      await _database.usersDao.upsertUser(_modelToCompanion(remoteUser));
      await _database.usersDao.updateSyncedAt(userId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync user from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing user: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing user: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push local user data to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final localEntry = await _database.usersDao.getUserById(userId);
      if (localEntry == null) {
        return Left(
          NotFoundFailure(message: 'User not found locally: $userId'),
        );
      }

      final user = _entryToEntity(localEntry);
      final model = UserModel.fromEntity(user);
      await _remoteDataSource.updateUser(model);
      await _database.usersDao.updateSyncedAt(userId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync user to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing user: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing user: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [UserEntry] to domain [User] entity.
  User _entryToEntity(UserEntry entry) {
    return User(
      id: entry.id,
      email: entry.email,
      displayName: entry.displayName,
      photoUrl: entry.photoUrl,
      preferredCurrency: entry.preferredCurrency,
      biometricEnabled: entry.biometricEnabled,
      themePreference: _themePreferenceFromString(entry.themePreference),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncedAt: entry.syncedAt,
    );
  }

  /// Convert domain [User] entity to Drift [UsersCompanion].
  UsersCompanion _entityToCompanion(User entity) {
    return UsersCompanion(
      id: Value(entity.id),
      email: Value(entity.email),
      displayName: Value(entity.displayName),
      photoUrl: Value(entity.photoUrl),
      preferredCurrency: Value(entity.preferredCurrency),
      biometricEnabled: Value(entity.biometricEnabled),
      themePreference: Value(_themePreferenceToString(entity.themePreference)),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      syncedAt: Value(entity.syncedAt),
    );
  }

  /// Convert [UserModel] to Drift [UsersCompanion].
  UsersCompanion _modelToCompanion(UserModel model) {
    return UsersCompanion(
      id: Value(model.id),
      email: Value(model.email),
      displayName: Value(model.displayName),
      photoUrl: Value(model.photoUrl),
      preferredCurrency: Value(model.preferredCurrency),
      biometricEnabled: Value(model.biometricEnabled),
      themePreference: Value(model.themePreference),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      syncedAt: Value(model.syncedAt),
    );
  }

  /// Convert [ThemePreference] enum to string.
  String _themePreferenceToString(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
      case ThemePreference.system:
        return 'system';
    }
  }

  /// Convert string to [ThemePreference] enum.
  ThemePreference _themePreferenceFromString(String value) {
    switch (value) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      case 'system':
      default:
        return ThemePreference.system;
    }
  }
}
