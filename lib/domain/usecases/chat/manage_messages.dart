import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for getting all messages in a session.
class GetMessagesUseCase extends UseCase<List<ChatMessage>, GetMessagesParams> {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetMessagesParams params,
  ) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    return repository.getMessages(params.sessionId);
  }
}

/// Parameters for [GetMessagesUseCase].
class GetMessagesParams extends Equatable {
  final String sessionId;

  const GetMessagesParams({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Use case for getting a message by ID.
class GetMessageByIdUseCase extends UseCase<ChatMessage, GetMessageByIdParams> {
  final ChatRepository repository;

  GetMessageByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(GetMessageByIdParams params) async {
    if (params.messageId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message ID is required',
          code: 'MISSING_MESSAGE_ID',
        ),
      );
    }

    return repository.getMessageById(params.messageId);
  }
}

/// Parameters for [GetMessageByIdUseCase].
class GetMessageByIdParams extends Equatable {
  final String messageId;

  const GetMessageByIdParams({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Use case for adding a message to a session.
class AddMessageUseCase extends UseCase<ChatMessage, AddMessageParams> {
  final ChatRepository repository;

  AddMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(AddMessageParams params) async {
    if (params.message.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
        ),
      );
    }

    if (params.message.content.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message content cannot be empty',
          code: 'EMPTY_CONTENT',
        ),
      );
    }

    return repository.addMessage(params.message);
  }
}

/// Parameters for [AddMessageUseCase].
class AddMessageParams extends Equatable {
  final ChatMessage message;

  const AddMessageParams({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Use case for updating a message.
class UpdateMessageUseCase extends UseCase<ChatMessage, UpdateMessageParams> {
  final ChatRepository repository;

  UpdateMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(UpdateMessageParams params) async {
    if (params.message.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message ID is required',
          code: 'MISSING_MESSAGE_ID',
        ),
      );
    }

    return repository.updateMessage(params.message);
  }
}

/// Parameters for [UpdateMessageUseCase].
class UpdateMessageParams extends Equatable {
  final ChatMessage message;

  const UpdateMessageParams({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Use case for deleting a message.
class DeleteMessageUseCase extends UseCase<void, DeleteMessageParams> {
  final ChatRepository repository;

  DeleteMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    if (params.messageId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message ID is required',
          code: 'MISSING_MESSAGE_ID',
        ),
      );
    }

    return repository.deleteMessage(params.messageId);
  }
}

/// Parameters for [DeleteMessageUseCase].
class DeleteMessageParams extends Equatable {
  final String messageId;

  const DeleteMessageParams({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Use case for getting recent messages in a session.
class GetRecentMessagesUseCase
    extends UseCase<List<ChatMessage>, GetRecentMessagesParams> {
  final ChatRepository repository;

  GetRecentMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetRecentMessagesParams params,
  ) async {
    if (params.sessionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Session ID is required',
          code: 'MISSING_SESSION_ID',
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

    return repository.getRecentMessages(params.sessionId, limit: params.limit);
  }
}

/// Parameters for [GetRecentMessagesUseCase].
class GetRecentMessagesParams extends Equatable {
  final String sessionId;
  final int limit;

  const GetRecentMessagesParams({required this.sessionId, this.limit = 50});

  @override
  List<Object?> get props => [sessionId, limit];
}
