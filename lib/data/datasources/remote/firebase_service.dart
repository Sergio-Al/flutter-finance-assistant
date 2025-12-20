import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/errors/exceptions.dart';

/// Base service for Firebase operations.
///
/// Provides shared functionality for all remote datasources
/// including authentication state, collection references,
/// and common Firestore operations.
class FirebaseService {
  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  FirebaseService({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fb_auth.FirebaseAuth.instance;

  /// Get the current authenticated user's ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get the current authenticated user or throw an exception.
  String get requireUserId {
    final userId = currentUserId;
    if (userId == null) {
      throw AuthenticationException('User not authenticated');
    }
    return userId;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Collection References
  // ═══════════════════════════════════════════════════════════════════════════

  /// Users collection reference.
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  /// Accounts collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> accountsCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.accountsCollection);

  /// Categories collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> categoriesCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.categoriesCollection);

  /// Transactions collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> transactionsCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.transactionsCollection);

  /// Budgets collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> budgetsCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.budgetsCollection);

  /// Recurring rules collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> recurringRulesCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.recurringTransactionsCollection);

  /// Receipts collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> receiptsCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.receiptsCollection);

  /// Chat sessions collection reference (user subcollection).
  CollectionReference<Map<String, dynamic>> chatSessionsCollection(String userId) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.chatHistoryCollection);

  /// Chat messages collection reference (session subcollection).
  CollectionReference<Map<String, dynamic>> chatMessagesCollection(
    String userId,
    String sessionId,
  ) =>
      chatSessionsCollection(userId).doc(sessionId).collection('messages');

  // ═══════════════════════════════════════════════════════════════════════════
  // Batch Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new write batch.
  WriteBatch batch() => _firestore.batch();

  /// Run a transaction.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) {
    return _firestore.runTransaction(transactionHandler);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Error Handling
  // ═══════════════════════════════════════════════════════════════════════════

  /// Wrap Firestore operations with error handling.
  Future<T> handleFirestoreOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e, operationName);
    } catch (e) {
      throw ServerException(
        message: operationName != null
            ? 'Failed to $operationName: $e'
            : 'Firestore operation failed: $e',
      );
    }
  }

  /// Map Firebase exceptions to our custom exceptions.
  Exception _mapFirebaseException(FirebaseException e, String? operationName) {
    final message = operationName != null
        ? 'Failed to $operationName: ${e.message}'
        : e.message ?? 'Unknown Firebase error';

    switch (e.code) {
      case 'permission-denied':
        return AuthenticationException('Permission denied: $message');
      case 'not-found':
        return NotFoundException(message);
      case 'already-exists':
        return ServerException(message: 'Document already exists: $message');
      case 'resource-exhausted':
        return ServerException(message: 'Quota exceeded: $message');
      case 'unavailable':
        return NetworkException('Service unavailable: $message');
      case 'deadline-exceeded':
        return TimeoutException('Operation timed out: $message');
      default:
        return ServerException(message: message);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Timestamp Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert DateTime to Firestore Timestamp.
  static Timestamp dateTimeToTimestamp(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);

  /// Convert Firestore Timestamp to DateTime.
  static DateTime timestampToDateTime(Timestamp timestamp) =>
      timestamp.toDate();

  /// Get server timestamp for Firestore operations.
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();
}
