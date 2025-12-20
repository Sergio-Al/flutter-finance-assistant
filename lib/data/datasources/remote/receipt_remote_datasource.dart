import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/receipt_model.dart';

/// Remote datasource for Receipt operations with Firebase.
///
/// Handles all receipt-related Firestore and Storage operations
/// including image upload, OCR data, and receipt item management.
abstract class ReceiptRemoteDataSource {
  /// Get all receipts for a user.
  Future<List<ReceiptModel>> getReceipts(String userId);

  /// Get receipt by ID.
  Future<ReceiptModel?> getReceiptById(String userId, String receiptId);

  /// Create a new receipt.
  Future<ReceiptModel> createReceipt(String userId, ReceiptModel receipt);

  /// Update an existing receipt.
  Future<ReceiptModel> updateReceipt(String userId, ReceiptModel receipt);

  /// Delete a receipt (including image from Storage).
  Future<void> deleteReceipt(String userId, String receiptId);

  /// Stream all receipts for a user.
  Stream<List<ReceiptModel>> watchReceipts(String userId);

  /// Upload receipt image to Firebase Storage.
  Future<String> uploadReceiptImage(String userId, String receiptId, File imageFile);

  /// Delete receipt image from Firebase Storage.
  Future<void> deleteReceiptImage(String imageUrl);

  /// Get receipt by transaction ID.
  Future<ReceiptModel?> getReceiptByTransaction(String userId, String transactionId);

  /// Get unprocessed receipts (OCR pending).
  Future<List<ReceiptModel>> getUnprocessedReceipts(String userId);

  /// Update receipt OCR status.
  Future<void> updateOcrStatus(String userId, String receiptId, String status);

  /// Update receipt with OCR results.
  Future<void> updateOcrResults(
    String userId,
    String receiptId, {
    String? merchantName,
    double? totalAmount,
    DateTime? receiptDate,
    String? rawText,
    List<ReceiptItemModel>? items,
  });

  /// Link receipt to transaction.
  Future<void> linkToTransaction(
    String userId,
    String receiptId,
    String transactionId,
  );

  /// Get receipts by date range.
  Future<List<ReceiptModel>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

/// Implementation of [ReceiptRemoteDataSource] using Firebase.
class ReceiptRemoteDataSourceImpl implements ReceiptRemoteDataSource {
  final FirebaseService _firebaseService;
  final FirebaseStorage _storage;

  ReceiptRemoteDataSourceImpl({
    required FirebaseService firebaseService,
    FirebaseStorage? storage,
  })  : _firebaseService = firebaseService,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<List<ReceiptModel>> getReceipts(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .receiptsCollection(userId)
            .orderBy('created_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => ReceiptModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get receipts',
    );
  }

  @override
  Future<ReceiptModel?> getReceiptById(String userId, String receiptId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return ReceiptModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get receipt',
    );
  }

  @override
  Future<ReceiptModel> createReceipt(String userId, ReceiptModel receipt) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.receiptsCollection(userId).doc(receipt.id);

        await docRef.set({
          ...receipt.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return ReceiptModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create receipt',
    );
  }

  @override
  Future<ReceiptModel> updateReceipt(String userId, ReceiptModel receipt) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.receiptsCollection(userId).doc(receipt.id);

        await docRef.update({
          ...receipt.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Receipt not found after update');
        }

        return ReceiptModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update receipt',
    );
  }

  @override
  Future<void> deleteReceipt(String userId, String receiptId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // Get receipt to find image URL
        final doc = await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .get();

        if (doc.exists && doc.data() != null) {
          final imageUrl = doc.data()!['image_url'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              await deleteReceiptImage(imageUrl);
            } catch (_) {
              // Continue even if image deletion fails
            }
          }
        }

        // Delete receipt document
        await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .delete();
      },
      operationName: 'delete receipt',
    );
  }

  @override
  Stream<List<ReceiptModel>> watchReceipts(String userId) {
    return _firebaseService
        .receiptsCollection(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReceiptModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<String> uploadReceiptImage(
    String userId,
    String receiptId,
    File imageFile,
  ) async {
    try {
      final ref = _storage.ref().child('receipts/$userId/$receiptId.jpg');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw UploadException('Failed to upload receipt image: ${e.message}');
    }
  }

  @override
  Future<void> deleteReceiptImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Failed to delete receipt image: ${e.message}');
    }
  }

  @override
  Future<ReceiptModel?> getReceiptByTransaction(
    String userId,
    String transactionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .receiptsCollection(userId)
            .where('transaction_id', isEqualTo: transactionId)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          return null;
        }

        final doc = snapshot.docs.first;
        return ReceiptModel.fromFirestore(doc.data(), doc.id);
      },
      operationName: 'get receipt by transaction',
    );
  }

  @override
  Future<List<ReceiptModel>> getUnprocessedReceipts(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .receiptsCollection(userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at')
            .get();

        return snapshot.docs
            .map((doc) => ReceiptModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get unprocessed receipts',
    );
  }

  @override
  Future<void> updateOcrStatus(
    String userId,
    String receiptId,
    String status,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .update({
          'status': status,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update OCR status',
    );
  }

  @override
  Future<void> updateOcrResults(
    String userId,
    String receiptId, {
    String? merchantName,
    double? totalAmount,
    DateTime? receiptDate,
    String? rawText,
    List<ReceiptItemModel>? items,
  }) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final updates = <String, dynamic>{
          'status': 'processed',
          'updated_at': FieldValue.serverTimestamp(),
        };

        if (merchantName != null) updates['merchant_name'] = merchantName;
        if (totalAmount != null) updates['total_amount'] = totalAmount;
        if (receiptDate != null) {
          updates['receipt_date'] = receiptDate.toIso8601String();
        }
        if (rawText != null) updates['raw_text'] = rawText;
        if (items != null) {
          updates['items'] = items.map((item) => item.toJson()).toList();
        }

        await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .update(updates);
      },
      operationName: 'update OCR results',
    );
  }

  @override
  Future<void> linkToTransaction(
    String userId,
    String receiptId,
    String transactionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .receiptsCollection(userId)
            .doc(receiptId)
            .update({
          'transaction_id': transactionId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'link receipt to transaction',
    );
  }

  @override
  Future<List<ReceiptModel>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .receiptsCollection(userId)
            .where('receipt_date',
                isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('receipt_date', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('receipt_date', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => ReceiptModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get receipts by date range',
    );
  }
}
