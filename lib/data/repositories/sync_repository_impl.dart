import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/core/sync/sync_queue_processor.dart';
import 'package:flutter_finance_assistant/core/sync/sync_repository.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/remote.dart';
import 'package:flutter_finance_assistant/data/models/account_model.dart';
import 'package:flutter_finance_assistant/data/models/category_model.dart';
import 'package:flutter_finance_assistant/data/models/transaction_model.dart';
import 'package:flutter_finance_assistant/data/models/budget_model.dart';
import 'package:flutter_finance_assistant/data/models/recurring_rule_model.dart';
import 'package:flutter_finance_assistant/data/models/receipt_model.dart';

/// Implementation of [SyncRepository] for offline-first sync operations.
///
/// Bridges local Drift database (DAOs) with Firebase Firestore (remote datasources)
/// to provide seamless offline-first sync functionality.
class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase _database;
  final FirebaseService _firebaseService;
  final AccountRemoteDataSource _accountRemoteDataSource;
  final CategoryRemoteDataSource _categoryRemoteDataSource;
  final TransactionRemoteDataSource _transactionRemoteDataSource;
  final BudgetRemoteDataSource _budgetRemoteDataSource;
  final RecurringRuleRemoteDataSource _recurringRuleRemoteDataSource;
  final ReceiptRemoteDataSource _receiptRemoteDataSource;
  final SharedPreferences _prefs;

  /// Key prefix for storing last sync timestamps
  static const String _syncTimeKeyPrefix = 'last_sync_time_';

  /// Creates a [SyncRepositoryImpl] with required dependencies.
  SyncRepositoryImpl({
    required AppDatabase database,
    required FirebaseService firebaseService,
    required AccountRemoteDataSource accountRemoteDataSource,
    required CategoryRemoteDataSource categoryRemoteDataSource,
    required TransactionRemoteDataSource transactionRemoteDataSource,
    required BudgetRemoteDataSource budgetRemoteDataSource,
    required RecurringRuleRemoteDataSource recurringRuleRemoteDataSource,
    required ReceiptRemoteDataSource receiptRemoteDataSource,
    required SharedPreferences prefs,
  }) : _database = database,
       _firebaseService = firebaseService,
       _accountRemoteDataSource = accountRemoteDataSource,
       _categoryRemoteDataSource = categoryRemoteDataSource,
       _transactionRemoteDataSource = transactionRemoteDataSource,
       _budgetRemoteDataSource = budgetRemoteDataSource,
       _recurringRuleRemoteDataSource = recurringRuleRemoteDataSource,
       _receiptRemoteDataSource = receiptRemoteDataSource,
       _prefs = prefs;

  // ═══════════════════════════════════════════════════════════════════════════
  // Sync Queue Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<int> getPendingItemCount() async {
    return _database.syncQueueDao.getPendingCount();
  }

  @override
  Future<int> getFailedItemCount() async {
    return _database.syncQueueDao.getFailedCount();
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems({int? limit}) async {
    final entries = limit != null
        ? await _database.syncQueueDao.getNextBatch(batchSize: limit)
        : await _database.syncQueueDao.getPendingOperations();

    return entries.map(_convertToSyncQueueItem).toList();
  }

  @override
  Future<List<SyncQueueItem>> getItemsByTable(String tableName) async {
    final entries = await _database.syncQueueDao.getOperationsByTable(
      tableName,
    );
    return entries.map(_convertToSyncQueueItem).toList();
  }

  @override
  Future<void> markItemProcessed(String itemId) async {
    final id = int.tryParse(itemId);
    if (id != null) {
      await _database.syncQueueDao.removeOperation(id);
    }
  }

  @override
  Future<void> incrementRetryCount(String itemId, String errorMessage) async {
    final id = int.tryParse(itemId);
    if (id != null) {
      await _database.syncQueueDao.markFailed(id, errorMessage);
    }
  }

  @override
  Future<void> resetFailedItems() async {
    await _database.syncQueueDao.resetAllFailed();
  }

  @override
  Future<void> clearQueue() async {
    await _database.syncQueueDao.clearAll();
  }

  @override
  Future<void> addToQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final jsonPayload = jsonEncode(payload);

    switch (operation) {
      case SyncQueueTable.operationCreate:
        await _database.syncQueueDao.enqueueCreate(
          tableName: tableName,
          recordId: recordId,
          data: jsonPayload,
        );
        break;
      case SyncQueueTable.operationUpdate:
        await _database.syncQueueDao.enqueueUpdate(
          tableName: tableName,
          recordId: recordId,
          data: jsonPayload,
        );
        break;
      case SyncQueueTable.operationDelete:
        await _database.syncQueueDao.enqueueDelete(
          tableName: tableName,
          recordId: recordId,
        );
        break;
      default:
        throw UnsupportedError('Unknown operation: $operation');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote (Firestore) Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> pushToRemote({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
    required bool isNew,
  }) async {
    final userId = _firebaseService.requireUserId;

    switch (tableName) {
      case TableNames.accounts:
        final model = _accountModelFromMap(data);
        if (isNew) {
          await _accountRemoteDataSource.createAccount(userId, model);
        } else {
          await _accountRemoteDataSource.updateAccount(userId, model);
        }
        break;

      case TableNames.categories:
        final model = _categoryModelFromMap(data);
        if (isNew) {
          await _categoryRemoteDataSource.createCategory(userId, model);
        } else {
          await _categoryRemoteDataSource.updateCategory(userId, model);
        }
        break;

      case TableNames.transactions:
        final model = _transactionModelFromMap(data);
        if (isNew) {
          await _transactionRemoteDataSource.createTransaction(userId, model);
        } else {
          await _transactionRemoteDataSource.updateTransaction(userId, model);
        }
        break;

      case TableNames.budgets:
        final model = _budgetModelFromMap(data);
        if (isNew) {
          await _budgetRemoteDataSource.createBudget(userId, model);
        } else {
          await _budgetRemoteDataSource.updateBudget(userId, model);
        }
        break;

      case TableNames.recurringRules:
        final model = _recurringRuleModelFromMap(data);
        if (isNew) {
          await _recurringRuleRemoteDataSource.createRule(userId, model);
        } else {
          await _recurringRuleRemoteDataSource.updateRule(userId, model);
        }
        break;

      case TableNames.receipts:
        final model = _receiptModelFromMap(data);
        if (isNew) {
          await _receiptRemoteDataSource.createReceipt(userId, model);
        } else {
          await _receiptRemoteDataSource.updateReceipt(userId, model);
        }
        break;

      default:
        throw UnsupportedError('Unknown table for push: $tableName');
    }
  }

  @override
  Future<void> deleteFromRemote({
    required String tableName,
    required String recordId,
  }) async {
    final userId = _firebaseService.requireUserId;

    switch (tableName) {
      case TableNames.accounts:
        await _accountRemoteDataSource.deleteAccount(userId, recordId);
        break;
      case TableNames.categories:
        await _categoryRemoteDataSource.deleteCategory(userId, recordId);
        break;
      case TableNames.transactions:
        await _transactionRemoteDataSource.deleteTransaction(userId, recordId);
        break;
      case TableNames.budgets:
        await _budgetRemoteDataSource.deleteBudget(userId, recordId);
        break;
      case TableNames.recurringRules:
        await _recurringRuleRemoteDataSource.deleteRule(userId, recordId);
        break;
      case TableNames.receipts:
        await _receiptRemoteDataSource.deleteReceipt(userId, recordId);
        break;
      default:
        throw UnsupportedError('Unknown table for delete: $tableName');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchFromRemote({
    required String tableName,
    required String recordId,
  }) async {
    final userId = _firebaseService.requireUserId;

    switch (tableName) {
      case TableNames.accounts:
        final model = await _accountRemoteDataSource.getAccountById(
          userId,
          recordId,
        );
        return model?.toJson();
      case TableNames.categories:
        final model = await _categoryRemoteDataSource.getCategoryById(
          userId,
          recordId,
        );
        return model?.toJson();
      case TableNames.transactions:
        final model = await _transactionRemoteDataSource.getTransactionById(
          userId,
          recordId,
        );
        return model?.toJson();
      case TableNames.budgets:
        final model = await _budgetRemoteDataSource.getBudgetById(
          userId,
          recordId,
        );
        return model?.toJson();
      case TableNames.recurringRules:
        final model = await _recurringRuleRemoteDataSource.getRuleById(
          userId,
          recordId,
        );
        return model?.toJson();
      case TableNames.receipts:
        final model = await _receiptRemoteDataSource.getReceiptById(
          userId,
          recordId,
        );
        return model?.toJson();
      default:
        throw UnsupportedError('Unknown table for fetch: $tableName');
    }
  }

  @override
  Future<bool> checkRemoteConflict({
    required String tableName,
    required String recordId,
    required DateTime localUpdatedAt,
  }) async {
    final remoteData = await fetchFromRemote(
      tableName: tableName,
      recordId: recordId,
    );

    if (remoteData == null) {
      // Record doesn't exist remotely, no conflict
      return false;
    }

    // Check if remote has been updated after local
    final remoteUpdatedAtStr = remoteData['updated_at'] as String?;
    if (remoteUpdatedAtStr == null) {
      return false;
    }

    final remoteUpdatedAt = DateTime.parse(remoteUpdatedAtStr);
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  @override
  Future<List<Map<String, dynamic>>> pullChangesFromRemote({
    required String tableName,
    required DateTime? lastSyncTime,
  }) async {
    final userId = _firebaseService.requireUserId;
    final results = <Map<String, dynamic>>[];

    // Get collection reference based on table name
    firestore.CollectionReference<Map<String, dynamic>> collectionRef;

    switch (tableName) {
      case TableNames.accounts:
        collectionRef = _firebaseService.accountsCollection(userId);
        break;
      case TableNames.categories:
        collectionRef = _firebaseService.categoriesCollection(userId);
        break;
      case TableNames.transactions:
        collectionRef = _firebaseService.transactionsCollection(userId);
        break;
      case TableNames.budgets:
        collectionRef = _firebaseService.budgetsCollection(userId);
        break;
      case TableNames.recurringRules:
        collectionRef = _firebaseService.recurringRulesCollection(userId);
        break;
      case TableNames.receipts:
        collectionRef = _firebaseService.receiptsCollection(userId);
        break;
      default:
        throw UnsupportedError('Unknown table for pull: $tableName');
    }

    // Query for records updated since last sync
    firestore.Query<Map<String, dynamic>> query = collectionRef;

    if (lastSyncTime != null) {
      query = query.where(
        'updated_at',
        isGreaterThan: firestore.Timestamp.fromDate(lastSyncTime),
      );
    }

    final snapshot = await query.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      results.add(data);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Local (Drift) Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> updateLocal({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> data,
  }) async {
    switch (tableName) {
      case TableNames.accounts:
        await _updateLocalAccount(recordId, data);
        break;
      case TableNames.categories:
        await _updateLocalCategory(recordId, data);
        break;
      case TableNames.transactions:
        await _updateLocalTransaction(recordId, data);
        break;
      case TableNames.budgets:
        await _updateLocalBudget(recordId, data);
        break;
      case TableNames.recurringRules:
        await _updateLocalRecurringRule(recordId, data);
        break;
      case TableNames.receipts:
        await _updateLocalReceipt(recordId, data);
        break;
      default:
        throw UnsupportedError('Unknown table for local update: $tableName');
    }
  }

  @override
  Future<void> deleteLocal({
    required String tableName,
    required String recordId,
  }) async {
    switch (tableName) {
      case TableNames.accounts:
        await _database.accountsDao.deleteAccount(recordId);
        break;
      case TableNames.categories:
        await _database.categoriesDao.deleteCategory(recordId);
        break;
      case TableNames.transactions:
        await _database.transactionsDao.deleteTransaction(recordId);
        break;
      case TableNames.budgets:
        await _database.budgetsDao.deleteBudget(recordId);
        break;
      case TableNames.recurringRules:
        await _database.recurringRulesDao.deleteRule(recordId);
        break;
      case TableNames.receipts:
        await _database.receiptsDao.deleteReceipt(recordId);
        break;
      default:
        throw UnsupportedError('Unknown table for local delete: $tableName');
    }
  }

  @override
  Future<void> updateLocalSyncStatus({
    required String tableName,
    required String recordId,
    required String status,
  }) async {
    switch (tableName) {
      case TableNames.accounts:
        await _database.accountsDao.updateSyncStatus(recordId, status);
        break;
      case TableNames.categories:
        await _database.categoriesDao.updateSyncStatus(recordId, status);
        break;
      case TableNames.transactions:
        await _database.transactionsDao.updateSyncStatus(recordId, status);
        break;
      case TableNames.budgets:
        await _database.budgetsDao.updateSyncStatus(recordId, status);
        break;
      case TableNames.recurringRules:
        await _database.recurringRulesDao.updateSyncStatus(recordId, status);
        break;
      case TableNames.receipts:
        await _database.receiptsDao.updateSyncStatus(recordId, status);
        break;
      default:
        throw UnsupportedError(
          'Unknown table for sync status update: $tableName',
        );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLocalPendingRecords(
    String tableName,
  ) async {
    switch (tableName) {
      case TableNames.accounts:
        final records = await _database.accountsDao.getPendingSync();
        return records.map(_accountEntryToMap).toList();
      case TableNames.categories:
        final records = await _database.categoriesDao.getPendingSync();
        return records.map(_categoryEntryToMap).toList();
      case TableNames.transactions:
        final records = await _database.transactionsDao.getPendingSync();
        return records.map(_transactionEntryToMap).toList();
      case TableNames.budgets:
        final records = await _database.budgetsDao.getPendingSync();
        return records.map(_budgetEntryToMap).toList();
      case TableNames.recurringRules:
        final records = await _database.recurringRulesDao.getPendingSync();
        return records.map(_recurringRuleEntryToMap).toList();
      case TableNames.receipts:
        final records = await _database.receiptsDao.getPendingSync();
        return records.map(_receiptEntryToMap).toList();
      default:
        throw UnsupportedError('Unknown table for pending records: $tableName');
    }
  }

  @override
  Future<DateTime?> getLastSyncTime(String tableName) async {
    final key = '$_syncTimeKeyPrefix$tableName';
    final timestamp = _prefs.getInt(key);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  Future<void> updateLastSyncTime(String tableName, DateTime time) async {
    final key = '$_syncTimeKeyPrefix$tableName';
    await _prefs.setInt(key, time.millisecondsSinceEpoch);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods - Conversion
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert SyncQueueEntry to SyncQueueItem.
  SyncQueueItem _convertToSyncQueueItem(SyncQueueEntry entry) {
    return SyncQueueItem(
      id: entry.id.toString(),
      tableName: entry.tableNameColumn,
      recordId: entry.recordId,
      operation: entry.operation,
      payload: entry.data ?? '{}',
      retryCount: entry.retryCount,
      lastError: entry.lastError,
      createdAt: entry.createdAt,
      processedAt: null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods - Model Conversion (Map to Model)
  // ═══════════════════════════════════════════════════════════════════════════

  AccountModel _accountModelFromMap(Map<String, dynamic> data) {
    return AccountModel.fromJson(data);
  }

  CategoryModel _categoryModelFromMap(Map<String, dynamic> data) {
    return CategoryModel.fromJson(data);
  }

  TransactionModel _transactionModelFromMap(Map<String, dynamic> data) {
    return TransactionModel.fromJson(data);
  }

  BudgetModel _budgetModelFromMap(Map<String, dynamic> data) {
    return BudgetModel.fromJson(data);
  }

  RecurringRuleModel _recurringRuleModelFromMap(Map<String, dynamic> data) {
    return RecurringRuleModel.fromJson(data);
  }

  ReceiptModel _receiptModelFromMap(Map<String, dynamic> data) {
    return ReceiptModel.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods - Entry to Map Conversion
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _accountEntryToMap(AccountEntry entry) {
    return {
      'id': entry.id,
      'user_id': entry.userId,
      'name': entry.name,
      'type': entry.type,
      'balance': entry.balance,
      'currency': entry.currency,
      'icon': entry.icon,
      'color': entry.color,
      'is_active': entry.isActive,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  Map<String, dynamic> _categoryEntryToMap(CategoryEntry entry) {
    return {
      'id': entry.id,
      'user_id': entry.userId,
      'name': entry.name,
      'icon': entry.icon,
      'color': entry.color,
      'type': entry.type,
      'parent_id': entry.parentId,
      'is_system': entry.isSystem,
      'created_at': entry.createdAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  Map<String, dynamic> _transactionEntryToMap(TransactionEntry entry) {
    return {
      'id': entry.id,
      'account_id': entry.accountId,
      'category_id': entry.categoryId,
      'amount': entry.amount,
      'type': entry.type,
      'description': entry.description,
      'date': entry.date.toIso8601String(),
      'receipt_url': entry.receiptUrl,
      'location': entry.location,
      'tags': entry.tags,
      'ai_category_confidence': entry.aiCategoryConfidence,
      'is_recurring': entry.isRecurring,
      'recurring_id': entry.recurringId,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  Map<String, dynamic> _budgetEntryToMap(BudgetEntry entry) {
    return {
      'id': entry.id,
      'account_id': entry.accountId,
      'category_id': entry.categoryId,
      'amount': entry.amount,
      'spent_amount': entry.spentAmount,
      'period': entry.period,
      'start_date': entry.startDate.toIso8601String(),
      'end_date': entry.endDate.toIso8601String(),
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  Map<String, dynamic> _recurringRuleEntryToMap(RecurringRuleEntry entry) {
    return {
      'id': entry.id,
      'transaction_id': entry.transactionId,
      'frequency': entry.frequency,
      'interval': entry.interval,
      'next_date': entry.nextDate.toIso8601String(),
      'end_date': entry.endDate?.toIso8601String(),
      'is_active': entry.isActive,
      'occurrence_count': entry.occurrenceCount,
      'max_occurrences': entry.maxOccurrences,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  Map<String, dynamic> _receiptEntryToMap(ReceiptEntry entry) {
    return {
      'id': entry.id,
      'transaction_id': entry.transactionId,
      'image_url': entry.imageUrl,
      'local_path': entry.localPath,
      'ocr_raw_text': entry.ocrRawText,
      'ocr_confidence': entry.ocrConfidence,
      'merchant_name': entry.merchantName,
      'total_amount': entry.totalAmount,
      'tax_amount': entry.taxAmount,
      'receipt_date': entry.receiptDate?.toIso8601String(),
      'suggested_category_id': entry.suggestedCategoryId,
      'status': entry.status,
      'created_at': entry.createdAt.toIso8601String(),
      'sync_status': entry.syncStatus,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods - Local Update Operations
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _updateLocalAccount(String id, Map<String, dynamic> data) async {
    await _database.accountsDao.updateAccount(
      AccountsCompanion(
        id: Value(id),
        userId: Value(data['user_id'] as String),
        name: Value(data['name'] as String),
        type: Value(data['type'] as String),
        balance: Value((data['balance'] as num).toDouble()),
        currency: Value(data['currency'] as String),
        icon: Value(data['icon'] as String? ?? 'account_balance_wallet'),
        color: Value(data['color'] as int? ?? 0xFF2E7D6F),
        isActive: Value(data['is_active'] as bool? ?? true),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> _updateLocalCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _database.categoriesDao.updateCategory(
      CategoriesCompanion(
        id: Value(id),
        userId: Value(data['user_id'] as String),
        name: Value(data['name'] as String),
        icon: Value(data['icon'] as String),
        color: Value(data['color'] as int),
        type: Value(data['type'] as String),
        parentId: Value(data['parent_id'] as String?),
        isSystem: Value(data['is_system'] as bool? ?? false),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> _updateLocalTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _database.transactionsDao.updateTransaction(
      TransactionsCompanion(
        id: Value(id),
        accountId: Value(data['account_id'] as String),
        categoryId: Value(data['category_id'] as String),
        amount: Value((data['amount'] as num).toDouble()),
        type: Value(data['type'] as String),
        description: Value(data['description'] as String?),
        date: Value(DateTime.parse(data['date'] as String)),
        receiptUrl: Value(data['receipt_url'] as String?),
        location: Value(data['location'] as String?),
        tags: Value(data['tags'] as String? ?? ''),
        aiCategoryConfidence: Value(
          (data['ai_category_confidence'] as num?)?.toDouble(),
        ),
        isRecurring: Value(data['is_recurring'] as bool? ?? false),
        recurringId: Value(data['recurring_id'] as String?),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> _updateLocalBudget(String id, Map<String, dynamic> data) async {
    await _database.budgetsDao.updateBudget(
      BudgetsCompanion(
        id: Value(id),
        accountId: Value(data['account_id'] as String),
        categoryId: Value(data['category_id'] as String),
        amount: Value((data['amount'] as num).toDouble()),
        spentAmount: Value((data['spent_amount'] as num?)?.toDouble() ?? 0.0),
        period: Value(data['period'] as String),
        startDate: Value(DateTime.parse(data['start_date'] as String)),
        endDate: Value(DateTime.parse(data['end_date'] as String)),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> _updateLocalRecurringRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _database.recurringRulesDao.updateRule(
      RecurringRulesCompanion(
        id: Value(id),
        transactionId: Value(data['transaction_id'] as String),
        frequency: Value(data['frequency'] as String),
        interval: Value(data['interval'] as int? ?? 1),
        nextDate: Value(DateTime.parse(data['next_date'] as String)),
        endDate: Value(
          data['end_date'] != null
              ? DateTime.parse(data['end_date'] as String)
              : null,
        ),
        isActive: Value(data['is_active'] as bool? ?? true),
        occurrenceCount: Value(data['occurrence_count'] as int? ?? 0),
        maxOccurrences: Value(data['max_occurrences'] as int?),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        updatedAt: Value(DateTime.parse(data['updated_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }

  Future<void> _updateLocalReceipt(String id, Map<String, dynamic> data) async {
    await _database.receiptsDao.updateReceipt(
      ReceiptsCompanion(
        id: Value(id),
        transactionId: Value(data['transaction_id'] as String?),
        imageUrl: Value(data['image_url'] as String?),
        localPath: Value(data['local_path'] as String?),
        ocrRawText: Value(data['ocr_raw_text'] as String?),
        ocrConfidence: Value((data['ocr_confidence'] as num?)?.toDouble()),
        merchantName: Value(data['merchant_name'] as String?),
        totalAmount: Value((data['total_amount'] as num?)?.toDouble()),
        taxAmount: Value((data['tax_amount'] as num?)?.toDouble()),
        receiptDate: Value(
          data['receipt_date'] != null
              ? DateTime.parse(data['receipt_date'] as String)
              : null,
        ),
        suggestedCategoryId: Value(data['suggested_category_id'] as String?),
        status: Value(data['status'] as String? ?? 'pending'),
        createdAt: Value(DateTime.parse(data['created_at'] as String)),
        syncStatus: const Value(SyncStatus.synced),
      ),
    );
  }
}
