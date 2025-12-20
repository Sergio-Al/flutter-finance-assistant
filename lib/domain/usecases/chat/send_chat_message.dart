import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for sending a message and receiving AI response.
///
/// ## Example Usage
/// ```dart
/// final useCase = SendChatMessageUseCase(chatRepository);
///
/// final result = await useCase(
///   SendChatMessageParams(
///     sessionId: 'session-123',
///     userId: 'user-456',
///     content: 'How can I reduce my monthly expenses?',
///     model: 'gpt-4', // optional
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (aiResponse) => displayMessage(aiResponse),
/// );
/// ```
class SendChatMessageUseCase
    extends UseCase<ChatMessage, SendChatMessageParams> {
  final ChatRepository repository;

  SendChatMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(
    SendChatMessageParams params,
  ) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.content.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message content cannot be empty',
          code: 'EMPTY_CONTENT',
        ),
      );
    }

    return repository.sendMessage(
      sessionId: params.sessionId,
      userId: params.userId,
      content: params.content.trim(),
      model: params.model,
    );
  }
}

/// Parameters for [SendChatMessageUseCase].
class SendChatMessageParams extends Equatable {
  final String sessionId;
  final String userId;
  final String content;
  final String? model;

  const SendChatMessageParams({
    required this.sessionId,
    required this.userId,
    required this.content,
    this.model,
  });

  @override
  List<Object?> get props => [sessionId, userId, content, model];
}

/// Use case for streaming AI response in real-time.
///
/// Useful for showing typing effect as AI generates response.
///
/// ## Example Usage
/// ```dart
/// final useCase = StreamChatResponseUseCase(chatRepository);
///
/// useCase(
///   StreamChatResponseParams(
///     sessionId: 'session-123',
///     userId: 'user-456',
///     content: 'Explain compound interest',
///   ),
/// ).listen(
///   (result) => result.fold(
///     (failure) => showError(failure.message),
///     (chunk) => appendToDisplay(chunk),
///   ),
/// );
/// ```
class StreamChatResponseUseCase
    extends StreamUseCase<String, StreamChatResponseParams> {
  final ChatRepository repository;

  StreamChatResponseUseCase(this.repository);

  @override
  Stream<Either<Failure, String>> call(StreamChatResponseParams params) {
    if (params.sessionId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Session ID is required',
            code: 'MISSING_SESSION_ID',
          ),
        ),
      );
    }

    if (params.userId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            code: 'MISSING_USER_ID',
          ),
        ),
      );
    }

    if (params.content.trim().isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Message content cannot be empty',
            code: 'EMPTY_CONTENT',
          ),
        ),
      );
    }

    return repository.streamResponse(
      sessionId: params.sessionId,
      userId: params.userId,
      content: params.content.trim(),
      model: params.model,
    );
  }
}

/// Parameters for [StreamChatResponseUseCase].
class StreamChatResponseParams extends Equatable {
  final String sessionId;
  final String userId;
  final String content;
  final String? model;

  const StreamChatResponseParams({
    required this.sessionId,
    required this.userId,
    required this.content,
    this.model,
  });

  @override
  List<Object?> get props => [sessionId, userId, content, model];
}

/// Use case for getting conversation context for AI.
///
/// Retrieves recent messages to provide context for AI responses.
class GetConversationContextUseCase
    extends UseCase<List<ChatMessage>, GetConversationContextParams> {
  final ChatRepository repository;

  GetConversationContextUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetConversationContextParams params,
  ) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    return repository.getConversationContext(
      params.sessionId,
      maxMessages: params.maxMessages,
      maxTokens: params.maxTokens,
    );
  }
}

/// Parameters for [GetConversationContextUseCase].
class GetConversationContextParams extends Equatable {
  final String sessionId;
  final int maxMessages;
  final int maxTokens;

  const GetConversationContextParams({
    required this.sessionId,
    this.maxMessages = 10,
    this.maxTokens = 4000,
  });

  @override
  List<Object?> get props => [sessionId, maxMessages, maxTokens];
}
