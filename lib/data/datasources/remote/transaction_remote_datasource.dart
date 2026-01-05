import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/utils/app_logger.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/transaction_model.dart';

/// Remote datasource for Transaction operations with Firebase.
///
/// Handles all transaction-related Firestore operations including
/// CRUD, filtering, search, and analytics queries.
abstract class TransactionRemoteDataSource {
  /// Get all transactions for a user.
  Future<List<TransactionModel>> getTransactions(String userId, {int? limit});

  /// Get transaction by ID.
  Future<TransactionModel?> getTransactionById(String userId, String transactionId);

  /// Create a new transaction.
  Future<TransactionModel> createTransaction(String userId, TransactionModel transaction);

  /// Update an existing transaction.
  Future<TransactionModel> updateTransaction(String userId, TransactionModel transaction);

  /// Delete a transaction.
  Future<void> deleteTransaction(String userId, String transactionId);

  /// Stream all transactions for a user.
  Stream<List<TransactionModel>> watchTransactions(String userId, {int? limit});

  /// Stream a single transaction.
  Stream<TransactionModel?> watchTransaction(String userId, String transactionId);

  /// Get transactions by date range.
  Future<List<TransactionModel>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get transactions by type (expense/income/transfer).
  Future<List<TransactionModel>> getTransactionsByType(String userId, String type);

  /// Get transactions by category.
  Future<List<TransactionModel>> getTransactionsByCategory(
    String userId,
    String categoryId,
  );

  /// Get transactions by account.
  Future<List<TransactionModel>> getTransactionsByAccount(
    String userId,
    String accountId,
  );

  /// Search transactions by description.
  Future<List<TransactionModel>> searchTransactions(String userId, String query);

  /// Get recent transactions.
  Future<List<TransactionModel>> getRecentTransactions(String userId, int limit);

  /// Batch create multiple transactions.
  Future<void> batchCreateTransactions(
    String userId,
    List<TransactionModel> transactions,
  );

  /// Batch delete multiple transactions.
  Future<void> batchDeleteTransactions(String userId, List<String> transactionIds);

  /// Get transactions modified after a timestamp (for sync).
  Future<List<TransactionModel>> getTransactionsModifiedAfter(
    String userId,
    DateTime timestamp,
  );
}

/// Implementation of [TransactionRemoteDataSource] using Firebase Firestore.
class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final FirebaseService _firebaseService;

  TransactionRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  @override
  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int? limit,
  }) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        Query<Map<String, dynamic>> query = _firebaseService
            .transactionsCollection(userId)
            .orderBy('date', descending: true);

        if (limit != null) {
          query = query.limit(limit);
        }

        final snapshot = await query.get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions',
    );
  }

  @override
  Future<TransactionModel?> getTransactionById(
    String userId,
    String transactionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .transactionsCollection(userId)
            .doc(transactionId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return TransactionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get transaction',
    );
  }

  @override
  Future<TransactionModel> createTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    AppLogger.info( 'Creating transaction: ${transaction.id}');
    print('Creating transaction: ${transaction.id}');
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService
            .transactionsCollection(userId)
            .doc(transaction.id);

        await docRef.set({
          ...transaction.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return TransactionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create transaction',
    );
  }

  @override
  Future<TransactionModel> updateTransaction(
    String userId,
    TransactionModel transaction,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService
            .transactionsCollection(userId)
            .doc(transaction.id);

        await docRef.update({
          ...transaction.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Transaction not found after update');
        }

        return TransactionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update transaction',
    );
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .transactionsCollection(userId)
            .doc(transactionId)
            .delete();
      },
      operationName: 'delete transaction',
    );
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
    String userId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firebaseService
        .transactionsCollection(userId)
        .orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  @override
  Stream<TransactionModel?> watchTransaction(
    String userId,
    String transactionId,
  ) {
    return _firebaseService
        .transactionsCollection(userId)
        .doc(transactionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return TransactionModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions by date range',
    );
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(
    String userId,
    String type,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .where('type', isEqualTo: type)
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions by type',
    );
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCategory(
    String userId,
    String categoryId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .where('category_id', isEqualTo: categoryId)
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions by category',
    );
  }

  @override
  Future<List<TransactionModel>> getTransactionsByAccount(
    String userId,
    String accountId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .where('account_id', isEqualTo: accountId)
            .orderBy('date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions by account',
    );
  }

  @override
  Future<List<TransactionModel>> searchTransactions(
    String userId,
    String query,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // Firestore doesn't support full-text search natively
        // This is a simple prefix search on description
        // For production, consider using Algolia or Firebase Extensions
        final queryLower = query.toLowerCase();

        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .orderBy('date', descending: true)
            .limit(AppConstants.maxTransactionsPerPage)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .where((t) =>
                t.description?.toLowerCase().contains(queryLower) == true ||
                t.tags.any((tag) => tag.toLowerCase().contains(queryLower)))
            .toList();
      },
      operationName: 'search transactions',
    );
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions(
    String userId,
    int limit,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .orderBy('date', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get recent transactions',
    );
  }

  @override
  Future<void> batchCreateTransactions(
    String userId,
    List<TransactionModel> transactions,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // Firestore batch limit is 500 operations
        const batchSize = 500;

        for (var i = 0; i < transactions.length; i += batchSize) {
          final batch = _firebaseService.batch();
          final end = (i + batchSize < transactions.length)
              ? i + batchSize
              : transactions.length;

          for (var j = i; j < end; j++) {
            final transaction = transactions[j];
            final docRef = _firebaseService
                .transactionsCollection(userId)
                .doc(transaction.id);

            batch.set(docRef, {
              ...transaction.toFirestore(),
              'created_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
        }
      },
      operationName: 'batch create transactions',
    );
  }

  @override
  Future<void> batchDeleteTransactions(
    String userId,
    List<String> transactionIds,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        const batchSize = 500;

        for (var i = 0; i < transactionIds.length; i += batchSize) {
          final batch = _firebaseService.batch();
          final end = (i + batchSize < transactionIds.length)
              ? i + batchSize
              : transactionIds.length;

          for (var j = i; j < end; j++) {
            final docRef = _firebaseService
                .transactionsCollection(userId)
                .doc(transactionIds[j]);
            batch.delete(docRef);
          }

          await batch.commit();
        }
      },
      operationName: 'batch delete transactions',
    );
  }

  @override
  Future<List<TransactionModel>> getTransactionsModifiedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .transactionsCollection(userId)
            .where('updated_at', isGreaterThan: timestamp.toIso8601String())
            .orderBy('updated_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get transactions modified after',
    );
  }
}
