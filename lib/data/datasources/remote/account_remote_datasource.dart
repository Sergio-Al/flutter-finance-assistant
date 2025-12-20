import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/account_model.dart';

/// Remote datasource for Account operations with Firebase.
///
/// Handles all account-related Firestore operations including
/// CRUD operations and balance management.
abstract class AccountRemoteDataSource {
  /// Get all accounts for a user.
  Future<List<AccountModel>> getAccounts(String userId);

  /// Get account by ID.
  Future<AccountModel?> getAccountById(String userId, String accountId);

  /// Create a new account.
  Future<AccountModel> createAccount(String userId, AccountModel account);

  /// Update an existing account.
  Future<AccountModel> updateAccount(String userId, AccountModel account);

  /// Delete an account.
  Future<void> deleteAccount(String userId, String accountId);

  /// Stream all accounts for a user.
  Stream<List<AccountModel>> watchAccounts(String userId);

  /// Stream a single account.
  Stream<AccountModel?> watchAccount(String userId, String accountId);

  /// Update account balance.
  Future<void> updateBalance(String userId, String accountId, double newBalance);

  /// Get active accounts only.
  Future<List<AccountModel>> getActiveAccounts(String userId);

  /// Get accounts by type.
  Future<List<AccountModel>> getAccountsByType(String userId, String type);

  /// Batch update multiple accounts.
  Future<void> batchUpdateAccounts(String userId, List<AccountModel> accounts);
}

/// Implementation of [AccountRemoteDataSource] using Firebase Firestore.
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final FirebaseService _firebaseService;

  AccountRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  @override
  Future<List<AccountModel>> getAccounts(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .accountsCollection(userId)
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get accounts',
    );
  }

  @override
  Future<AccountModel?> getAccountById(String userId, String accountId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .accountsCollection(userId)
            .doc(accountId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return AccountModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get account',
    );
  }

  @override
  Future<AccountModel> createAccount(String userId, AccountModel account) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.accountsCollection(userId).doc(account.id);

        await docRef.set({
          ...account.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return AccountModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create account',
    );
  }

  @override
  Future<AccountModel> updateAccount(String userId, AccountModel account) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.accountsCollection(userId).doc(account.id);

        await docRef.update({
          ...account.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Account not found after update');
        }

        return AccountModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update account',
    );
  }

  @override
  Future<void> deleteAccount(String userId, String accountId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .accountsCollection(userId)
            .doc(accountId)
            .delete();
      },
      operationName: 'delete account',
    );
  }

  @override
  Stream<List<AccountModel>> watchAccounts(String userId) {
    return _firebaseService
        .accountsCollection(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<AccountModel?> watchAccount(String userId, String accountId) {
    return _firebaseService
        .accountsCollection(userId)
        .doc(accountId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AccountModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> updateBalance(
    String userId,
    String accountId,
    double newBalance,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService.accountsCollection(userId).doc(accountId).update({
          'balance': newBalance,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update balance',
    );
  }

  @override
  Future<List<AccountModel>> getActiveAccounts(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .accountsCollection(userId)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get active accounts',
    );
  }

  @override
  Future<List<AccountModel>> getAccountsByType(String userId, String type) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .accountsCollection(userId)
            .where('type', isEqualTo: type)
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get accounts by type',
    );
  }

  @override
  Future<void> batchUpdateAccounts(
    String userId,
    List<AccountModel> accounts,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final batch = _firebaseService.batch();

        for (final account in accounts) {
          final docRef =
              _firebaseService.accountsCollection(userId).doc(account.id);
          batch.update(docRef, {
            ...account.toFirestore(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      },
      operationName: 'batch update accounts',
    );
  }
}
