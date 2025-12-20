import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/user_model.dart';

/// Remote datasource for User operations with Firebase.
///
/// Handles all user-related Firestore operations including
/// profile management and preferences sync.
abstract class UserRemoteDataSource {
  /// Get user by ID from Firestore.
  Future<UserModel?> getUserById(String userId);

  /// Create a new user document in Firestore.
  Future<UserModel> createUser(UserModel user);

  /// Update user profile in Firestore.
  Future<UserModel> updateUser(UserModel user);

  /// Delete user document from Firestore.
  Future<void> deleteUser(String userId);

  /// Stream user document changes.
  Stream<UserModel?> watchUser(String userId);

  /// Update specific user preferences.
  Future<void> updatePreferences({
    required String userId,
    Map<String, dynamic> preferences,
  });

  /// Check if user exists in Firestore.
  Future<bool> userExists(String userId);
}

/// Implementation of [UserRemoteDataSource] using Firebase Firestore.
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseService _firebaseService;

  UserRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  @override
  Future<UserModel?> getUserById(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService.usersCollection.doc(userId).get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return UserModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get user',
    );
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.usersCollection.doc(user.id);
        
        await docRef.set({
          ...user.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Fetch the created document to get server timestamps
        final doc = await docRef.get();
        return UserModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create user',
    );
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.usersCollection.doc(user.id);

        await docRef.update({
          ...user.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('User not found after update');
        }

        return UserModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update user',
    );
  }

  @override
  Future<void> deleteUser(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // Delete user document
        await _firebaseService.usersCollection.doc(userId).delete();

        // Note: Subcollections (accounts, transactions, etc.) should be
        // deleted via Cloud Functions for proper cleanup
      },
      operationName: 'delete user',
    );
  }

  @override
  Stream<UserModel?> watchUser(String userId) {
    return _firebaseService.usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> updatePreferences({
    required String userId,
    Map<String, dynamic>? preferences,
  }) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        if (preferences == null || preferences.isEmpty) return;

        await _firebaseService.usersCollection.doc(userId).update({
          ...preferences,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update preferences',
    );
  }

  @override
  Future<bool> userExists(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService.usersCollection.doc(userId).get();
        return doc.exists;
      },
      operationName: 'check user exists',
    );
  }
}
