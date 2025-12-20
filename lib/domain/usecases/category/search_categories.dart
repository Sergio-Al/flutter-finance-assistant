import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for searching categories by name.
///
/// ## Example Usage
/// ```dart
/// final useCase = SearchCategoriesUseCase(categoryRepository);
///
/// final result = await useCase(
///   SearchCategoriesParams(
///     userId: 'user-123',
///     query: 'food',
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (categories) => displaySearchResults(categories),
/// );
/// ```
class SearchCategoriesUseCase
    extends UseCase<List<Category>, SearchCategoriesParams> {
  final CategoryRepository repository;

  SearchCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    SearchCategoriesParams params,
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
      // Return all categories if query is empty
      return repository.getCategories(params.userId);
    }

    return repository.searchCategories(params.userId, params.query.trim());
  }
}

/// Parameters for [SearchCategoriesUseCase].
class SearchCategoriesParams extends Equatable {
  final String userId;
  final String query;

  const SearchCategoriesParams({required this.userId, required this.query});

  @override
  List<Object?> get props => [userId, query];
}

/// Use case for getting most frequently used categories.
///
/// Useful for quick selection in transaction forms.
class GetMostUsedCategoriesUseCase
    extends UseCase<List<Category>, GetMostUsedCategoriesParams> {
  final CategoryRepository repository;

  GetMostUsedCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetMostUsedCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.limit <= 0) {
      return const Left(
        ValidationFailure(
          message: 'Limit must be greater than zero',
          code: 'INVALID_LIMIT',
        ),
      );
    }

    return repository.getMostUsedCategories(params.userId, limit: params.limit);
  }
}

/// Parameters for [GetMostUsedCategoriesUseCase].
class GetMostUsedCategoriesParams extends Equatable {
  final String userId;
  final int limit;

  const GetMostUsedCategoriesParams({required this.userId, this.limit = 5});

  @override
  List<Object?> get props => [userId, limit];
}

/// Use case for getting custom (user-created) categories only.
class GetCustomCategoriesUseCase
    extends UseCase<List<Category>, GetCustomCategoriesParams> {
  final CategoryRepository repository;

  GetCustomCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetCustomCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getCustomCategories(params.userId);
  }
}

/// Parameters for [GetCustomCategoriesUseCase].
class GetCustomCategoriesParams extends Equatable {
  final String userId;

  const GetCustomCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting system-defined categories.
class GetSystemCategoriesUseCase extends UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;

  GetSystemCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) {
    return repository.getSystemCategories();
  }
}
