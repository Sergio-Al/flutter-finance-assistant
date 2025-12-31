import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/transaction_model.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

/// Implementation of [TransactionRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Handles all financial transaction operations including CRUD, filtering,
/// search, and analytics aggregations.
class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _database;
  final TransactionRemoteDataSource _remoteDataSource;

  /// Creates [TransactionRepositoryImpl] with required data sources.
  TransactionRepositoryImpl({
    required AppDatabase database,
    required TransactionRemoteDataSource remoteDataSource,
  }) : _database = database,
       _remoteDataSource = remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions(
    String accountId,
  ) async {
    try {
      final entries = await _database.transactionsDao.getAllTransactions(
        accountId,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Transaction>> getTransactionById(
    String transactionId,
  ) async {
    try {
      final entry = await _database.transactionsDao.getTransactionById(
        transactionId,
      );
      if (entry == null) {
        return Left(
          NotFoundFailure(message: 'Transaction not found: $transactionId'),
        );
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transaction: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transaction: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Transaction>> createTransaction(
    Transaction transaction,
  ) async {
    try {
      final now = DateTime.now();
      // generate a new ID for the transaction
      final newTransaction = transaction.copyWith(
        id: const Uuid().v4(),
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );


      final companion = _entityToCompanion(newTransaction);

      print('Creating transaction: $companion');
      
      await _database.transactionsDao.insertTransaction(companion);

      print('Transaction created locally with ID: ${newTransaction.id}');

      // Add to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'transactions',
        recordId: newTransaction.id,
        data: TransactionModel.fromEntity(newTransaction).toJson().toString(),
      );

      return Right(newTransaction);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create transaction: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating transaction: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  ) async {
    try {
      final updatedTransaction = transaction.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      final success = await _database.transactionsDao.updateTransaction(
        _entityToCompanion(updatedTransaction),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Transaction not found for update: ${transaction.id}',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'transactions',
        recordId: updatedTransaction.id,
        data: TransactionModel.fromEntity(
          updatedTransaction,
        ).toJson().toString(),
      );

      return Right(updatedTransaction);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update transaction: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating transaction: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String transactionId) async {
    try {
      final deletedCount = await _database.transactionsDao.deleteTransaction(
        transactionId,
      );
      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(
            message: 'Transaction not found for deletion: $transactionId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'transactions',
        recordId: transactionId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete transaction: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting transaction: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByType(
    String accountId,
    TransactionType type,
  ) async {
    try {
      final entries = await _database.transactionsDao.getByType(
        accountId,
        type.value,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions by type: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transactions by type: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByCategory(
    String accountId,
    String categoryId,
  ) async {
    try {
      final entries = await _database.transactionsDao.getByCategory(
        accountId,
        categoryId,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions by category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transactions by category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByDateRange(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions by date range: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transactions by date range: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByMonth(
    String accountId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions by month: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transactions by month: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getRecentTransactions(
    String accountId, {
    int limit = 10,
  }) async {
    try {
      final entries = await _database.transactionsDao.getRecentTransactions(
        accountId,
        limit: limit,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get recent transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting recent transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getAllUserTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      // First get all account IDs for this user
      final accounts = await _database.accountsDao.getAllAccounts(userId);
      final accountIds = accounts.map((a) => a.id).toList();

      if (accountIds.isEmpty) {
        return const Right([]);
      }

      final start = startDate ?? DateTime(2000);
      final end = endDate ?? DateTime.now().add(const Duration(days: 1));

      final entries = await _database.transactionsDao.getForAccounts(
        accountIds,
        start,
        end,
      );

      var transactions = entries.map(_entryToEntity).toList();

      if (limit != null && transactions.length > limit) {
        transactions = transactions.take(limit).toList();
      }

      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get all user transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting all user transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search & Filter
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Transaction>>> searchTransactions(
    String accountId,
    String query,
  ) async {
    try {
      final entries = await _database.transactionsDao.search(accountId, query);
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error searching transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getFilteredTransactions({
    required String accountId,
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    int? limit,
    int? offset,
  }) async {
    try {
      // Start with all transactions for the account
      var entries = await _database.transactionsDao.getAllTransactions(
        accountId,
      );

      // Apply filters
      if (type != null) {
        entries = entries.where((e) => e.type == type.value).toList();
      }

      if (categoryId != null) {
        entries = entries.where((e) => e.categoryId == categoryId).toList();
      }

      if (startDate != null) {
        entries = entries
            .where(
              (e) =>
                  e.date.isAfter(startDate) ||
                  e.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        entries = entries
            .where(
              (e) =>
                  e.date.isBefore(endDate) || e.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (minAmount != null) {
        entries = entries.where((e) => e.amount >= minAmount).toList();
      }

      if (maxAmount != null) {
        entries = entries.where((e) => e.amount <= maxAmount).toList();
      }

      // Apply pagination
      if (offset != null) {
        entries = entries.skip(offset).toList();
      }

      if (limit != null) {
        entries = entries.take(limit).toList();
      }

      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get filtered transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting filtered transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Aggregations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, double>> getTotalSpent(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final total = await _database.transactionsDao.getSumByType(
        accountId,
        'expense',
        startDate,
        endDate,
      );
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total spent: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total spent: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncome(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final total = await _database.transactionsDao.getSumByType(
        accountId,
        'income',
        startDate,
        endDate,
      );
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total income: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total income: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getSpendingByCategory(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get only expenses grouped by category
      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );

      final expenseEntries = entries.where((e) => e.type == 'expense');

      final Map<String, double> spendingByCategory = {};
      for (final entry in expenseEntries) {
        spendingByCategory[entry.categoryId] =
            (spendingByCategory[entry.categoryId] ?? 0) + entry.amount;
      }

      return Right(spendingByCategory);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get spending by category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting spending by category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, double>>> getDailySpending(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );

      final expenseEntries = entries.where((e) => e.type == 'expense');

      final Map<DateTime, double> dailySpending = {};
      for (final entry in expenseEntries) {
        // Normalize date to midnight for grouping
        final dateKey = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + entry.amount;
      }

      return Right(dailySpending);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get daily spending: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting daily spending: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<int, double>>> getMonthlySpending(
    String accountId,
    int year,
  ) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );

      final expenseEntries = entries.where((e) => e.type == 'expense');

      final Map<int, double> monthlySpending = {};
      for (var month = 1; month <= 12; month++) {
        monthlySpending[month] = 0;
      }

      for (final entry in expenseEntries) {
        final month = entry.date.month;
        monthlySpending[month] = (monthlySpending[month] ?? 0) + entry.amount;
      }

      return Right(monthlySpending);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get monthly spending: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting monthly spending: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getTransactionCountByCategory(
    String accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final entries = await _database.transactionsDao.getByDateRange(
        accountId,
        startDate,
        endDate,
      );

      final Map<String, int> countByCategory = {};
      for (final entry in entries) {
        countByCategory[entry.categoryId] =
            (countByCategory[entry.categoryId] ?? 0) + 1;
      }

      return Right(countByCategory);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transaction count by category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting transaction count by category: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Recurring Transactions
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Transaction>>> getRecurringTransactions(
    String accountId,
  ) async {
    try {
      final entries = await _database.transactionsDao.getRecurringTransactions(
        accountId,
      );
      final transactions = entries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get recurring transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting recurring transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByRecurringRule(
    String recurringId,
  ) async {
    try {
      // Get the recurring rule to find the template transaction
      final ruleEntry = await _database.recurringRulesDao.getRuleById(
        recurringId,
      );
      if (ruleEntry == null) {
        return const Right([]);
      }

      // Get all transactions for the account of the template transaction
      final templateEntry = await _database.transactionsDao.getTransactionById(
        ruleEntry.transactionId,
      );
      if (templateEntry == null) {
        return const Right([]);
      }

      final entries = await _database.transactionsDao.getAllTransactions(
        templateEntry.accountId,
      );

      final filteredEntries = entries
          .where((e) => e.recurringId == recurringId)
          .toList();

      final transactions = filteredEntries.map(_entryToEntity).toList();
      return Right(transactions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get transactions by recurring rule: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message:
              'Unexpected error getting transactions by recurring rule: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<Transaction>>> watchTransactions(
    String accountId,
  ) {
    return _database.transactionsDao.watchAllTransactions(accountId).map((
      entries,
    ) {
      try {
        final transactions = entries.map(_entryToEntity).toList();
        return Right<Failure, List<Transaction>>(transactions);
      } catch (e) {
        return Left<Failure, List<Transaction>>(
          CacheFailure(
            message: 'Error watching transactions: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<Transaction>>> watchRecentTransactions(
    String accountId, {
    int limit = 10,
  }) {
    return _database.transactionsDao
        .watchRecentTransactions(accountId, limit: limit)
        .map((entries) {
          try {
            final transactions = entries.map(_entryToEntity).toList();
            return Right<Failure, List<Transaction>>(transactions);
          } catch (e) {
            return Left<Failure, List<Transaction>>(
              CacheFailure(
                message: 'Error watching recent transactions: $e',
                originalError: e,
              ),
            );
          }
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync transactions from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteTransactions = await _remoteDataSource.getTransactions(
        userId,
      );

      for (final model in remoteTransactions) {
        final existingEntry = await _database.transactionsDao
            .getTransactionById(model.id);

        if (existingEntry == null) {
          await _database.transactionsDao.insertTransaction(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else if (model.updatedAt.isAfter(existingEntry.updatedAt)) {
          await _database.transactionsDao.updateTransaction(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync transactions from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingTransactions = await _database.transactionsDao
          .getPendingSync();

      for (final entry in pendingTransactions) {
        final model = TransactionModel.fromEntity(_entryToEntity(entry));
        await _remoteDataSource.updateTransaction(userId, model);
        await _database.transactionsDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync transactions to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing transactions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing transactions: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Batch sync from remote with timestamp-based incremental updates.
  Future<Either<Failure, void>> syncFromRemoteIncremental(
    String userId,
    DateTime lastSyncTime,
  ) async {
    try {
      final modifiedTransactions = await _remoteDataSource
          .getTransactionsModifiedAfter(userId, lastSyncTime);

      for (final model in modifiedTransactions) {
        final existingEntry = await _database.transactionsDao
            .getTransactionById(model.id);

        if (existingEntry == null) {
          await _database.transactionsDao.insertTransaction(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else {
          await _database.transactionsDao.updateTransaction(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed incremental sync: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error during incremental sync: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error during incremental sync: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [TransactionEntry] to domain [Transaction] entity.
  Transaction _entryToEntity(TransactionEntry entry) {
    return Transaction(
      id: entry.id,
      accountId: entry.accountId,
      categoryId: entry.categoryId,
      amount: entry.amount,
      type: TransactionTypeExtension.fromString(entry.type),
      description: entry.description,
      date: entry.date,
      receiptUrl: entry.receiptUrl,
      location: entry.location,
      tags: _parseTagsFromString(entry.tags),
      aiCategoryConfidence: entry.aiCategoryConfidence,
      isRecurring: entry.isRecurring,
      recurringId: entry.recurringId,
      toAccountId: entry.toAccountId,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [Transaction] entity to Drift [TransactionsCompanion].
  TransactionsCompanion _entityToCompanion(Transaction entity) {
    return TransactionsCompanion(
      id: Value(entity.id),
      accountId: Value(entity.accountId),
      categoryId: Value(entity.categoryId),
      amount: Value(entity.amount),
      type: Value(entity.type.value),
      description: Value(entity.description),
      date: Value(entity.date),
      receiptUrl: Value(entity.receiptUrl),
      location: Value(entity.location),
      tags: Value(_tagsToString(entity.tags)),
      aiCategoryConfidence: Value(entity.aiCategoryConfidence),
      isRecurring: Value(entity.isRecurring),
      recurringId: Value(entity.recurringId),
      toAccountId: Value(entity.toAccountId),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [TransactionModel] to Drift [TransactionsCompanion].
  TransactionsCompanion _modelToCompanion(
    TransactionModel model, {
    String syncStatus = 'pending',
  }) {
    return TransactionsCompanion(
      id: Value(model.id),
      accountId: Value(model.accountId),
      categoryId: Value(model.categoryId),
      amount: Value(model.amount),
      type: Value(model.type),
      description: Value(model.description),
      date: Value(model.date),
      receiptUrl: Value(model.receiptUrl),
      location: Value(model.location),
      tags: Value(_tagsToString(model.tags)),
      aiCategoryConfidence: Value(model.aiCategoryConfidence),
      isRecurring: Value(model.isRecurring),
      recurringId: Value(model.recurringId),
      toAccountId: Value(model.toAccountId),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  /// Parse tags string to list.
  List<String> _parseTagsFromString(String? tagsString) {
    if (tagsString == null || tagsString.isEmpty) {
      return [];
    }
    return tagsString
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Convert tags list to string for storage.
  String _tagsToString(List<String> tags) {
    return tags.join(',');
  }
}
