import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'chat_dao.g.dart';

/// Data Access Object for ChatMessages and ChatSessions tables.
@DriftAccessor(tables: [ChatMessages, ChatSessions])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  // ============ Sessions ============

  /// Get all sessions for a user
  Future<List<ChatSessionEntry>> getAllSessions(String userId) {
    return (select(chatSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
  }

  /// Get session by ID
  Future<ChatSessionEntry?> getSessionById(String id) {
    return (select(chatSessions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get most recent session
  Future<ChatSessionEntry?> getMostRecentSession(String userId) {
    return (select(chatSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watch all sessions
  Stream<List<ChatSessionEntry>> watchAllSessions(String userId) {
    return (select(chatSessions)
          ..where((s) => s.userId.equals(userId))
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .watch();
  }

  /// Create new session
  Future<void> createSession(ChatSessionsCompanion session) {
    return into(chatSessions).insert(session);
  }

  /// Update session
  Future<bool> updateSession(ChatSessionsCompanion session) {
    return (update(chatSessions)..where((s) => s.id.equals(session.id.value)))
        .write(session)
        .then((rows) => rows > 0);
  }

  /// Update session title
  Future<bool> updateSessionTitle(String id, String title) {
    return (update(chatSessions)..where((s) => s.id.equals(id))).write(
      ChatSessionsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((rows) => rows > 0);
  }

  /// Update session timestamp (when new message added)
  Future<bool> touchSession(String id) {
    return (update(chatSessions)..where((s) => s.id.equals(id))).write(
      ChatSessionsCompanion(updatedAt: Value(DateTime.now())),
    ).then((rows) => rows > 0);
  }

  /// Delete session and its messages
  Future<void> deleteSession(String id) async {
    await (delete(chatMessages)..where((m) => m.sessionId.equals(id))).go();
    await (delete(chatSessions)..where((s) => s.id.equals(id))).go();
  }

  // ============ Messages ============

  /// Get all messages for a session
  Future<List<ChatMessageEntry>> getSessionMessages(String sessionId) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
  }

  /// Get recent messages for a session
  Future<List<ChatMessageEntry>> getRecentMessages(
    String sessionId, {
    int limit = 50,
  }) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(limit))
        .get()
        .then((messages) => messages.reversed.toList());
  }

  /// Watch session messages
  Stream<List<ChatMessageEntry>> watchSessionMessages(String sessionId) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// Insert new message
  Future<void> insertMessage(ChatMessagesCompanion message) async {
    await into(chatMessages).insert(message);
    // Update session timestamp
    if (message.sessionId.present) {
      await touchSession(message.sessionId.value);
    }
  }

  /// Update message
  Future<bool> updateMessage(ChatMessagesCompanion message) {
    return (update(chatMessages)..where((m) => m.id.equals(message.id.value)))
        .write(message)
        .then((rows) => rows > 0);
  }

  /// Delete message
  Future<int> deleteMessage(String id) {
    return (delete(chatMessages)..where((m) => m.id.equals(id))).go();
  }

  /// Get message count for session
  Future<int> getMessageCount(String sessionId) async {
    final result = await (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId)))
        .get();
    return result.length;
  }

  /// Get total tokens used in session
  Future<int> getSessionTokens(String sessionId) async {
    final messages = await getSessionMessages(sessionId);
    return messages.fold<int>(0, (sum, m) => sum + (m.tokensUsed ?? 0));
  }

  /// Delete all messages in session
  Future<int> clearSessionMessages(String sessionId) {
    return (delete(chatMessages)..where((m) => m.sessionId.equals(sessionId)))
        .go();
  }

  /// Get messages pending sync
  Future<List<ChatMessageEntry>> getPendingSync() {
    return (select(chatMessages)..where((m) => m.syncStatus.equals('pending')))
        .get();
  }

  /// Update message sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(chatMessages)..where((m) => m.id.equals(id))).write(
      ChatMessagesCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
