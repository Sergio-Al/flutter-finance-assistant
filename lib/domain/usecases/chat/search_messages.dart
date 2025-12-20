import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for searching messages across all sessions.
///
/// ## Example Usage
/// ```dart
/// final useCase = SearchMessagesUseCase(chatRepository);
///
/// final result = await useCase(
///   SearchMessagesParams(
///     userId: 'user-123',
///     query: 'budget',
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (messages) => displaySearchResults(messages),
/// );
/// ```
class SearchMessagesUseCase
    extends UseCase<List<ChatMessage>, SearchMessagesParams> {
  final ChatRepository repository;

  SearchMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    SearchMessagesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.query.trim().isEmpty) {
      return const Right([]);
    }

    return repository.searchMessages(params.userId, params.query.trim());
  }
}

/// Parameters for [SearchMessagesUseCase].
class SearchMessagesParams extends Equatable {
  final String userId;
  final String query;

  const SearchMessagesParams({required this.userId, required this.query});

  @override
  List<Object?> get props => [userId, query];
}
