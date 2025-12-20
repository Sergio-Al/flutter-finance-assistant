import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/repositories/transaction_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for watching recent transactions in real-time.
///
/// Returns a [Stream] that emits whenever transactions change.
/// Useful for:
/// - Dashboard widgets that show recent activity
/// - Real-time transaction lists
/// - Notification of new transactions
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchRecentTransactionsUseCase(transactionRepository);
///
/// final stream = useCase(
///   WatchRecentTransactionsParams(
///     accountId: 'account-123',
///     limit: 5,
///   ),
/// );
///
/// // In BLoC
/// stream.listen((result) {
///   result.fold(
///     (failure) => emit(TransactionError(failure.message)),
///     (transactions) => emit(RecentTransactionsUpdated(transactions)),
///   );
/// });
/// ```
class WatchRecentTransactionsUseCase
    extends StreamUseCase<List<Transaction>, WatchRecentTransactionsParams> {
  final TransactionRepository repository;

  WatchRecentTransactionsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Transaction>>> call(
    WatchRecentTransactionsParams params,
  ) {
    // Validate account ID
    if (params.accountId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Account ID is required',
            code: 'MISSING_ACCOUNT_ID',
          ),
        ),
      );
    }

    // Validate limit
    if (params.limit <= 0) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'Limit must be greater than zero',
            code: 'INVALID_LIMIT',
          ),
        ),
      );
    }

    return repository.watchRecentTransactions(
      params.accountId,
      limit: params.limit,
    );
  }
}

/// Parameters for [WatchRecentTransactionsUseCase].
class WatchRecentTransactionsParams extends Equatable {
  /// The account ID to watch transactions for
  final String accountId;

  /// Maximum number of transactions to return (default: 10)
  final int limit;

  const WatchRecentTransactionsParams({
    required this.accountId,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [accountId, limit];
}
