import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/account_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/account_model.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';

/// Implementation of [AccountRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Provides both Future-based and Stream-based data access.
class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase _database;
  final AccountRemoteDataSource _remoteDataSource;

  /// Creates [AccountRepositoryImpl] with required dependencies.
  AccountRepositoryImpl({
    required AppDatabase database,
    required AccountRemoteDataSource remoteDataSource,
  }) : _database = database,
       _remoteDataSource = remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════════
  // Read Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Account>>> getAccounts(String userId) async {
    try {
      final entries = await _database.accountsDao.getAllAccounts(userId);
      final accounts = entries.map(_entryToEntity).toList();
      return Right(accounts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get accounts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting accounts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Account>>> getActiveAccounts(
    String userId,
  ) async {
    try {
      final entries = await _database.accountsDao.getActiveAccounts(userId);
      final accounts = entries.map(_entryToEntity).toList();
      return Right(accounts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get active accounts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting active accounts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Account>> getAccountById(String accountId) async {
    try {
      final entry = await _database.accountsDao.getAccountById(accountId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Account not found: $accountId'));
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Account>>> getAccountsByType(
    String userId,
    AccountType type,
  ) async {
    try {
      final entries = await _database.accountsDao.getAccountsByType(
        userId,
        type.value,
      );
      final accounts = entries.map(_entryToEntity).toList();
      return Right(accounts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get accounts by type: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting accounts by type: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Create/Update/Delete Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Account>> createAccount(Account account) async {
    try {
      final now = DateTime.now();
      final newAccount = account.copyWith(
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Insert into local database
      await _database.accountsDao.insertAccount(_entityToCompanion(newAccount));

      // Add to sync queue for background sync
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'accounts',
        recordId: newAccount.id,
        data: AccountModel.fromEntity(newAccount).toJson().toString(),
      );

      return Right(newAccount);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Account>> updateAccount(Account account) async {
    try {
      final updatedAccount = account.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      // Update local database
      final success = await _database.accountsDao.updateAccount(
        _entityToCompanion(updatedAccount),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Account not found for update: ${account.id}',
          ),
        );
      }

      // Add to sync queue for background sync
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'accounts',
        recordId: updatedAccount.id,
        data: AccountModel.fromEntity(updatedAccount).toJson().toString(),
      );

      return Right(updatedAccount);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String accountId) async {
    try {
      // Soft delete - deactivate account
      final success = await _database.accountsDao.deactivateAccount(accountId);

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Account not found for deletion: $accountId',
          ),
        );
      }

      // Add to sync queue for background sync
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'accounts',
        recordId: accountId,
        data: '{"is_active": false}',
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> permanentlyDeleteAccount(
    String accountId,
  ) async {
    try {
      // Hard delete from local database
      final deletedCount = await _database.accountsDao.deleteAccount(accountId);

      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(
            message: 'Account not found for permanent deletion: $accountId',
          ),
        );
      }

      // Add to sync queue for background sync
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'accounts',
        recordId: accountId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to permanently delete account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error permanently deleting account: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Balance Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Account>> updateBalance(
    String accountId,
    double newBalance,
  ) async {
    try {
      // Update balance in local database
      final success = await _database.accountsDao.updateBalance(
        accountId,
        newBalance,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Account not found for balance update: $accountId',
          ),
        );
      }

      // Get updated account
      final entry = await _database.accountsDao.getAccountById(accountId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Account not found after balance update: $accountId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'accounts',
        recordId: accountId,
        data: '{"balance": $newBalance}',
      );

      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update balance: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating balance: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Account>> adjustBalance(
    String accountId,
    double amount,
  ) async {
    try {
      // Adjust balance in local database
      final success = await _database.accountsDao.adjustBalance(
        accountId,
        amount,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Account not found for balance adjustment: $accountId',
          ),
        );
      }

      // Get updated account
      final entry = await _database.accountsDao.getAccountById(accountId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Account not found after balance adjustment: $accountId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'accounts',
        recordId: accountId,
        data: '{"balance": ${entry.balance}}',
      );

      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to adjust balance: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error adjusting balance: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalBalance(String userId) async {
    try {
      final total = await _database.accountsDao.getTotalBalance(userId);
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total balance: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total balance: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalBalanceByType(
    String userId,
    AccountType type,
  ) async {
    try {
      final accounts = await _database.accountsDao.getAccountsByType(
        userId,
        type.value,
      );
      final total = accounts.fold<double>(0.0, (sum, acc) => sum + acc.balance);
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total balance by type: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total balance by type: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getNetWorth(String userId) async {
    try {
      final accounts = await _database.accountsDao.getActiveAccounts(userId);

      double assets = 0.0;
      double liabilities = 0.0;

      for (final account in accounts) {
        final type = AccountTypeExtension.fromString(account.type);
        if (type == AccountType.creditCard || type == AccountType.loan) {
          // Liabilities reduce net worth
          liabilities += account.balance.abs();
        } else {
          // Assets increase net worth
          assets += account.balance;
        }
      }

      return Right(assets - liabilities);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to calculate net worth: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error calculating net worth: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Stream Operations (Real-time)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<Account>>> watchAccounts(String userId) {
    return _database.accountsDao.watchAllAccounts(userId).map((entries) {
      try {
        final accounts = entries.map(_entryToEntity).toList();
        return Right<Failure, List<Account>>(accounts);
      } catch (e) {
        return Left<Failure, List<Account>>(
          CacheFailure(
            message: 'Error watching accounts: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, Account>> watchAccount(String accountId) {
    // Create a stream that watches for the specific account
    return _database.accountsDao
        .watchAllAccounts('')
        .asyncMap((entries) async {
          final entry = await _database.accountsDao.getAccountById(accountId);
          return entry;
        })
        .map((entry) {
          if (entry == null) {
            return Left<Failure, Account>(
              NotFoundFailure(message: 'Account not found: $accountId'),
            );
          }
          return Right<Failure, Account>(_entryToEntity(entry));
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync accounts from remote to local database.
  ///
  /// Fetches all accounts from Firestore and updates local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      // Fetch from remote
      final remoteAccounts = await _remoteDataSource.getAccounts(userId);

      // Update local database
      for (final model in remoteAccounts) {
        final existingEntry = await _database.accountsDao.getAccountById(
          model.id,
        );

        if (existingEntry == null) {
          // Insert new account
          await _database.accountsDao.insertAccount(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else {
          // Update existing account if remote is newer
          if (model.updatedAt.isAfter(existingEntry.updatedAt)) {
            await _database.accountsDao.updateAccount(
              _modelToCompanion(model, syncStatus: 'synced'),
            );
          }
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync accounts from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing accounts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing accounts: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push pending local changes to remote.
  ///
  /// Syncs all accounts with 'pending' status to Firestore.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingAccounts = await _database.accountsDao.getPendingSync();

      for (final entry in pendingAccounts) {
        final model = AccountModel.fromEntity(_entryToEntity(entry));

        // Update remote
        await _remoteDataSource.updateAccount(userId, model);

        // Mark as synced locally
        await _database.accountsDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync accounts to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing accounts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing accounts: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [AccountEntry] to domain [Account] entity.
  Account _entryToEntity(AccountEntry entry) {
    return Account(
      id: entry.id,
      userId: entry.userId,
      name: entry.name,
      type: AccountTypeExtension.fromString(entry.type),
      balance: entry.balance,
      currency: entry.currency,
      icon: entry.icon,
      color: entry.color,
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [Account] entity to Drift [AccountsCompanion].
  AccountsCompanion _entityToCompanion(Account entity) {
    return AccountsCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      name: Value(entity.name),
      type: Value(entity.type.value),
      balance: Value(entity.balance),
      currency: Value(entity.currency),
      icon: Value(entity.icon),
      color: Value(entity.color),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [AccountModel] to Drift [AccountsCompanion].
  AccountsCompanion _modelToCompanion(
    AccountModel model, {
    String syncStatus = 'pending',
  }) {
    return AccountsCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      name: Value(model.name),
      type: Value(model.type),
      balance: Value(model.balance),
      currency: Value(model.currency),
      icon: Value(model.icon),
      color: Value(model.color),
      isActive: Value(model.isActive),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      syncStatus: Value(syncStatus),
    );
  }
}
