import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/repositories/account_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for watching accounts in real-time.
///
/// Returns a [Stream] that emits whenever accounts change.
/// Useful for:
/// - Account list screens
/// - Dashboard balance displays
/// - Real-time balance updates
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchAccountsUseCase(accountRepository);
///
/// final stream = useCase(
///   WatchAccountsParams(userId: 'user-123'),
/// );
///
/// // In BLoC
/// await emit.forEach(
///   stream,
///   onData: (result) => result.fold(
///     (failure) => AccountError(failure.message),
///     (accounts) => AccountsLoaded(accounts),
///   ),
/// );
/// ```
class WatchAccountsUseCase
    extends StreamUseCase<List<Account>, WatchAccountsParams> {
  final AccountRepository repository;

  WatchAccountsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Account>>> call(WatchAccountsParams params) {
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

    return repository.watchAccounts(params.userId);
  }
}

/// Parameters for [WatchAccountsUseCase].
class WatchAccountsParams extends Equatable {
  final String userId;

  const WatchAccountsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for watching a single account in real-time.
///
/// Returns a [Stream] that emits whenever the specific account changes.
/// Useful for account detail screens.
class WatchAccountUseCase extends StreamUseCase<Account, WatchAccountParams> {
  final AccountRepository repository;

  WatchAccountUseCase(this.repository);

  @override
  Stream<Either<Failure, Account>> call(WatchAccountParams params) {
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

    return repository.watchAccount(params.accountId);
  }
}

/// Parameters for [WatchAccountUseCase].
class WatchAccountParams extends Equatable {
  final String accountId;

  const WatchAccountParams({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}
