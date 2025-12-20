import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for signing out the current user.
///
/// Clears authentication state and local session data.
///
/// ## Example Usage
/// ```dart
/// final useCase = SignOutUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (_) => navigateToLogin(),
/// );
/// ```
class SignOutUseCase extends UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.signOut();
  }
}

/// Use case for getting the current authenticated user ID.
///
/// Returns null if no user is authenticated.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetCurrentUserIdUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => handleError(failure),
///   (userId) {
///     if (userId != null) {
///       // User is signed in
///     } else {
///       // No user signed in
///     }
///   },
/// );
/// ```
class GetCurrentUserIdUseCase extends UseCase<String?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserIdUseCase(this.repository);

  @override
  Future<Either<Failure, String?>> call(NoParams params) {
    return repository.getCurrentUserId();
  }
}

/// Use case for checking if a user is authenticated.
///
/// ## Example Usage
/// ```dart
/// final useCase = IsAuthenticatedUseCase(authRepository);
///
/// final result = await useCase(NoParams());
///
/// result.fold(
///   (failure) => handleError(failure),
///   (isAuthenticated) {
///     if (isAuthenticated) {
///       navigateToDashboard();
///     } else {
///       navigateToLogin();
///     }
///   },
/// );
/// ```
class IsAuthenticatedUseCase extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsAuthenticatedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.isAuthenticated();
  }
}

/// Use case for watching authentication state changes.
///
/// Emits the user ID when authenticated, null when signed out.
///
/// ## Example Usage
/// ```dart
/// final useCase = WatchAuthStateUseCase(authRepository);
///
/// useCase(NoParams()).listen((result) {
///   result.fold(
///     (failure) => handleError(failure),
///     (userId) {
///       if (userId != null) {
///         emit(Authenticated(userId));
///       } else {
///         emit(Unauthenticated());
///       }
///     },
///   );
/// });
/// ```
class WatchAuthStateUseCase extends StreamUseCase<String?, NoParams> {
  final AuthRepository repository;

  WatchAuthStateUseCase(this.repository);

  @override
  Stream<Either<Failure, String?>> call(NoParams params) {
    return repository.watchAuthState();
  }
}
