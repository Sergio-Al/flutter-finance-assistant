import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for initializing default categories for a new user.
///
/// Should be called when a user registers or on first app launch.
///
/// ## Example Usage
/// ```dart
/// final useCase = InitializeDefaultCategoriesUseCase(categoryRepository);
///
/// final result = await useCase(
///   InitializeDefaultCategoriesParams(userId: 'new-user-123'),
/// );
///
/// result.fold(
///   (failure) => handleError(failure),
///   (categories) => print('Created ${categories.length} default categories'),
/// );
/// ```
class InitializeDefaultCategoriesUseCase
    extends UseCase<List<Category>, InitializeDefaultCategoriesParams> {
  final CategoryRepository repository;

  InitializeDefaultCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    InitializeDefaultCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.initializeDefaultCategories(params.userId);
  }
}

/// Parameters for [InitializeDefaultCategoriesUseCase].
class InitializeDefaultCategoriesParams extends Equatable {
  final String userId;

  const InitializeDefaultCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for watching categories in real-time.
///
/// Returns a [Stream] that emits whenever categories change.
class WatchCategoriesUseCase
    extends StreamUseCase<List<Category>, WatchCategoriesParams> {
  final CategoryRepository repository;

  WatchCategoriesUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Category>>> call(WatchCategoriesParams params) {
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

    return repository.watchCategories(params.userId);
  }
}

/// Parameters for [WatchCategoriesUseCase].
class WatchCategoriesParams extends Equatable {
  final String userId;

  const WatchCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting a single category by ID.
class GetCategoryByIdUseCase extends UseCase<Category, GetCategoryByIdParams> {
  final CategoryRepository repository;

  GetCategoryByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(GetCategoryByIdParams params) async {
    if (params.categoryId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category ID is required',
          code: 'MISSING_CATEGORY_ID',
        ),
      );
    }

    return repository.getCategoryById(params.categoryId);
  }
}

/// Parameters for [GetCategoryByIdUseCase].
class GetCategoryByIdParams extends Equatable {
  final String categoryId;

  const GetCategoryByIdParams({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
