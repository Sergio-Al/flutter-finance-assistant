import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/models/chat_message_model.dart';

/// Remote datasource for Chat operations with Firebase.
///
/// Handles all chat-related Firestore operations including
/// sessions, messages, and conversation history.
abstract class ChatRemoteDataSource {
  // ═══════════════════════════════════════════════════════════════════════════
  // Session Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all chat sessions for a user.
  Future<List<ChatSessionModel>> getSessions(String userId);

  /// Get chat session by ID.
  Future<ChatSessionModel?> getSessionById(String userId, String sessionId);

  /// Create a new chat session.
  Future<ChatSessionModel> createSession(String userId, ChatSessionModel session);

  /// Update chat session (title, etc.).
  Future<ChatSessionModel> updateSession(String userId, ChatSessionModel session);

  /// Delete a chat session and all its messages.
  Future<void> deleteSession(String userId, String sessionId);

  /// Stream all sessions for a user.
  Stream<List<ChatSessionModel>> watchSessions(String userId);

  /// Get recent sessions.
  Future<List<ChatSessionModel>> getRecentSessions(String userId, int limit);

  // ═══════════════════════════════════════════════════════════════════════════
  // Message Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all messages for a session.
  Future<List<ChatMessageModel>> getMessages(String userId, String sessionId);

  /// Get message by ID.
  Future<ChatMessageModel?> getMessageById(
    String userId,
    String sessionId,
    String messageId,
  );

  /// Add a message to a session.
  Future<ChatMessageModel> addMessage(
    String userId,
    String sessionId,
    ChatMessageModel message,
  );

  /// Delete a message.
  Future<void> deleteMessage(String userId, String sessionId, String messageId);

  /// Stream messages for a session.
  Stream<List<ChatMessageModel>> watchMessages(String userId, String sessionId);

  /// Get recent messages (for context).
  Future<List<ChatMessageModel>> getRecentMessages(
    String userId,
    String sessionId,
    int limit,
  );

  /// Get message count for a session.
  Future<int> getMessageCount(String userId, String sessionId);

  /// Delete all messages in a session.
  Future<void> clearSessionMessages(String userId, String sessionId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update session's last message timestamp.
  Future<void> updateSessionLastMessage(String userId, String sessionId);

  /// Increment session message count.
  Future<void> incrementMessageCount(String userId, String sessionId);
}

/// Implementation of [ChatRemoteDataSource] using Firebase Firestore.
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseService _firebaseService;

  ChatRemoteDataSourceImpl({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  // ═══════════════════════════════════════════════════════════════════════════
  // Session Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<ChatSessionModel>> getSessions(String userId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .chatSessionsCollection(userId)
            .orderBy('last_message_at', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => ChatSessionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get chat sessions',
    );
  }

  @override
  Future<ChatSessionModel?> getSessionById(
    String userId,
    String sessionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .chatSessionsCollection(userId)
            .doc(sessionId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return ChatSessionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get chat session',
    );
  }

  @override
  Future<ChatSessionModel> createSession(
    String userId,
    ChatSessionModel session,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.chatSessionsCollection(userId).doc(session.id);

        await docRef.set({
          ...session.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
          'last_message_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        return ChatSessionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'create chat session',
    );
  }

  @override
  Future<ChatSessionModel> updateSession(
    String userId,
    ChatSessionModel session,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef =
            _firebaseService.chatSessionsCollection(userId).doc(session.id);

        await docRef.update({
          ...session.toFirestore(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        final doc = await docRef.get();
        if (!doc.exists || doc.data() == null) {
          throw NotFoundException('Chat session not found after update');
        }

        return ChatSessionModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'update chat session',
    );
  }

  @override
  Future<void> deleteSession(String userId, String sessionId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        // Delete all messages first
        await clearSessionMessages(userId, sessionId);

        // Delete the session document
        await _firebaseService
            .chatSessionsCollection(userId)
            .doc(sessionId)
            .delete();
      },
      operationName: 'delete chat session',
    );
  }

  @override
  Stream<List<ChatSessionModel>> watchSessions(String userId) {
    return _firebaseService
        .chatSessionsCollection(userId)
        .orderBy('last_message_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSessionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<ChatSessionModel>> getRecentSessions(
    String userId,
    int limit,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .chatSessionsCollection(userId)
            .orderBy('last_message_at', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs
            .map((doc) => ChatSessionModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get recent chat sessions',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Message Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<List<ChatMessageModel>> getMessages(
    String userId,
    String sessionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .orderBy('timestamp')
            .limit(AppConstants.chatHistoryLimit)
            .get();

        return snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc.data(), doc.id))
            .toList();
      },
      operationName: 'get chat messages',
    );
  }

  @override
  Future<ChatMessageModel?> getMessageById(
    String userId,
    String sessionId,
    String messageId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final doc = await _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .doc(messageId)
            .get();

        if (!doc.exists || doc.data() == null) {
          return null;
        }

        return ChatMessageModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'get chat message',
    );
  }

  @override
  Future<ChatMessageModel> addMessage(
    String userId,
    String sessionId,
    ChatMessageModel message,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final docRef = _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .doc(message.id);

        await docRef.set({
          ...message.toFirestore(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update session's last message time and count
        await updateSessionLastMessage(userId, sessionId);
        await incrementMessageCount(userId, sessionId);

        final doc = await docRef.get();
        return ChatMessageModel.fromFirestore(doc.data()!, doc.id);
      },
      operationName: 'add chat message',
    );
  }

  @override
  Future<void> deleteMessage(
    String userId,
    String sessionId,
    String messageId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .doc(messageId)
            .delete();
      },
      operationName: 'delete chat message',
    );
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(
    String userId,
    String sessionId,
  ) {
    return _firebaseService
        .chatMessagesCollection(userId, sessionId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<ChatMessageModel>> getRecentMessages(
    String userId,
    String sessionId,
    int limit,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        // Return in chronological order
        return snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc.data(), doc.id))
            .toList()
            .reversed
            .toList();
      },
      operationName: 'get recent chat messages',
    );
  }

  @override
  Future<int> getMessageCount(String userId, String sessionId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final snapshot = await _firebaseService
            .chatMessagesCollection(userId, sessionId)
            .count()
            .get();

        return snapshot.count ?? 0;
      },
      operationName: 'get message count',
    );
  }

  @override
  Future<void> clearSessionMessages(String userId, String sessionId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        final messagesRef =
            _firebaseService.chatMessagesCollection(userId, sessionId);

        // Delete in batches
        const batchSize = 500;
        QuerySnapshot<Map<String, dynamic>> snapshot;

        do {
          snapshot = await messagesRef.limit(batchSize).get();

          if (snapshot.docs.isEmpty) break;

          final batch = _firebaseService.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } while (snapshot.docs.length == batchSize);

        // Reset session message count
        await _firebaseService
            .chatSessionsCollection(userId)
            .doc(sessionId)
            .update({
          'message_count': 0,
          'updated_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'clear session messages',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> updateSessionLastMessage(
    String userId,
    String sessionId,
  ) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .chatSessionsCollection(userId)
            .doc(sessionId)
            .update({
          'last_message_at': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'update session last message',
    );
  }

  @override
  Future<void> incrementMessageCount(String userId, String sessionId) async {
    return _firebaseService.handleFirestoreOperation(
      () async {
        await _firebaseService
            .chatSessionsCollection(userId)
            .doc(sessionId)
            .update({
          'message_count': FieldValue.increment(1),
        });
      },
      operationName: 'increment message count',
    );
  }
}
