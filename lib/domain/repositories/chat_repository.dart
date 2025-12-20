import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';

/// Repository interface for chat operations.
///
/// Defines the contract for AI chat history data access.
/// Implementation will be in the data layer.
abstract class ChatRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // Session Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all chat sessions for a user.
  Future<Either<Failure, List<ChatSession>>> getSessions(String userId);

  /// Get session by ID.
  Future<Either<Failure, ChatSession>> getSessionById(String sessionId);

  /// Create a new chat session.
  Future<Either<Failure, ChatSession>> createSession(String userId, {
    String? title,
  });

  /// Update session (e.g., title).
  Future<Either<Failure, ChatSession>> updateSession(ChatSession session);

  /// Delete a session and all its messages.
  Future<Either<Failure, void>> deleteSession(String sessionId);

  /// Get recent sessions.
  Future<Either<Failure, List<ChatSession>>> getRecentSessions(
    String userId, {
    int limit = 10,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Message Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all messages in a session.
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId);

  /// Get message by ID.
  Future<Either<Failure, ChatMessage>> getMessageById(String messageId);

  /// Add a message to a session.
  Future<Either<Failure, ChatMessage>> addMessage(ChatMessage message);

  /// Update a message.
  Future<Either<Failure, ChatMessage>> updateMessage(ChatMessage message);

  /// Delete a message.
  Future<Either<Failure, void>> deleteMessage(String messageId);

  /// Get recent messages in a session.
  Future<Either<Failure, List<ChatMessage>>> getRecentMessages(
    String sessionId, {
    int limit = 50,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AI Interaction
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a message and get AI response.
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String sessionId,
    required String userId,
    required String content,
    String? model,
  });

  /// Stream AI response for real-time display.
  Stream<Either<Failure, String>> streamResponse({
    required String sessionId,
    required String userId,
    required String content,
    String? model,
  });

  /// Get conversation context for AI (recent messages).
  Future<Either<Failure, List<ChatMessage>>> getConversationContext(
    String sessionId, {
    int maxMessages = 10,
    int maxTokens = 4000,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Search & Analytics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search messages across all sessions.
  Future<Either<Failure, List<ChatMessage>>> searchMessages(
    String userId,
    String query,
  );

  /// Get total tokens used by user.
  Future<Either<Failure, int>> getTotalTokensUsed(String userId);

  /// Get tokens used in a specific period.
  Future<Either<Failure, int>> getTokensUsedInPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get message count for user.
  Future<Either<Failure, int>> getMessageCount(String userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════════════════

  /// Delete old sessions (older than specified days).
  Future<Either<Failure, int>> deleteOldSessions(
    String userId, {
    int olderThanDays = 30,
  });

  /// Clear all chat history for user.
  Future<Either<Failure, void>> clearAllHistory(String userId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of sessions for real-time updates.
  Stream<Either<Failure, List<ChatSession>>> watchSessions(String userId);

  /// Stream of messages in a session.
  Stream<Either<Failure, List<ChatMessage>>> watchMessages(String sessionId);
}
