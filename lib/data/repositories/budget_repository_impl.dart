import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/core/utils/app_logger.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/budget_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/budget_model.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';

/// Implementation of [BudgetRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Provides budget tracking, spending updates, and period management.
class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _database;
  final BudgetRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  /// Creates [BudgetRepositoryImpl] with required dependencies.
  BudgetRepositoryImpl({
    required AppDatabase database,
    required BudgetRemoteDataSource remoteDataSource,
    Uuid? uuid,
  }) : _database = database,
       _remoteDataSource = remoteDataSource,
       _uuid = uuid ?? const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Budget>>> getBudgets(String userId) async {
    try {
      // userId is used to filter by account, but budgets don't have userId directly
      // They are associated via accountId or are global (null accountId)
      final entries = await _database.budgetsDao.getAllBudgets(null);
      AppLogger.d(
        'Fetched ${entries.length} budgets from local database',
        tag: 'BudgetRepo',
      );

      final budgets = entries.map(_entryToEntity).toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> getBudgetById(String budgetId) async {
    try {
      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Budget not found: $budgetId'));
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budget: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budget: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget?>> getBudgetByCategory(
    String userId,
    String categoryId,
  ) async {
    try {
      final entry = await _database.budgetsDao.getBudgetByCategory(categoryId);
      if (entry == null) {
        return const Right(null);
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budget by category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budget by category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> createBudget(Budget budget) async {
    try {
      final now = DateTime.now();
      final budgetId = budget.id.isEmpty ? 'budget_${_uuid.v4()}' : budget.id;
      final newBudget = budget.copyWith(
        id: budgetId,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      AppLogger.d(
        'Creating new budget with ID: ${newBudget.id}',
        tag: 'BudgetRepo',
      );

      // Insert into local database
      await _database.budgetsDao.insertBudget(_entityToCompanion(newBudget));

      // Add to sync queue for background sync
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'budgets',
        recordId: newBudget.id,
        data: jsonEncode(BudgetModel.fromEntity(newBudget).toJson()),
      );

      return Right(newBudget);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create budget: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating budget: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> updateBudget(Budget budget) async {
    try {
      final updatedBudget = budget.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      final success = await _database.budgetsDao.updateBudget(
        _entityToCompanion(updatedBudget),
      );

      if (!success) {
        return Left(
          NotFoundFailure(message: 'Budget not found for update: ${budget.id}'),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: updatedBudget.id,
        data: jsonEncode(BudgetModel.fromEntity(updatedBudget).toJson()),
      );

      return Right(updatedBudget);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update budget: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating budget: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(String budgetId) async {
    try {
      final deletedCount = await _database.budgetsDao.deleteBudget(budgetId);

      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(message: 'Budget not found for deletion: $budgetId'),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'budgets',
        recordId: budgetId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete budget: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting budget: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Budget>>> getActiveBudgets(String userId) async {
    try {
      final entries = await _database.budgetsDao.getActiveBudgets(null);
      final budgets = entries.map(_entryToEntity).toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get active budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting active budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getBudgetsByPeriod(
    String userId,
    BudgetPeriod period,
  ) async {
    try {
      final entries = await _database.budgetsDao.getAllBudgets(null);
      final budgets = entries
          .where((e) => e.period == period.value)
          .map(_entryToEntity)
          .toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budgets by period: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budgets by period: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getBudgetsByAccount(
    String accountId,
  ) async {
    try {
      final entries = await _database.budgetsDao.getAllBudgets(accountId);
      final budgets = entries.map(_entryToEntity).toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budgets by account: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budgets by account: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getExceededBudgets(
    String userId,
  ) async {
    try {
      final entries = await _database.budgetsDao.getExceededBudgets(null);
      final budgets = entries.map(_entryToEntity).toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get exceeded budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting exceeded budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getWarningBudgets(String userId) async {
    try {
      final entries = await _database.budgetsDao.getWarningBudgets(null);
      final budgets = entries.map(_entryToEntity).toList();
      return Right(budgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get warning budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting warning budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Spending Updates
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Budget>> updateSpentAmount(
    String budgetId,
    double spentAmount,
  ) async {
    try {
      final success = await _database.budgetsDao.updateSpentAmount(
        budgetId,
        spentAmount,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found for spending update: $budgetId',
          ),
        );
      }

      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(message: 'Budget not found after update: $budgetId'),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: '{"spent_amount": $spentAmount}',
      );

      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update spent amount: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating spent amount: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> addSpending(
    String budgetId,
    double amount,
  ) async {
    try {
      final success = await _database.budgetsDao.incrementSpentAmount(
        budgetId,
        amount,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found for adding spending: $budgetId',
          ),
        );
      }

      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found after adding spending: $budgetId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: '{"spent_amount": ${entry.spentAmount}}',
      );

      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to add spending: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error adding spending: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> subtractSpending(
    String budgetId,
    double amount,
  ) async {
    try {
      // Subtract is essentially adding a negative amount
      final success = await _database.budgetsDao.incrementSpentAmount(
        budgetId,
        -amount,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found for subtracting spending: $budgetId',
          ),
        );
      }

      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found after subtracting spending: $budgetId',
          ),
        );
      }

      // Ensure spent amount doesn't go negative
      final newSpentAmount = entry.spentAmount < 0 ? 0.0 : entry.spentAmount;
      if (entry.spentAmount < 0) {
        await _database.budgetsDao.updateSpentAmount(budgetId, 0.0);
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: '{"spent_amount": $newSpentAmount}',
      );

      return Right(_entryToEntity(entry).copyWith(spentAmount: newSpentAmount));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to subtract spending: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error subtracting spending: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> recalculateSpentAmount(
    String budgetId,
  ) async {
    try {
      // Get the budget to know its category and date range
      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found for recalculation: $budgetId',
          ),
        );
      }

      // Get transactions for this category
      // If budget has specific account, use that; otherwise get from all accounts
      double totalSpent = 0.0;

      if (entry.accountId != null) {
        // Get transactions for specific account and category
        final transactions = await _database.transactionsDao.getByCategory(
          entry.accountId!,
          entry.categoryId,
        );

        // Filter by date range and sum expenses
        for (final tx in transactions) {
          if (tx.type == 'expense' &&
              !tx.date.isBefore(entry.startDate) &&
              !tx.date.isAfter(entry.endDate)) {
            totalSpent += tx.amount.abs();
          }
        }
      } else {
        // Budget applies to all accounts - get all accounts first
        final accounts = await _database.accountsDao.getActiveAccounts('');

        for (final account in accounts) {
          final transactions = await _database.transactionsDao.getByCategory(
            account.id,
            entry.categoryId,
          );

          // Filter by date range and sum expenses
          for (final tx in transactions) {
            if (tx.type == 'expense' &&
                !tx.date.isBefore(entry.startDate) &&
                !tx.date.isAfter(entry.endDate)) {
              totalSpent += tx.amount.abs();
            }
          }
        }
      }

      // Update the spent amount
      await _database.budgetsDao.updateSpentAmount(budgetId, totalSpent);

      // Get updated budget
      final updatedEntry = await _database.budgetsDao.getBudgetById(budgetId);
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found after recalculation: $budgetId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: '{"spent_amount": $totalSpent}',
      );

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to recalculate spent amount: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error recalculating spent amount: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> recalculateAllBudgets(
    String userId,
  ) async {
    try {
      final entries = await _database.budgetsDao.getActiveBudgets(null);
      final recalculatedBudgets = <Budget>[];

      for (final entry in entries) {
        final result = await recalculateSpentAmount(entry.id);
        result.fold(
          (failure) => null, // Skip failures
          (budget) => recalculatedBudgets.add(budget),
        );
      }

      return Right(recalculatedBudgets);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to recalculate all budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error recalculating all budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Period Management
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Budget>> resetBudgetPeriod(String budgetId) async {
    try {
      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found for period reset: $budgetId',
          ),
        );
      }

      // Calculate new period dates
      final period = BudgetPeriodExtension.fromString(entry.period);
      final now = DateTime.now();
      final newEndDate = period.getEndDate(now);

      // Reset spent amount and update dates
      final success = await _database.budgetsDao.updateBudget(
        BudgetsCompanion(
          id: Value(budgetId),
          spentAmount: const Value(0.0),
          startDate: Value(now),
          endDate: Value(newEndDate),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      if (!success) {
        return Left(
          NotFoundFailure(message: 'Failed to reset budget period: $budgetId'),
        );
      }

      final updatedEntry = await _database.budgetsDao.getBudgetById(budgetId);
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found after period reset: $budgetId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: jsonEncode(BudgetModel.fromEntity(
          _entryToEntity(updatedEntry),
        ).toJson()),
      );

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to reset budget period: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error resetting budget period: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Budget>> rolloverBudget(String budgetId) async {
    try {
      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left(
          NotFoundFailure(message: 'Budget not found for rollover: $budgetId'),
        );
      }

      if (!entry.rollover) {
        return Left(
          ValidationFailure(
            message: 'Budget rollover is not enabled for this budget',
          ),
        );
      }

      // Calculate unused amount from previous period
      final unusedAmount = entry.amount - entry.spentAmount;
      final rolloverAmount = unusedAmount > 0 ? unusedAmount : 0.0;

      // Calculate new period dates
      final period = BudgetPeriodExtension.fromString(entry.period);
      final now = DateTime.now();
      final newEndDate = period.getEndDate(now);

      // New amount = base amount + rollover
      final newAmount = entry.amount + rolloverAmount;

      // Update budget with rolled over amount
      final success = await _database.budgetsDao.updateBudget(
        BudgetsCompanion(
          id: Value(budgetId),
          amount: Value(newAmount),
          spentAmount: const Value(0.0),
          startDate: Value(now),
          endDate: Value(newEndDate),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      if (!success) {
        return Left(
          NotFoundFailure(message: 'Failed to rollover budget: $budgetId'),
        );
      }

      final updatedEntry = await _database.budgetsDao.getBudgetById(budgetId);
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(
            message: 'Budget not found after rollover: $budgetId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'budgets',
        recordId: budgetId,
        data: jsonEncode(BudgetModel.fromEntity(
          _entryToEntity(updatedEntry),
        ).toJson()),
      );

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to rollover budget: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error rolling over budget: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<BudgetHistory>>> getBudgetHistory(
    String budgetId, {
    int limit = 12,
  }) async {
    // Budget history is not stored locally - would need to fetch from remote
    // For now, return empty list as history tracking would require additional tables
    try {
      // In a full implementation, you would store historical data when periods reset
      // For now, return empty history
      return const Right([]);
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budget history: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Aggregations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, double>> getTotalBudgetedAmount(String userId) async {
    try {
      final entries = await _database.budgetsDao.getActiveBudgets(null);
      final total = entries.fold<double>(0.0, (sum, b) => sum + b.amount);
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total budgeted amount: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total budgeted amount: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalSpentAmount(String userId) async {
    try {
      final entries = await _database.budgetsDao.getActiveBudgets(null);
      final total = entries.fold<double>(0.0, (sum, b) => sum + b.spentAmount);
      return Right(total);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total spent amount: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total spent amount: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, BudgetSummary>> getBudgetSummary(String userId) async {
    try {
      final allBudgets = await _database.budgetsDao.getAllBudgets(null);
      final activeBudgets = await _database.budgetsDao.getActiveBudgets(null);
      final exceededBudgets = await _database.budgetsDao.getExceededBudgets(
        null,
      );
      final warningBudgets = await _database.budgetsDao.getWarningBudgets(null);

      final totalBudgeted = activeBudgets.fold<double>(
        0.0,
        (sum, b) => sum + b.amount,
      );
      final totalSpent = activeBudgets.fold<double>(
        0.0,
        (sum, b) => sum + b.spentAmount,
      );

      final overallUtilization = totalBudgeted > 0
          ? totalSpent / totalBudgeted
          : 0.0;

      return Right(
        BudgetSummary(
          totalBudgets: allBudgets.length,
          activeBudgets: activeBudgets.length,
          exceededBudgets: exceededBudgets.length,
          warningBudgets: warningBudgets.length,
          totalBudgeted: totalBudgeted,
          totalSpent: totalSpent,
          overallUtilization: overallUtilization,
        ),
      );
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get budget summary: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting budget summary: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<Budget>>> watchBudgets(String userId) {
    return _database.budgetsDao.watchAllBudgets(null).map((entries) {
      try {
        final budgets = entries.map(_entryToEntity).toList();
        return Right<Failure, List<Budget>>(budgets);
      } catch (e) {
        return Left<Failure, List<Budget>>(
          CacheFailure(message: 'Error watching budgets: $e', originalError: e),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, Budget>> watchBudget(String budgetId) {
    return _database.budgetsDao.watchAllBudgets(null).asyncMap((entries) async {
      final entry = await _database.budgetsDao.getBudgetById(budgetId);
      if (entry == null) {
        return Left<Failure, Budget>(
          NotFoundFailure(message: 'Budget not found: $budgetId'),
        );
      }
      return Right<Failure, Budget>(_entryToEntity(entry));
    });
  }

  @override
  Stream<Either<Failure, List<Budget>>> watchExceededBudgets(String userId) {
    return _database.budgetsDao.watchActiveBudgets(null).map((entries) {
      try {
        final exceededEntries = entries
            .where((b) => b.spentAmount > b.amount)
            .toList();
        final budgets = exceededEntries.map(_entryToEntity).toList();
        return Right<Failure, List<Budget>>(budgets);
      } catch (e) {
        return Left<Failure, List<Budget>>(
          CacheFailure(
            message: 'Error watching exceeded budgets: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync budgets from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteBudgets = await _remoteDataSource.getBudgets(userId);

      for (final model in remoteBudgets) {
        final existingEntry = await _database.budgetsDao.getBudgetById(
          model.id,
        );

        if (existingEntry == null) {
          await _database.budgetsDao.insertBudget(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else {
          if (model.updatedAt.isAfter(existingEntry.updatedAt)) {
            await _database.budgetsDao.updateBudget(
              _modelToCompanion(model, syncStatus: 'synced'),
            );
          }
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync budgets from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingBudgets = await _database.budgetsDao.getPendingSync();

      for (final entry in pendingBudgets) {
        final model = BudgetModel.fromEntity(_entryToEntity(entry));
        await _remoteDataSource.updateBudget(userId, model);
        await _database.budgetsDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync budgets to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing budgets: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing budgets: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [BudgetEntry] to domain [Budget] entity.
  Budget _entryToEntity(BudgetEntry entry) {
    return Budget(
      id: entry.id,
      accountId: entry.accountId,
      categoryId: entry.categoryId,
      amount: entry.amount,
      spentAmount: entry.spentAmount,
      period: BudgetPeriodExtension.fromString(entry.period),
      startDate: entry.startDate,
      endDate: entry.endDate,
      rollover: entry.rollover,
      alertsEnabled: entry.alertsEnabled,
      alertThreshold: entry.alertThreshold,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [Budget] entity to Drift [BudgetsCompanion].
  BudgetsCompanion _entityToCompanion(Budget entity) {
    return BudgetsCompanion(
      id: Value(entity.id),
      accountId: Value(entity.accountId),
      categoryId: Value(entity.categoryId),
      amount: Value(entity.amount),
      spentAmount: Value(entity.spentAmount),
      period: Value(entity.period.value),
      startDate: Value(entity.startDate),
      endDate: Value(entity.endDate),
      rollover: Value(entity.rollover),
      alertsEnabled: Value(entity.alertsEnabled),
      alertThreshold: Value(entity.alertThreshold),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [BudgetModel] to Drift [BudgetsCompanion].
  BudgetsCompanion _modelToCompanion(
    BudgetModel model, {
    String syncStatus = 'pending',
  }) {
    return BudgetsCompanion(
      id: Value(model.id),
      accountId: Value(model.accountId),
      categoryId: Value(model.categoryId),
      amount: Value(model.amount),
      spentAmount: Value(model.spentAmount),
      period: Value(model.period),
      startDate: Value(model.startDate),
      endDate: Value(model.endDate),
      rollover: Value(model.rollover),
      alertsEnabled: Value(model.alertsEnabled),
      alertThreshold: Value(model.alertThreshold),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      syncStatus: Value(syncStatus),
    );
  }
}
