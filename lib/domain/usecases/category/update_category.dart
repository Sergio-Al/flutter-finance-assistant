import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for updating a category.
///
/// Only custom (non-system) categories can be updated.
///
/// ## Example Usage
/// ```dart
/// final useCase = UpdateCategoryUseCase(categoryRepository);
///
/// final result = await useCase(
///   UpdateCategoryParams(category: updatedCategory),
/// );
/// ```
class UpdateCategoryUseCase extends UseCase<Category, UpdateCategoryParams> {
  final CategoryRepository repository;

  UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Category>> call(UpdateCategoryParams params) async {
    if (params.category.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category ID is required',
          code: 'MISSING_CATEGORY_ID',
        ),
      );
    }

    if (params.category.isSystem) {
      return const Left(
        ValidationFailure(
          message: 'System categories cannot be modified',
          code: 'SYSTEM_CATEGORY_EDIT',
        ),
      );
    }

    if (params.category.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category name is required',
          code: 'MISSING_CATEGORY_NAME',
        ),
      );
    }

    return repository.updateCategory(params.category);
  }
}

/// Parameters for [UpdateCategoryUseCase].
class UpdateCategoryParams extends Equatable {
  final Category category;

  const UpdateCategoryParams({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Use case for deleting a category.
///
/// Only custom (non-system) categories can be deleted.
class DeleteCategoryUseCase extends UseCase<void, DeleteCategoryParams> {
  final CategoryRepository repository;

  DeleteCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCategoryParams params) async {
    if (params.categoryId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category ID is required',
          code: 'MISSING_CATEGORY_ID',
        ),
      );
    }

    // First check if it's a system category
    final categoryResult = await repository.getCategoryById(params.categoryId);

    return categoryResult.fold((failure) => Left(failure), (category) {
      if (category.isSystem) {
        return const Left(
          ValidationFailure(
            message: 'System categories cannot be deleted',
            code: 'SYSTEM_CATEGORY_DELETE',
          ),
        );
      }
      return repository.deleteCategory(params.categoryId);
    });
  }
}

/// Parameters for [DeleteCategoryUseCase].
class DeleteCategoryParams extends Equatable {
  final String categoryId;

  const DeleteCategoryParams({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
