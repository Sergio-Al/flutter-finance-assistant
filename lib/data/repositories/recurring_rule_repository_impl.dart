import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/recurring_rule_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/recurring_rule_model.dart';
import 'package:flutter_finance_assistant/domain/entities/recurring_rule.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/repositories/recurring_rule_repository.dart';

/// Implementation of [RecurringRuleRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Handles recurring transaction rules, scheduling, and automatic transaction creation.
class RecurringRuleRepositoryImpl implements RecurringRuleRepository {
  final AppDatabase _database;
  final RecurringRuleRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  /// Creates [RecurringRuleRepositoryImpl] with required data sources.
  RecurringRuleRepositoryImpl({
    required AppDatabase database,
    required RecurringRuleRemoteDataSource remoteDataSource,
    Uuid? uuid,
  })  : _database = database,
        _remoteDataSource = remoteDataSource,
        _uuid = uuid ?? const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<RecurringRule>>> getRecurringRules(
    String userId,
  ) async {
    try {
      final entries = await _database.recurringRulesDao.getAllRules();
      final rules = entries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get recurring rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting recurring rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> getRecurringRuleById(
    String ruleId,
  ) async {
    try {
      final entry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (entry == null) {
        return Left(NotFoundFailure(
          message: 'Recurring rule not found: $ruleId',
        ));
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get recurring rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting recurring rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> createRecurringRule(
    RecurringRule rule,
  ) async {
    try {
      final now = DateTime.now();
      final newRule = rule.copyWith(
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      await _database.recurringRulesDao.insertRule(
        _entityToCompanion(newRule),
      );

      // Add to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'recurring_rules',
        recordId: newRule.id,
        data: jsonEncode(RecurringRuleModel.fromEntity(newRule).toJson()),
      );

      return Right(newRule);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to create recurring rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error creating recurring rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> updateRecurringRule(
    RecurringRule rule,
  ) async {
    try {
      final updatedRule = rule.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      final success = await _database.recurringRulesDao.updateRule(
        _entityToCompanion(updatedRule),
      );

      if (!success) {
        return Left(NotFoundFailure(
          message: 'Recurring rule not found for update: ${rule.id}',
        ));
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'recurring_rules',
        recordId: updatedRule.id,
        data: jsonEncode(RecurringRuleModel.fromEntity(updatedRule).toJson()),
      );

      return Right(updatedRule);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to update recurring rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error updating recurring rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringRule(String ruleId) async {
    try {
      final deletedCount = await _database.recurringRulesDao.deleteRule(ruleId);
      if (deletedCount == 0) {
        return Left(NotFoundFailure(
          message: 'Recurring rule not found for deletion: $ruleId',
        ));
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'recurring_rules',
        recordId: ruleId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to delete recurring rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error deleting recurring rule: $e',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<RecurringRule>>> getActiveRules(
    String userId,
  ) async {
    try {
      final entries = await _database.recurringRulesDao.getActiveRules();
      final rules = entries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get active rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting active rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getInactiveRules(
    String userId,
  ) async {
    try {
      final allEntries = await _database.recurringRulesDao.getAllRules();
      final inactiveEntries = allEntries.where((e) => !e.isActive).toList();
      final rules = inactiveEntries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get inactive rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting inactive rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getCompletedRules(
    String userId,
  ) async {
    try {
      final allEntries = await _database.recurringRulesDao.getAllRules();
      final completedEntries = allEntries.where((e) {
        final rule = _entryToEntity(e);
        return rule.isComplete;
      }).toList();
      final rules = completedEntries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get completed rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting completed rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getRulesByFrequency(
    String userId,
    RecurringFrequency frequency,
  ) async {
    try {
      final allEntries = await _database.recurringRulesDao.getAllRules();
      final filteredEntries = allEntries
          .where((e) => e.frequency == frequency.value)
          .toList();
      final rules = filteredEntries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get rules by frequency: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting rules by frequency: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getDueRules(String userId) async {
    try {
      final entries = await _database.recurringRulesDao.getDueRules();
      final rules = entries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get due rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting due rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<RecurringRule>>> getRulesDueInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final activeEntries = await _database.recurringRulesDao.getActiveRules();
      final filteredEntries = activeEntries.where((e) {
        return e.nextDate.isAfter(startDate) && e.nextDate.isBefore(endDate);
      }).toList();
      final rules = filteredEntries.map(_entryToEntity).toList();
      return Right(rules);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get rules due in range: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting rules due in range: $e',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Rule Management
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, RecurringRule>> activateRule(String ruleId) async {
    try {
      final success = await _database.recurringRulesDao.activateRule(ruleId);
      if (!success) {
        return Left(NotFoundFailure(
          message: 'Rule not found for activation: $ruleId',
        ));
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'recurring_rules',
        recordId: ruleId,
        data: '{"isActive": true}',
      );

      final updatedEntry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (updatedEntry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found after activation',
        ));
      }

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to activate rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error activating rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> deactivateRule(String ruleId) async {
    try {
      final success = await _database.recurringRulesDao.deactivateRule(ruleId);
      if (!success) {
        return Left(NotFoundFailure(
          message: 'Rule not found for deactivation: $ruleId',
        ));
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'recurring_rules',
        recordId: ruleId,
        data: '{"isActive": false}',
      );

      final updatedEntry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (updatedEntry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found after deactivation',
        ));
      }

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to deactivate rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error deactivating rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> skipNextOccurrence(
    String ruleId,
  ) async {
    try {
      final entry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (entry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found for skipping: $ruleId',
        ));
      }

      final rule = _entryToEntity(entry);
      final nextDate = rule.calculateNextDate();

      final success = await _database.recurringRulesDao.updateNextDate(
        ruleId,
        nextDate,
      );

      if (!success) {
        return Left(NotFoundFailure(
          message: 'Failed to skip next occurrence',
        ));
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'recurring_rules',
        recordId: ruleId,
        data: '{"nextDate": "${nextDate.toIso8601String()}"}',
      );

      final updatedEntry = await _database.recurringRulesDao.getRuleById(ruleId);
      return Right(_entryToEntity(updatedEntry!));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to skip next occurrence: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error skipping next occurrence: $e',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Processing
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Transaction>> processRule(String ruleId) async {
    try {
      final entry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (entry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found for processing: $ruleId',
        ));
      }

      final rule = _entryToEntity(entry);

      // Check if rule is due
      if (!rule.isDue) {
        return Left(ValidationFailure(
          message: 'Rule is not due for processing yet',
        ));
      }

      // Get the template transaction
      final templateEntry = await _database.transactionsDao.getTransactionById(
        rule.transactionId,
      );
      if (templateEntry == null) {
        return Left(NotFoundFailure(
          message: 'Template transaction not found: ${rule.transactionId}',
        ));
      }

      // Create new transaction from template
      final now = DateTime.now();
      final newTransactionId = 'txn_${_uuid.v4()}';

      final newTransaction = Transaction(
        id: newTransactionId,
        accountId: templateEntry.accountId,
        categoryId: templateEntry.categoryId,
        amount: templateEntry.amount,
        type: TransactionTypeExtension.fromString(templateEntry.type),
        description: templateEntry.description,
        date: now,
        tags: [],
        isRecurring: true,
        recurringId: ruleId,
        toAccountId: templateEntry.toAccountId,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Insert the new transaction
      await _database.transactionsDao.insertTransaction(
        TransactionsCompanion(
          id: Value(newTransaction.id),
          accountId: Value(newTransaction.accountId),
          categoryId: Value(newTransaction.categoryId),
          amount: Value(newTransaction.amount),
          type: Value(newTransaction.type.value),
          description: Value(newTransaction.description),
          date: Value(newTransaction.date),
          isRecurring: Value(newTransaction.isRecurring),
          recurringId: Value(newTransaction.recurringId),
          toAccountId: Value(newTransaction.toAccountId),
          createdAt: Value(newTransaction.createdAt),
          updatedAt: Value(newTransaction.updatedAt),
          syncStatus: Value(newTransaction.syncStatus),
        ),
      );

      // Update the rule's next date and occurrence count
      await updateNextDate(ruleId);
      await incrementOccurrenceCount(ruleId);

      // Add transaction to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'transactions',
        recordId: newTransactionId,
        data: newTransaction.toString(),
      );

      return Right(newTransaction);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to process rule: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error processing rule: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> processAllDueRules(
    String userId,
  ) async {
    try {
      final dueResult = await getDueRules(userId);

      return dueResult.fold(
        (failure) => Left(failure),
        (dueRules) async {
          final createdTransactions = <Transaction>[];

          for (final rule in dueRules) {
            final result = await processRule(rule.id);
            result.fold(
              (failure) {
                // Log failure but continue processing other rules
              },
              (transaction) {
                createdTransactions.add(transaction);
              },
            );
          }

          return Right(createdTransactions);
        },
      );
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error processing all due rules: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> updateNextDate(String ruleId) async {
    try {
      final entry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (entry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found for updating next date: $ruleId',
        ));
      }

      final rule = _entryToEntity(entry);
      final nextDate = rule.calculateNextDate();

      final success = await _database.recurringRulesDao.updateNextDate(
        ruleId,
        nextDate,
      );

      if (!success) {
        return Left(NotFoundFailure(
          message: 'Failed to update next date',
        ));
      }

      // Check if rule should be deactivated (completed)
      final updatedRule = rule.copyWith(nextDate: nextDate);
      if (updatedRule.isComplete) {
        await _database.recurringRulesDao.deactivateRule(ruleId);
      }

      final updatedEntry = await _database.recurringRulesDao.getRuleById(ruleId);
      return Right(_entryToEntity(updatedEntry!));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to update next date: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error updating next date: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, RecurringRule>> incrementOccurrenceCount(
    String ruleId,
  ) async {
    try {
      final success = await _database.recurringRulesDao.incrementOccurrenceCount(
        ruleId,
      );

      if (!success) {
        return Left(NotFoundFailure(
          message: 'Rule not found for incrementing count: $ruleId',
        ));
      }

      final updatedEntry = await _database.recurringRulesDao.getRuleById(ruleId);
      if (updatedEntry == null) {
        return Left(NotFoundFailure(
          message: 'Rule not found after incrementing count',
        ));
      }

      return Right(_entryToEntity(updatedEntry));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to increment occurrence count: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error incrementing occurrence count: $e',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Projections
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<ProjectedTransaction>>> getProjectedTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final activeEntries = await _database.recurringRulesDao.getActiveRules();
      final projections = <ProjectedTransaction>[];

      for (final entry in activeEntries) {
        final rule = _entryToEntity(entry);

        // Get template transaction for details
        final templateEntry = await _database.transactionsDao.getTransactionById(
          rule.transactionId,
        );
        if (templateEntry == null) continue;

        // Project all occurrences within the date range
        var projectedDate = rule.nextDate;
        while (projectedDate.isBefore(endDate)) {
          if (projectedDate.isAfter(startDate)) {
            final isExpense = templateEntry.type == 'expense';
            projections.add(ProjectedTransaction(
              recurringRuleId: rule.id,
              projectedDate: projectedDate,
              amount: templateEntry.amount,
              categoryId: templateEntry.categoryId,
              accountId: templateEntry.accountId,
              description: templateEntry.description,
              isExpense: isExpense,
            ));
          }

          // Calculate next projected date
          projectedDate = rule.frequency.getNextDate(
            projectedDate,
            rule.interval,
          );

          // Check for end date
          if (rule.endDate != null && projectedDate.isAfter(rule.endDate!)) {
            break;
          }
        }
      }

      // Sort by date
      projections.sort((a, b) => a.projectedDate.compareTo(b.projectedDate));

      return Right(projections);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(
        message: 'Failed to get projected transactions: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(CacheFailure(
        message: 'Unexpected error getting projected transactions: $e',
        originalError: e,
      ));
    }
  }

  @override
  Future<Either<Failure, double>> getProjectedIncome(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final projectionsResult = await getProjectedTransactions(
      userId,
      startDate,
      endDate,
    );

    return projectionsResult.fold(
      (failure) => Left(failure),
      (projections) {
        final income = projections
            .where((p) => !p.isExpense)
            .fold<double>(0, (sum, p) => sum + p.amount);
        return Right(income);
      },
    );
  }

  @override
  Future<Either<Failure, double>> getProjectedExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final projectionsResult = await getProjectedTransactions(
      userId,
      startDate,
      endDate,
    );

    return projectionsResult.fold(
      (failure) => Left(failure),
      (projections) {
        final expenses = projections
            .where((p) => p.isExpense)
            .fold<double>(0, (sum, p) => sum + p.amount);
        return Right(expenses);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<RecurringRule>>> watchRecurringRules(
    String userId,
  ) {
    return _database.recurringRulesDao.watchActiveRules().map((entries) {
      try {
        final rules = entries.map(_entryToEntity).toList();
        return Right<Failure, List<RecurringRule>>(rules);
      } catch (e) {
        return Left<Failure, List<RecurringRule>>(CacheFailure(
          message: 'Error watching recurring rules: $e',
          originalError: e,
        ));
      }
    });
  }

  @override
  Stream<Either<Failure, List<RecurringRule>>> watchDueRules(String userId) {
    return _database.recurringRulesDao.watchDueRules().map((entries) {
      try {
        final rules = entries.map(_entryToEntity).toList();
        return Right<Failure, List<RecurringRule>>(rules);
      } catch (e) {
        return Left<Failure, List<RecurringRule>>(CacheFailure(
          message: 'Error watching due rules: $e',
          originalError: e,
        ));
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync recurring rules from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteRules = await _remoteDataSource.getRules(userId);

      for (final model in remoteRules) {
        final existingEntry = await _database.recurringRulesDao.getRuleById(
          model.id,
        );

        if (existingEntry == null) {
          await _database.recurringRulesDao.insertRule(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else if (model.updatedAt.isAfter(existingEntry.updatedAt)) {
          await _database.recurringRulesDao.updateRule(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: 'Failed to sync recurring rules from remote: ${e.message}',
        originalError: e,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: 'Network error syncing recurring rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(SyncFailure(
        message: 'Unexpected error syncing recurring rules: $e',
        originalError: e,
      ));
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingRules = await _database.recurringRulesDao.getPendingSync();

      for (final entry in pendingRules) {
        final model = RecurringRuleModel.fromEntity(_entryToEntity(entry));
        await _remoteDataSource.updateRule(userId, model);
        await _database.recurringRulesDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: 'Failed to sync recurring rules to remote: ${e.message}',
        originalError: e,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: 'Network error syncing recurring rules: ${e.message}',
        originalError: e,
      ));
    } catch (e) {
      return Left(SyncFailure(
        message: 'Unexpected error syncing recurring rules: $e',
        originalError: e,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [RecurringRuleEntry] to domain [RecurringRule] entity.
  RecurringRule _entryToEntity(RecurringRuleEntry entry) {
    return RecurringRule(
      id: entry.id,
      transactionId: entry.transactionId,
      frequency: RecurringFrequencyExtension.fromString(entry.frequency),
      interval: entry.interval,
      nextDate: entry.nextDate,
      endDate: entry.endDate,
      isActive: entry.isActive,
      occurrenceCount: entry.occurrenceCount,
      maxOccurrences: entry.maxOccurrences,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [RecurringRule] entity to Drift [RecurringRulesCompanion].
  RecurringRulesCompanion _entityToCompanion(RecurringRule entity) {
    return RecurringRulesCompanion(
      id: Value(entity.id),
      transactionId: Value(entity.transactionId),
      frequency: Value(entity.frequency.value),
      interval: Value(entity.interval),
      nextDate: Value(entity.nextDate),
      endDate: Value(entity.endDate),
      isActive: Value(entity.isActive),
      occurrenceCount: Value(entity.occurrenceCount),
      maxOccurrences: Value(entity.maxOccurrences),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [RecurringRuleModel] to Drift [RecurringRulesCompanion].
  RecurringRulesCompanion _modelToCompanion(
    RecurringRuleModel model, {
    String syncStatus = 'pending',
  }) {
    return RecurringRulesCompanion(
      id: Value(model.id),
      transactionId: Value(model.transactionId),
      frequency: Value(model.frequency),
      interval: Value(model.interval),
      nextDate: Value(model.nextDate),
      endDate: Value(model.endDate),
      isActive: Value(model.isActive),
      occurrenceCount: Value(model.occurrenceCount),
      maxOccurrences: Value(model.maxOccurrences),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
      syncStatus: Value(syncStatus),
    );
  }
}
