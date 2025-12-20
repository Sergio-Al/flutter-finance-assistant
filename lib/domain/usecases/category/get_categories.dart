import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for retrieving all categories for a user.
///
/// Returns both system and custom categories.
///
/// ## Example Usage
/// ```dart
/// final useCase = GetCategoriesUseCase(categoryRepository);
///
/// final result = await useCase(
///   GetCategoriesParams(userId: 'user-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (categories) => displayCategories(categories),
/// );
/// ```
class GetCategoriesUseCase
    extends UseCase<List<Category>, GetCategoriesParams> {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getCategories(params.userId);
  }
}

/// Parameters for [GetCategoriesUseCase].
class GetCategoriesParams extends Equatable {
  final String userId;

  const GetCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting categories by type.
class GetCategoriesByTypeUseCase
    extends UseCase<List<Category>, GetCategoriesByTypeParams> {
  final CategoryRepository repository;

  GetCategoriesByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetCategoriesByTypeParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getCategoriesByType(params.userId, params.type);
  }
}

/// Parameters for [GetCategoriesByTypeUseCase].
class GetCategoriesByTypeParams extends Equatable {
  final String userId;
  final CategoryType type;

  const GetCategoriesByTypeParams({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

/// Use case for getting expense categories only.
class GetExpenseCategoriesUseCase
    extends UseCase<List<Category>, GetExpenseCategoriesParams> {
  final CategoryRepository repository;

  GetExpenseCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetExpenseCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getExpenseCategories(params.userId);
  }
}

/// Parameters for [GetExpenseCategoriesUseCase].
class GetExpenseCategoriesParams extends Equatable {
  final String userId;

  const GetExpenseCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting income categories only.
class GetIncomeCategoriesUseCase
    extends UseCase<List<Category>, GetIncomeCategoriesParams> {
  final CategoryRepository repository;

  GetIncomeCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetIncomeCategoriesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getIncomeCategories(params.userId);
  }
}

/// Parameters for [GetIncomeCategoriesUseCase].
class GetIncomeCategoriesParams extends Equatable {
  final String userId;

  const GetIncomeCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting subcategories of a parent category.
class GetSubcategoriesUseCase
    extends UseCase<List<Category>, GetSubcategoriesParams> {
  final CategoryRepository repository;

  GetSubcategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(
    GetSubcategoriesParams params,
  ) async {
    if (params.parentId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Parent category ID is required',
          code: 'MISSING_PARENT_ID',
        ),
      );
    }

    return repository.getSubcategories(params.parentId);
  }
}

/// Parameters for [GetSubcategoriesUseCase].
class GetSubcategoriesParams extends Equatable {
  final String parentId;

  const GetSubcategoriesParams({required this.parentId});

  @override
  List<Object?> get props => [parentId];
}
