import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for creating a new chat session.
///
/// ## Example Usage
/// ```dart
/// final useCase = CreateChatSessionUseCase(chatRepository);
///
/// final result = await useCase(
///   CreateChatSessionParams(
///     userId: 'user-123',
///     title: 'Budget Planning Help',
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (session) => navigateToChatScreen(session.id),
/// );
/// ```
class CreateChatSessionUseCase
    extends UseCase<ChatSession, CreateChatSessionParams> {
  final ChatRepository repository;

  CreateChatSessionUseCase(this.repository);

  @override
  Future<Either<Failure, ChatSession>> call(
    CreateChatSessionParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.createSession(params.userId, title: params.title);
  }
}

/// Parameters for [CreateChatSessionUseCase].
class CreateChatSessionParams extends Equatable {
  final String userId;
  final String? title;

  const CreateChatSessionParams({required this.userId, this.title});

  @override
  List<Object?> get props => [userId, title];
}

/// Use case for getting a chat session by ID.
class GetChatSessionUseCase extends UseCase<ChatSession, GetChatSessionParams> {
  final ChatRepository repository;

  GetChatSessionUseCase(this.repository);

  @override
  Future<Either<Failure, ChatSession>> call(GetChatSessionParams params) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    return repository.getSessionById(params.sessionId);
  }
}

/// Parameters for [GetChatSessionUseCase].
class GetChatSessionParams extends Equatable {
  final String sessionId;

  const GetChatSessionParams({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Use case for getting all chat sessions for a user.
class GetChatSessionsUseCase
    extends UseCase<List<ChatSession>, GetChatSessionsParams> {
  final ChatRepository repository;

  GetChatSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatSession>>> call(
    GetChatSessionsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getSessions(params.userId);
  }
}

/// Parameters for [GetChatSessionsUseCase].
class GetChatSessionsParams extends Equatable {
  final String userId;

  const GetChatSessionsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting recent chat sessions.
class GetRecentSessionsUseCase
    extends UseCase<List<ChatSession>, GetRecentSessionsParams> {
  final ChatRepository repository;

  GetRecentSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatSession>>> call(
    GetRecentSessionsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.limit <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Limit must be greater than 0',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    return repository.getRecentSessions(params.userId, limit: params.limit);
  }
}

/// Parameters for [GetRecentSessionsUseCase].
class GetRecentSessionsParams extends Equatable {
  final String userId;
  final int limit;

  const GetRecentSessionsParams({required this.userId, this.limit = 10});

  @override
  List<Object?> get props => [userId, limit];
}

/// Use case for updating a chat session.
class UpdateChatSessionUseCase
    extends UseCase<ChatSession, UpdateChatSessionParams> {
  final ChatRepository repository;

  UpdateChatSessionUseCase(this.repository);

  @override
  Future<Either<Failure, ChatSession>> call(
    UpdateChatSessionParams params,
  ) async {
    if (params.session.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    return repository.updateSession(params.session);
  }
}

/// Parameters for [UpdateChatSessionUseCase].
class UpdateChatSessionParams extends Equatable {
  final ChatSession session;

  const UpdateChatSessionParams({required this.session});

  @override
  List<Object?> get props => [session];
}

/// Use case for deleting a chat session.
class DeleteChatSessionUseCase extends UseCase<void, DeleteChatSessionParams> {
  final ChatRepository repository;

  DeleteChatSessionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteChatSessionParams params) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    return repository.deleteSession(params.sessionId);
  }
}

/// Parameters for [DeleteChatSessionUseCase].
class DeleteChatSessionParams extends Equatable {
  final String sessionId;

  const DeleteChatSessionParams({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}
