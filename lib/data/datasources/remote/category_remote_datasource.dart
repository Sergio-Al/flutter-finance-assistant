import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/category_model.dart';

/// Remote datasource for Category operations with Firebase.
///
/// Handles all category-related Firestore operations including
/// system and custom categories.
abstract class CategoryRemoteDataSource {
  /// Get all categories for a user (including system categories).
  Future<List<CategoryModel>> getCategories(String userId);

  /// Get category by ID.
  Future<CategoryModel?> getCategoryById(String userId, String categoryId);

  /// Create a new custom category.
  Future<CategoryModel> createCategory(String userId, CategoryModel category);

  /// Update an existing category.
  Future<CategoryModel> updateCategory(String userId, CategoryModel category);

  /// Delete a category.
  Future<void> deleteCategory(String userId, String categoryId);

  /// Stream all categories for a user.
  Stream<List<CategoryModel>> watchCategories(String userId);

  /// Get categories by type (expense/income).
  Future<List<CategoryModel>> getCategoriesByType(String userId, String type);

  /// Get system categories only.
  Future<List<CategoryModel>> getSystemCategories();

  /// Get user's custom categories only.
  Future<List<CategoryModel>> getUserCategories(String userId);

  /// Seed default categories for a new user.
  Future<void> seedDefaultCategories(String userId, List<CategoryModel> categories);

  /// Reorder categories.
  Future<void> reorderCategories(String userId, List<String> categoryIds);
}

/// Implementation of [CategoryRemoteDataSource] using Firebase Firestore.
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseService _firebaseService;

  CategoryRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .categoriesCollection(userId)
            .orderBy('order_index')
            .get();

        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get categories',
    );
  }

  @override
  Future<CategoryModel?> getCategoryById(String userId, String categoryId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .categoriesCollection(userId)
            .doc(categoryId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return CategoryModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get category',
    );
  }

  @override
  Future<CategoryModel> createCategory(String userId, CategoryModel category) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.categoriesCollection(userId).doc(category.id);

        await docRef.set({
          ...category.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return CategoryModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create category',
    );
  }

  @override
  Future<CategoryModel> updateCategory(String userId, CategoryModel category) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService.categoriesCollection(userId).doc(category.id);

        await docRef.update({
          ...category.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Category not found after update');
        }

        return CategoryModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update category',
    );
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .categoriesCollection(userId)
            .doc(categoryId)
            .delete();
      },
      operationName: 'delete category',
    );
  }

  @override
  Stream<List<CategoryModel>> watchCategories(String userId) {
    return _firebaseService
        .categoriesCollection(userId)
        .orderBy('order_index')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<CategoryModel>> getCategoriesByType(String userId, String type) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .categoriesCollection(userId)
            .where('type', isEqualTo: type)
            .orderBy('order_index')
            .get();

        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get categories by type',
    );
  }

  @override
  Future<List<CategoryModel>> getSystemCategories() async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // System categories are stored in a global collection
        final snapshot = await _firebaseService.usersCollection
            .doc('_system')
            .collection('categories')
            .orderBy('order_index')
            .get();

        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get system categories',
    );
  }

  @override
  Future<List<CategoryModel>> getUserCategories(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .categoriesCollection(userId)
            .where('is_system', isEqualTo: false)
            .orderBy('order_index')
            .get();

        return snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get user categories',
    );
  }

  @override
  Future<void> seedDefaultCategories(
    String userId,
    List<CategoryModel> categories,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final batch = _firebaseService.batch();

        for (final category in categories) {
          final docRef =
              _firebaseService.categoriesCollection(userId).doc(category.id);
          batch.set(docRef, {
            ...category.toFirestore(),
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      },
      operationName: 'seed default categories',
    );
  }

  @override
  Future<void> reorderCategories(String userId, List<String> categoryIds) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final batch = _firebaseService.batch();

        for (int i = 0; i < categoryIds.length; i++) {
          final docRef =
              _firebaseService.categoriesCollection(userId).doc(categoryIds[i]);
          batch.update(docRef, {
            'order_index': i,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      },
      operationName: 'reorder categories',
    );
  }
}
