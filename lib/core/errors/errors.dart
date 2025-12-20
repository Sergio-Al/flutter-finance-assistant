/// Error handling classes for the Finance Assistant app.
///
/// Provides a comprehensive set of failure types for functional
/// error handling using dartz's Either type.
///
/// Usage:
/// ```dart
/// Future<Either<Failure, User>> getUser(String id) async {
///   try {
///     final user = await dataSource.getUser(id);
///     return Right(user);
///   } on NetworkException {
///     return Left(NetworkFailure());
///   } catch (e) {
///     return Left(UnexpectedFailure(originalError: e));
///   }
/// }
/// ```
library;

export 'failures.dart';
export 'exceptions.dart';
