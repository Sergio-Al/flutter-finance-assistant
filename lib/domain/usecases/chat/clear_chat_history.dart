import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for deleting old chat sessions.
///
/// ## Example Usage
/// ```dart
/// final useCase = DeleteOldSessionsUseCase(chatRepository);
///
/// // Delete sessions older than 30 days
/// final result = await useCase(
///   DeleteOldSessionsParams(
///     userId: 'user-123',
///     olderThanDays: 30,
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (deletedCount) => showMessage('Deleted $deletedCount sessions'),
/// );
/// ```
class DeleteOldSessionsUseCase extends UseCase<int, DeleteOldSessionsParams> {
  final ChatRepository repository;

  DeleteOldSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(DeleteOldSessionsParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.olderThanDays <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Days must be greater than 0',
          code: 'INVALID_DAYS',
        ),
      );
    }

    return repository.deleteOldSessions(
      params.userId,
      olderThanDays: params.olderThanDays,
    );
  }
}

/// Parameters for [DeleteOldSessionsUseCase].
class DeleteOldSessionsParams extends Equatable {
  final String userId;
  final int olderThanDays;

  const DeleteOldSessionsParams({
    required this.userId,
    this.olderThanDays = 30,
  });

  @override
  List<Object?> get props => [userId, olderThanDays];
}

/// Use case for clearing all chat history for a user.
///
/// ⚠️ Destructive operation - cannot be undone.
class ClearAllHistoryUseCase extends UseCase<void, ClearAllHistoryParams> {
  final ChatRepository repository;

  ClearAllHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ClearAllHistoryParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.clearAllHistory(params.userId);
  }
}

/// Parameters for [ClearAllHistoryUseCase].
class ClearAllHistoryParams extends Equatable {
  final String userId;

  const ClearAllHistoryParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
