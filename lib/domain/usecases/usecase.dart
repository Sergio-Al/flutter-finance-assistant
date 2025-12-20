import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';

/// Base class for all use cases in the application.
///
/// Use cases encapsulate a single piece of business logic and represent
/// a specific action the user can perform in the app.
///
/// ## Design Pattern
/// Follows the Command pattern where each use case is a single command
/// that can be executed with specific parameters.
///
/// ## Type Parameters
/// - [Type]: The success return type (Right side of Either)
/// - [Params]: The parameters required to execute the use case
///
/// ## Usage Example
/// ```dart
/// class GetUserUseCase extends UseCase<User, GetUserParams> {
///   final UserRepository repository;
///
///   GetUserUseCase(this.repository);
///
///   @override
///   Future<Either<Failure, User>> call(GetUserParams params) {
///     return repository.getUserById(params.userId);
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  /// Executes the use case with the given parameters.
  ///
  /// Returns [Either<Failure, Type>] where:
  /// - Left: Contains a [Failure] if the operation failed
  /// - Right: Contains the success value of type [Type]
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this class when the use case doesn't require any parameters.
///
/// ## Usage Example
/// ```dart
/// class GetCurrentUserUseCase extends UseCase<User, NoParams> {
///   @override
///   Future<Either<Failure, User>> call(NoParams params) {
///     return repository.getCurrentUser();
///   }
/// }
///
/// // Calling:
/// final result = await getCurrentUserUseCase(NoParams());
/// ```
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Base class for use cases that return a Stream instead of a Future.
///
/// Useful for real-time data updates, like watching transactions
/// or listening to account balance changes.
///
/// ## Usage Example
/// ```dart
/// class WatchTransactionsUseCase extends StreamUseCase<List<Transaction>, WatchParams> {
///   @override
///   Stream<Either<Failure, List<Transaction>>> call(WatchParams params) {
///     return repository.watchTransactions(params.accountId);
///   }
/// }
/// ```
abstract class StreamUseCase<Type, Params> {
  /// Executes the use case and returns a stream of results.
  Stream<Either<Failure, Type>> call(Params params);
}
