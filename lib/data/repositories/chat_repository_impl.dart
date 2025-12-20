import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/chat_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/chat_message_model.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';

/// Implementation of [ChatRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Integrates with Google Gemini API for AI-powered chat responses.
class ChatRepositoryImpl implements ChatRepository {
  final AppDatabase _database;
  final ChatRemoteDataSource _remoteDataSource;
  final genai.GenerativeModel? _generativeModel;
  final Uuid _uuid;

  /// Creates [ChatRepositoryImpl] with required data sources.
  ChatRepositoryImpl({
    required AppDatabase database,
    required ChatRemoteDataSource remoteDataSource,
    genai.GenerativeModel? generativeModel,
    Uuid? uuid,
  }) : _database = database,
       _remoteDataSource = remoteDataSource,
       _generativeModel = generativeModel,
       _uuid = uuid ?? const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // Session Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<ChatSession>>> getSessions(String userId) async {
    try {
      final entries = await _database.chatDao.getAllSessions(userId);
      final sessions = await Future.wait(
        entries.map((entry) => _sessionEntryToEntity(entry)),
      );
      return Right(sessions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get chat sessions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting chat sessions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatSession>> getSessionById(String sessionId) async {
    try {
      final entry = await _database.chatDao.getSessionById(sessionId);
      if (entry == null) {
        return Left(
          NotFoundFailure(message: 'Chat session not found: $sessionId'),
        );
      }
      final session = await _sessionEntryToEntity(entry);
      return Right(session);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get chat session: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting chat session: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatSession>> createSession(
    String userId, {
    String? title,
  }) async {
    try {
      final now = DateTime.now();
      final sessionId = 'session_${_uuid.v4()}';

      final session = ChatSession(
        id: sessionId,
        userId: userId,
        title: title ?? 'New Chat',
        messages: const [],
        createdAt: now,
        updatedAt: now,
      );

      await _database.chatDao.createSession(_sessionEntityToCompanion(session));

      return Right(session);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create chat session: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating chat session: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatSession>> updateSession(
    ChatSession session,
  ) async {
    try {
      final updatedSession = session.copyWith(updatedAt: DateTime.now());

      final success = await _database.chatDao.updateSession(
        _sessionEntityToCompanion(updatedSession),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Chat session not found for update: ${session.id}',
          ),
        );
      }

      return Right(updatedSession);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update chat session: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating chat session: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      await _database.chatDao.deleteSession(sessionId);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete chat session: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting chat session: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatSession>>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final entries = await _database.chatDao.getAllSessions(userId);
      final limitedEntries = entries.take(limit).toList();
      final sessions = await Future.wait(
        limitedEntries.map((entry) => _sessionEntryToEntity(entry)),
      );
      return Right(sessions);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get recent chat sessions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting recent chat sessions: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Message Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String sessionId,
  ) async {
    try {
      final entries = await _database.chatDao.getSessionMessages(sessionId);
      final messages = entries.map(_messageEntryToEntity).toList();
      return Right(messages);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get messages: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting messages: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> getMessageById(String messageId) async {
    try {
      // Search across all messages (could be optimized with a dedicated query)
      final allMessages = await ((_database.select(
        _database.chatMessages,
      ))..where((m) => m.id.equals(messageId))).getSingleOrNull();

      if (allMessages == null) {
        return Left(NotFoundFailure(message: 'Message not found: $messageId'));
      }

      return Right(_messageEntryToEntity(allMessages));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get message: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting message: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> addMessage(ChatMessage message) async {
    try {
      await _database.chatDao.insertMessage(_messageEntityToCompanion(message));
      return Right(message);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to add message: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error adding message: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> updateMessage(
    ChatMessage message,
  ) async {
    try {
      final success = await _database.chatDao.updateMessage(
        _messageEntityToCompanion(message),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Message not found for update: ${message.id}',
          ),
        );
      }

      return Right(message);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update message: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating message: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String messageId) async {
    try {
      final deletedCount = await _database.chatDao.deleteMessage(messageId);
      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(
            message: 'Message not found for deletion: $messageId',
          ),
        );
      }
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete message: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting message: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getRecentMessages(
    String sessionId, {
    int limit = 50,
  }) async {
    try {
      final entries = await _database.chatDao.getRecentMessages(
        sessionId,
        limit: limit,
      );
      final messages = entries.map(_messageEntryToEntity).toList();
      return Right(messages);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get recent messages: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting recent messages: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI Interaction
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String sessionId,
    required String userId,
    required String content,
    String? model,
  }) async {
    try {
      if (_generativeModel == null) {
        return Left(AIServiceFailure(message: 'AI service is not configured'));
      }

      final now = DateTime.now();

      // Create and save user message
      final userMessage = ChatMessage(
        id: 'msg_${_uuid.v4()}',
        userId: userId,
        sessionId: sessionId,
        role: ChatRole.user,
        content: content,
        createdAt: now,
        syncStatus: 'pending',
      );

      await _database.chatDao.insertMessage(
        _messageEntityToCompanion(userMessage),
      );

      // Get conversation context
      final contextResult = await getConversationContext(sessionId);
      final contextMessages = contextResult.fold(
        (failure) => <ChatMessage>[],
        (messages) => messages,
      );

      // Build conversation history for AI
      final history = contextMessages.map((msg) {
        return genai.Content(msg.role == ChatRole.user ? 'user' : 'model', [
          genai.TextPart(msg.content),
        ]);
      }).toList();

      // Start chat with history
      final chat = _generativeModel.startChat(history: history);

      // Send message and get response
      final response = await chat.sendMessage(genai.Content.text(content));
      final responseText =
          response.text ?? 'I apologize, but I could not generate a response.';

      // Calculate tokens used (approximate)
      final tokensUsed = response.usageMetadata?.totalTokenCount ?? 0;

      // Create and save assistant message
      final assistantMessage = ChatMessage(
        id: 'msg_${_uuid.v4()}',
        userId: userId,
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: responseText,
        tokensUsed: tokensUsed,
        model: model ?? AppConstants.geminiModel,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await _database.chatDao.insertMessage(
        _messageEntityToCompanion(assistantMessage),
      );

      // Update session title if it's the first message
      final messageCount = await _database.chatDao.getMessageCount(sessionId);
      if (messageCount <= 2) {
        // Generate a title from the first user message
        final title = _generateSessionTitle(content);
        await _database.chatDao.updateSessionTitle(sessionId, title);
      }

      return Right(assistantMessage);
    } on genai.GenerativeAIException catch (e) {
      return Left(
        AIServiceFailure(
          message: 'AI service error: ${e.message}',
          originalError: e,
        ),
      );
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to save message: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Unexpected error sending message: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, String>> streamResponse({
    required String sessionId,
    required String userId,
    required String content,
    String? model,
  }) async* {
    if (_generativeModel == null) {
      yield Left(AIServiceFailure(message: 'AI service is not configured'));
      return;
    }

    try {
      final now = DateTime.now();

      // Create and save user message
      final userMessage = ChatMessage(
        id: 'msg_${_uuid.v4()}',
        userId: userId,
        sessionId: sessionId,
        role: ChatRole.user,
        content: content,
        createdAt: now,
        syncStatus: 'pending',
      );

      await _database.chatDao.insertMessage(
        _messageEntityToCompanion(userMessage),
      );

      // Get conversation context
      final contextResult = await getConversationContext(sessionId);
      final contextMessages = contextResult.fold(
        (failure) => <ChatMessage>[],
        (messages) => messages,
      );

      // Build conversation history for AI
      final history = contextMessages.map((msg) {
        return genai.Content(msg.role == ChatRole.user ? 'user' : 'model', [
          genai.TextPart(msg.content),
        ]);
      }).toList();

      // Start chat with history
      final chat = _generativeModel.startChat(history: history);

      // Stream response
      final responseStream = chat.sendMessageStream(
        genai.Content.text(content),
      );
      final fullResponse = StringBuffer();

      await for (final chunk in responseStream) {
        final text = chunk.text ?? '';
        fullResponse.write(text);
        yield Right(text);
      }

      // Save complete assistant message
      final assistantMessage = ChatMessage(
        id: 'msg_${_uuid.v4()}',
        userId: userId,
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: fullResponse.toString(),
        model: model ?? AppConstants.geminiModel,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await _database.chatDao.insertMessage(
        _messageEntityToCompanion(assistantMessage),
      );

      // Update session title if it's the first message
      final messageCount = await _database.chatDao.getMessageCount(sessionId);
      if (messageCount <= 2) {
        final title = _generateSessionTitle(content);
        await _database.chatDao.updateSessionTitle(sessionId, title);
      }
    } on genai.GenerativeAIException catch (e) {
      yield Left(
        AIServiceFailure(
          message: 'AI service error: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      yield Left(
        AIServiceFailure(
          message: 'Unexpected error streaming response: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getConversationContext(
    String sessionId, {
    int maxMessages = 10,
    int maxTokens = 4000,
  }) async {
    try {
      final entries = await _database.chatDao.getRecentMessages(
        sessionId,
        limit: maxMessages,
      );

      // Filter to stay within token limit (approximate: 4 chars per token)
      final messages = <ChatMessage>[];
      int estimatedTokens = 0;

      for (final entry in entries) {
        final messageTokens = (entry.content.length / 4).ceil();
        if (estimatedTokens + messageTokens > maxTokens) break;
        estimatedTokens += messageTokens;
        messages.add(_messageEntryToEntity(entry));
      }

      return Right(messages);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get conversation context: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting conversation context: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search & Analytics
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<ChatMessage>>> searchMessages(
    String userId,
    String query,
  ) async {
    try {
      // Get all sessions for user
      final sessions = await _database.chatDao.getAllSessions(userId);
      final results = <ChatMessage>[];

      final lowercaseQuery = query.toLowerCase();

      // Search through each session's messages
      for (final session in sessions) {
        final messages = await _database.chatDao.getSessionMessages(session.id);
        for (final message in messages) {
          if (message.content.toLowerCase().contains(lowercaseQuery)) {
            results.add(_messageEntryToEntity(message));
          }
        }
      }

      return Right(results);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search messages: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error searching messages: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getTotalTokensUsed(String userId) async {
    try {
      final sessions = await _database.chatDao.getAllSessions(userId);
      int totalTokens = 0;

      for (final session in sessions) {
        final tokens = await _database.chatDao.getSessionTokens(session.id);
        totalTokens += tokens;
      }

      return Right(totalTokens);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get total tokens: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting total tokens: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getTokensUsedInPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sessions = await _database.chatDao.getAllSessions(userId);
      int totalTokens = 0;

      for (final session in sessions) {
        final messages = await _database.chatDao.getSessionMessages(session.id);
        for (final message in messages) {
          if (message.createdAt.isAfter(startDate) &&
              message.createdAt.isBefore(endDate)) {
            totalTokens += message.tokensUsed ?? 0;
          }
        }
      }

      return Right(totalTokens);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get tokens in period: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting tokens in period: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getMessageCount(String userId) async {
    try {
      final sessions = await _database.chatDao.getAllSessions(userId);
      int totalMessages = 0;

      for (final session in sessions) {
        final count = await _database.chatDao.getMessageCount(session.id);
        totalMessages += count;
      }

      return Right(totalMessages);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get message count: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting message count: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, int>> deleteOldSessions(
    String userId, {
    int olderThanDays = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final sessions = await _database.chatDao.getAllSessions(userId);
      int deletedCount = 0;

      for (final session in sessions) {
        if (session.updatedAt.isBefore(cutoffDate)) {
          await _database.chatDao.deleteSession(session.id);
          deletedCount++;
        }
      }

      return Right(deletedCount);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete old sessions: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting old sessions: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> clearAllHistory(String userId) async {
    try {
      final sessions = await _database.chatDao.getAllSessions(userId);

      for (final session in sessions) {
        await _database.chatDao.deleteSession(session.id);
      }

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to clear chat history: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error clearing chat history: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<ChatSession>>> watchSessions(String userId) {
    return _database.chatDao.watchAllSessions(userId).asyncMap((entries) async {
      try {
        final sessions = await Future.wait(
          entries.map((entry) => _sessionEntryToEntity(entry)),
        );
        return Right<Failure, List<ChatSession>>(sessions);
      } catch (e) {
        return Left<Failure, List<ChatSession>>(
          CacheFailure(
            message: 'Error watching sessions: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<ChatMessage>>> watchMessages(String sessionId) {
    return _database.chatDao.watchSessionMessages(sessionId).map((entries) {
      try {
        final messages = entries.map(_messageEntryToEntity).toList();
        return Right<Failure, List<ChatMessage>>(messages);
      } catch (e) {
        return Left<Failure, List<ChatMessage>>(
          CacheFailure(
            message: 'Error watching messages: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync sessions and messages from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      // Sync sessions
      final remoteSessions = await _remoteDataSource.getSessions(userId);

      for (final model in remoteSessions) {
        final existingEntry = await _database.chatDao.getSessionById(model.id);

        if (existingEntry == null) {
          await _database.chatDao.createSession(
            _sessionModelToCompanion(model),
          );
        } else if (model.updatedAt.isAfter(existingEntry.updatedAt)) {
          await _database.chatDao.updateSession(
            _sessionModelToCompanion(model),
          );
        }

        // Sync messages for this session
        final remoteMessages = await _remoteDataSource.getMessages(
          userId,
          model.id,
        );
        for (final msgModel in remoteMessages) {
          final existingMsg = await ((_database.select(
            _database.chatMessages,
          ))..where((m) => m.id.equals(msgModel.id))).getSingleOrNull();

          if (existingMsg == null) {
            await _database.chatDao.insertMessage(
              _messageModelToCompanion(msgModel, syncStatus: 'synced'),
            );
          }
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(message: 'Unexpected error syncing: $e', originalError: e),
      );
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingMessages = await _database.chatDao.getPendingSync();

      for (final entry in pendingMessages) {
        final model = ChatMessageModel.fromEntity(_messageEntryToEntity(entry));
        await _remoteDataSource.addMessage(userId, entry.sessionId, model);
        await _database.chatDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(message: 'Unexpected error syncing: $e', originalError: e),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [ChatSessionEntry] to domain [ChatSession] entity.
  Future<ChatSession> _sessionEntryToEntity(ChatSessionEntry entry) async {
    final messageEntries = await _database.chatDao.getSessionMessages(entry.id);
    final messages = messageEntries.map(_messageEntryToEntity).toList();

    return ChatSession(
      id: entry.id,
      userId: entry.userId,
      title: entry.title,
      messages: messages,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Convert domain [ChatSession] entity to Drift [ChatSessionsCompanion].
  ChatSessionsCompanion _sessionEntityToCompanion(ChatSession entity) {
    return ChatSessionsCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      title: Value(entity.title),
      createdAt: Value(entity.createdAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  /// Convert [ChatSessionModel] to Drift [ChatSessionsCompanion].
  ChatSessionsCompanion _sessionModelToCompanion(ChatSessionModel model) {
    return ChatSessionsCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      title: Value(model.title),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
  }

  /// Convert Drift [ChatMessageEntry] to domain [ChatMessage] entity.
  ChatMessage _messageEntryToEntity(ChatMessageEntry entry) {
    return ChatMessage(
      id: entry.id,
      userId: entry.userId,
      sessionId: entry.sessionId,
      role: ChatRoleExtension.fromString(entry.role),
      content: entry.content,
      tokensUsed: entry.tokensUsed,
      model: entry.model,
      metadata: null, // Metadata stored as JSON if needed
      createdAt: entry.createdAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [ChatMessage] entity to Drift [ChatMessagesCompanion].
  ChatMessagesCompanion _messageEntityToCompanion(ChatMessage entity) {
    return ChatMessagesCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      sessionId: Value(entity.sessionId),
      role: Value(entity.role.value),
      content: Value(entity.content),
      tokensUsed: Value(entity.tokensUsed),
      model: Value(entity.model),
      createdAt: Value(entity.createdAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [ChatMessageModel] to Drift [ChatMessagesCompanion].
  ChatMessagesCompanion _messageModelToCompanion(
    ChatMessageModel model, {
    String syncStatus = 'pending',
  }) {
    return ChatMessagesCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      sessionId: Value(model.sessionId),
      role: Value(model.role),
      content: Value(model.content),
      tokensUsed: Value(model.tokensUsed),
      model: Value(model.model),
      createdAt: Value(model.createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utility Methods
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a session title from the first user message.
  String _generateSessionTitle(String firstMessage) {
    // Take first 50 characters or until first newline
    final endIndex = firstMessage.indexOf('\n');
    final truncated = endIndex > 0 && endIndex < 50
        ? firstMessage.substring(0, endIndex)
        : firstMessage.length > 50
        ? '${firstMessage.substring(0, 47)}...'
        : firstMessage;
    return truncated.trim();
  }
}
