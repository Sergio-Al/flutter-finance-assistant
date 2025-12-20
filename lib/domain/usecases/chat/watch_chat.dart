import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for watching chat sessions in real-time.
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchSessionsUseCase(chatRepository);
///
/// useCase(WatchSessionsParams(userId: 'user-123')).listen(
///   (result) => result.fold(
///     (failure) => showError(failure.message),
///     (sessions) => updateSessionList(sessions),
///   ),
/// );
/// ```
class WatchSessionsUseCase
    extends StreamUseCase<List<ChatSession>, WatchSessionsParams> {
  final ChatRepository repository;

  WatchSessionsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<ChatSession>>> call(WatchSessionsParams params) {
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

    return repository.watchSessions(params.userId);
  }
}

/// Parameters for [WatchSessionsUseCase].
class WatchSessionsParams extends Equatable {
  final String userId;

  const WatchSessionsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for watching messages in a session in real-time.
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchMessagesUseCase(chatRepository);
///
/// useCase(WatchMessagesParams(sessionId: 'session-123')).listen(
///   (result) => result.fold(
///     (failure) => showError(failure.message),
///     (messages) => updateMessageList(messages),
///   ),
/// );
/// ```
class WatchMessagesUseCase
    extends StreamUseCase<List<ChatMessage>, WatchMessagesParams> {
  final ChatRepository repository;

  WatchMessagesUseCase(this.repository);

  @override
  Stream<Either<Failure, List<ChatMessage>>> call(WatchMessagesParams params) {
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

    return repository.watchMessages(params.sessionId);
  }
}

/// Parameters for [WatchMessagesUseCase].
class WatchMessagesParams extends Equatable {
  final String sessionId;

  const WatchMessagesParams({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
