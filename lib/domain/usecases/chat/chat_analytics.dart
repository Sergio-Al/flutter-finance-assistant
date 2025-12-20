import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/chat_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for getting total tokens used by a user.
///
/// Useful for tracking AI usage and costs.
class GetTotalTokensUsedUseCase extends UseCase<int, GetTotalTokensUsedParams> {
  final ChatRepository repository;

  GetTotalTokensUsedUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetTotalTokensUsedParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getTotalTokensUsed(params.userId);
  }
}

/// Parameters for [GetTotalTokensUsedUseCase].
class GetTotalTokensUsedParams extends Equatable {
  final String userId;

  const GetTotalTokensUsedParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting tokens used in a specific period.
class GetTokensUsedInPeriodUseCase
    extends UseCase<int, GetTokensUsedInPeriodParams> {
  final ChatRepository repository;

  GetTokensUsedInPeriodUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetTokensUsedInPeriodParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure(
          message: 'Start date must be before or equal to end date',
          code: 'INVALID_DATE_RANGE',
        ),
      );
    }

    return repository.getTokensUsedInPeriod(
      params.userId,
      params.startDate,
      params.endDate,
    );
  }
}

/// Parameters for [GetTokensUsedInPeriodUseCase].
class GetTokensUsedInPeriodParams extends Equatable {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const GetTokensUsedInPeriodParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Use case for getting total message count for a user.
class GetMessageCountUseCase extends UseCase<int, GetMessageCountParams> {
  final ChatRepository repository;

  GetMessageCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetMessageCountParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getMessageCount(params.userId);
  }
}

/// Parameters for [GetMessageCountUseCase].
class GetMessageCountParams extends Equatable {
  final String userId;

  const GetMessageCountParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Combined chat usage statistics.
class ChatUsageStats extends Equatable {
  final int totalTokens;
  final int messageCount;
  final int sessionCount;

  const ChatUsageStats({
    required this.totalTokens,
    required this.messageCount,
    required this.sessionCount,
  });

  @override
  List<Object?> get props => [totalTokens, messageCount, sessionCount];
}
