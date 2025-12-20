import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/recurring_rule_model.dart';

/// Remote datasource for Recurring Rule operations with Firebase.
///
/// Handles all recurring transaction rule-related Firestore operations
/// including CRUD and schedule management.
abstract class RecurringRuleRemoteDataSource {
  /// Get all recurring rules for a user.
  Future<List<RecurringRuleModel>> getRules(String userId);

  /// Get recurring rule by ID.
  Future<RecurringRuleModel?> getRuleById(String userId, String ruleId);

  /// Create a new recurring rule.
  Future<RecurringRuleModel> createRule(String userId, RecurringRuleModel rule);

  /// Update an existing recurring rule.
  Future<RecurringRuleModel> updateRule(String userId, RecurringRuleModel rule);

  /// Delete a recurring rule.
  Future<void> deleteRule(String userId, String ruleId);

  /// Stream all recurring rules for a user.
  Stream<List<RecurringRuleModel>> watchRules(String userId);

  /// Get active recurring rules.
  Future<List<RecurringRuleModel>> getActiveRules(String userId);

  /// Get rules due for execution (nextExecution <= date).
  Future<List<RecurringRuleModel>> getDueRules(String userId, DateTime date);

  /// Update last executed timestamp.
  Future<void> updateLastExecuted(String userId, String ruleId, DateTime date);

  /// Update next execution timestamp.
  Future<void> updateNextExecution(String userId, String ruleId, DateTime date);

  /// Deactivate a rule.
  Future<void> deactivateRule(String userId, String ruleId);

  /// Batch update next execution dates.
  Future<void> batchUpdateNextExecution(
    String userId,
    Map<String, DateTime> ruleNextDates,
  );
}

/// Implementation of [RecurringRuleRemoteDataSource] using Firebase Firestore.
class RecurringRuleRemoteDataSourceImpl implements RecurringRuleRemoteDataSource {
  final FirebaseService _firebaseService;

  RecurringRuleRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  @override
  Future<List<RecurringRuleModel>> getRules(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .recurringRulesCollection(userId)
            .orderBy('next_execution')
            .get();

        return snapshot.docs
            .map((doc) => RecurringRuleModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get recurring rules',
    );
  }

  @override
  Future<RecurringRuleModel?> getRuleById(String userId, String ruleId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .recurringRulesCollection(userId)
            .doc(ruleId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return RecurringRuleModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get recurring rule',
    );
  }

  @override
  Future<RecurringRuleModel> createRule(
    String userId,
    RecurringRuleModel rule,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.recurringRulesCollection(userId).doc(rule.id);

        await docRef.set({
          ...rule.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return RecurringRuleModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create recurring rule',
    );
  }

  @override
  Future<RecurringRuleModel> updateRule(
    String userId,
    RecurringRuleModel rule,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.recurringRulesCollection(userId).doc(rule.id);

        await docRef.update({
          ...rule.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Recurring rule not found after update');
        }

        return RecurringRuleModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update recurring rule',
    );
  }

  @override
  Future<void> deleteRule(String userId, String ruleId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .recurringRulesCollection(userId)
            .doc(ruleId)
            .delete();
      },
      operationName: 'delete recurring rule',
    );
  }

  @override
  Stream<List<RecurringRuleModel>> watchRules(String userId) {
    return _firebaseService
        .recurringRulesCollection(userId)
        .orderBy('next_execution')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecurringRuleModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<RecurringRuleModel>> getActiveRules(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .recurringRulesCollection(userId)
            .where('is_active', isEqualTo: true)
            .orderBy('next_execution')
            .get();

        return snapshot.docs
            .map((doc) => RecurringRuleModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get active recurring rules',
    );
  }

  @override
  Future<List<RecurringRuleModel>> getDueRules(
    String userId,
    DateTime date,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .recurringRulesCollection(userId)
            .where('is_active', isEqualTo: true)
            .where('next_execution', isLessThanOrEqualTo: date.toIso8601String())
            .orderBy('next_execution')
            .get();

        return snapshot.docs
            .map((doc) => RecurringRuleModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get due recurring rules',
    );
  }

  @override
  Future<void> updateLastExecuted(
    String userId,
    String ruleId,
    DateTime date,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .recurringRulesCollection(userId)
            .doc(ruleId)
            .update({
          'last_executed': date.toIso8601String(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update last executed',
    );
  }

  @override
  Future<void> updateNextExecution(
    String userId,
    String ruleId,
    DateTime date,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .recurringRulesCollection(userId)
            .doc(ruleId)
            .update({
          'next_execution': date.toIso8601String(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update next execution',
    );
  }

  @override
  Future<void> deactivateRule(String userId, String ruleId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .recurringRulesCollection(userId)
            .doc(ruleId)
            .update({
          'is_active': false,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'deactivate recurring rule',
    );
  }

  @override
  Future<void> batchUpdateNextExecution(
    String userId,
    Map<String, DateTime> ruleNextDates,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final batch = _firebaseService.batch();

        for (final entry in ruleNextDates.entries) {
          final docRef =
              _firebaseService.recurringRulesCollection(userId).doc(entry.key);
          batch.update(docRef, {
            'next_execution': entry.value.toIso8601String(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      },
      operationName: 'batch update next execution',
    );
  }
}
