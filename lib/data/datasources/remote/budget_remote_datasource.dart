import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/budget_model.dart';

/// Remote datasource for Budget operations with Firebase.
///
/// Handles all budget-related Firestore operations including
/// CRUD, tracking, and analytics.
abstract class BudgetRemoteDataSource {
  /// Get all budgets for a user.
  Future<List<BudgetModel>> getBudgets(String userId);

  /// Get budget by ID.
  Future<BudgetModel?> getBudgetById(String userId, String budgetId);

  /// Create a new budget.
  Future<BudgetModel> createBudget(String userId, BudgetModel budget);

  /// Update an existing budget.
  Future<BudgetModel> updateBudget(String userId, BudgetModel budget);

  /// Delete a budget.
  Future<void> deleteBudget(String userId, String budgetId);

  /// Stream all budgets for a user.
  Stream<List<BudgetModel>> watchBudgets(String userId);

  /// Stream a single budget.
  Stream<BudgetModel?> watchBudget(String userId, String budgetId);

  /// Get active budgets only.
  Future<List<BudgetModel>> getActiveBudgets(String userId);

  /// Get budget by category.
  Future<BudgetModel?> getBudgetByCategory(String userId, String categoryId);

  /// Get budgets by period (daily, weekly, monthly, yearly).
  Future<List<BudgetModel>> getBudgetsByPeriod(String userId, String period);

  /// Update spent amount for a budget.
  Future<void> updateSpentAmount(
    String userId,
    String budgetId,
    double spentAmount,
  );

  /// Add spending to a budget (increment spent amount).
  Future<void> addSpending(String userId, String budgetId, double amount);

  /// Get exceeded budgets.
  Future<List<BudgetModel>> getExceededBudgets(String userId);

  /// Reset spent amounts for period rollover.
  Future<void> resetSpentAmounts(String userId, List<String> budgetIds);
}

/// Implementation of [BudgetRemoteDataSource] using Firebase Firestore.
class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final FirebaseService _firebaseService;

  BudgetRemoteDataSourceImpl({required FirebaseService firebaseService})
    : _firebaseService = firebaseService;

  @override
  Future<List<BudgetModel>> getBudgets(String userId) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final snapshot = await _firebaseService
          .budgetsCollection(userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
          .toList();
    }, operationName: 'get budgets');
  }

  @override
  Future<BudgetModel?> getBudgetById(String userId, String budgetId) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final doc = await _firebaseService
          .budgetsCollection(userId)
          .doc(budgetId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return BudgetModel.fromFirestore(doc.data()!, doc.id);
    }, operationName: 'get budget');
  }

  @override
  Future<BudgetModel> createBudget(String userId, BudgetModel budget) async {
    return await _firebaseService.handleFirestoreOperation(() async {
      final docRef = _firebaseService.budgetsCollection(userId).doc(budget.id);

      try {
        print('DEBUG: Creating budget at path: ${docRef.path}');
        print('DEBUG: User ID: $userId');
        print('DEBUG: Budget ID: ${budget.id}');
        
        final firestoreData = budget.toFirestore();
        print('DEBUG: Firestore data: $firestoreData');
        
        // Check if data has any null keys or problematic values
        firestoreData.forEach((key, value) {
          print('DEBUG: Field "$key" = $value (${value.runtimeType})');
        });

        await docRef.set({
          ...firestoreData,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Firestore write timed out - check network/rules');
          },
        );

        print('DEBUG: Budget created successfully with ID: ${docRef.id}');

        final doc = await docRef.get();
        return BudgetModel.fromFirestore(doc.data()!, doc.id);
      } catch (e, stackTrace) {
        print('ERROR creating budget: $e');
        print('Stack trace: $stackTrace');
        throw DatabaseException('Failed to create budget: $e');
      }
    }, operationName: 'create budget');
  }

  @override
  Future<BudgetModel> updateBudget(String userId, BudgetModel budget) async {
    return await _firebaseService.handleFirestoreOperation(() async {
      final docRef = _firebaseService.budgetsCollection(userId).doc(budget.id);

      await docRef.update({
        ...budget.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        throw NotFoundException('Budget not found after update');
      }

      return BudgetModel.fromFirestore(doc.data()!, doc.id);
    }, operationName: 'update budget');
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    return _firebaseService.handleFirestoreOperation(() async {
      await _firebaseService.budgetsCollection(userId).doc(budgetId).delete();
    }, operationName: 'delete budget');
  }

  @override
  Stream<List<BudgetModel>> watchBudgets(String userId) {
    return _firebaseService
        .budgetsCollection(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<BudgetModel?> watchBudget(String userId, String budgetId) {
    return _firebaseService
        .budgetsCollection(userId)
        .doc(budgetId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            return null;
          }
          return BudgetModel.fromFirestore(doc.data()!, doc.id);
        });
  }

  @override
  Future<List<BudgetModel>> getActiveBudgets(String userId) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final snapshot = await _firebaseService
          .budgetsCollection(userId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
          .toList();
    }, operationName: 'get active budgets');
  }

  @override
  Future<BudgetModel?> getBudgetByCategory(
    String userId,
    String categoryId,
  ) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final snapshot = await _firebaseService
          .budgetsCollection(userId)
          .where('category_id', isEqualTo: categoryId)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return BudgetModel.fromFirestore(doc.data(), doc.id);
    }, operationName: 'get budget by category');
  }

  @override
  Future<List<BudgetModel>> getBudgetsByPeriod(
    String userId,
    String period,
  ) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final snapshot = await _firebaseService
          .budgetsCollection(userId)
          .where('period', isEqualTo: period)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
          .toList();
    }, operationName: 'get budgets by period');
  }

  @override
  Future<void> updateSpentAmount(
    String userId,
    String budgetId,
    double spentAmount,
  ) async {
    return _firebaseService.handleFirestoreOperation(() async {
      await _firebaseService.budgetsCollection(userId).doc(budgetId).update({
        'spent_amount': spentAmount,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }, operationName: 'update spent amount');
  }

  @override
  Future<void> addSpending(
    String userId,
    String budgetId,
    double amount,
  ) async {
    return _firebaseService.handleFirestoreOperation(() async {
      await _firebaseService.budgetsCollection(userId).doc(budgetId).update({
        'spent_amount': FieldValue.increment(amount),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }, operationName: 'add spending');
  }

  @override
  Future<List<BudgetModel>> getExceededBudgets(String userId) async {
    return _firebaseService.handleFirestoreOperation(() async {
      // Firestore doesn't support comparing two fields directly
      // Get all active budgets and filter client-side
      final snapshot = await _firebaseService
          .budgetsCollection(userId)
          .where('is_active', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc.data(), doc.id))
          .where((budget) => budget.spentAmount >= budget.amount)
          .toList();
    }, operationName: 'get exceeded budgets');
  }

  @override
  Future<void> resetSpentAmounts(String userId, List<String> budgetIds) async {
    return _firebaseService.handleFirestoreOperation(() async {
      final batch = _firebaseService.batch();

      for (final budgetId in budgetIds) {
        final docRef = _firebaseService.budgetsCollection(userId).doc(budgetId);
        batch.update(docRef, {
          'spent_amount': 0.0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }, operationName: 'reset spent amounts');
  }
}
