import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/repositories/transaction_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for retrieving transactions within a specific date range.
///
/// This is a common operation used in:
/// - Monthly expense reports
/// - Custom date filtering in transaction lists
/// - Analytics dashboards
/// - Budget tracking for specific periods
///
/// ## Example Usage
/// ```dart
/// // In BLoC or ViewModel
/// final useCase = GetTransactionsByDateRangeUseCase(transactionRepository);
///
/// final result = await useCase(
///   GetTransactionsByDateRangeParams(
///     accountId: 'account-123',
///     startDate: DateTime(2024, 1, 1),
///     endDate: DateTime(2024, 1, 31),
///   ),
/// );
///
/// result.fold(
///   (failure) => emit(TransactionError(failure.message)),
///   (transactions) => emit(TransactionLoaded(transactions)),
/// );
/// ```
class GetTransactionsByDateRangeUseCase
    extends UseCase<List<Transaction>, GetTransactionsByDateRangeParams> {
  final TransactionRepository repository;

  GetTransactionsByDateRangeUseCase(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(
    GetTransactionsByDateRangeParams params,
  ) async {
    // Validate date range
    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure(
          message: 'Start date must be before or equal to end date',
          code: 'INVALID_DATE_RANGE',
        ),
      );
    }

    // Validate account ID
    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    return repository.getTransactionsByDateRange(
      params.accountId,
      params.startDate,
      params.endDate,
    );
  }
}

/// Parameters for [GetTransactionsByDateRangeUseCase].
///
/// Uses [Equatable] for value comparison, which is useful for:
/// - Caching use case results
/// - Comparing params in BLoC events
/// - Testing equality
class GetTransactionsByDateRangeParams extends Equatable {
  /// The account ID to fetch transactions for
  final String accountId;

  /// Start of the date range (inclusive)
  final DateTime startDate;

  /// End of the date range (inclusive)
  final DateTime endDate;

  const GetTransactionsByDateRangeParams({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [accountId, startDate, endDate];

  /// Creates a copy with modified fields
  GetTransactionsByDateRangeParams copyWith({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return GetTransactionsByDateRangeParams(
      accountId: accountId ?? this.accountId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
