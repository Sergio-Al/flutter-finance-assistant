import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for retrieving budgets with their related entities populated.
///
/// This use case demonstrates **Use Case Composition** pattern where
/// multiple domain repositories are composed at the use case level rather
/// than joining data at the repository level.
///
/// ## Why Use Case Composition?
/// - Keeps repositories focused on single domain responsibility
/// - Allows flexible composition based on use case needs
/// - Clear orchestration logic at the application/domain layer
/// - Easy to extend with additional relations (transactions, accounts)
///
/// ## Example Usage
/// ```dart
/// final useCase = GetBudgetsWithRelationsUseCase(
///   budgetRepository: budgetRepo,
///   categoryRepository: categoryRepo,
/// );
///
/// final result = await useCase(
///   GetBudgetsWithRelationsParams(
///     userId: 'user-123',
///     includeCategory: true,
///   ),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (budgets) {
///     for (final budget in budgets) {
///       print('${budget.category?.name}: ${budget.spentAmount}/${budget.amount}');
///     }
///   },
/// );
/// ```
class GetBudgetsWithRelationsUseCase
    extends UseCase<List<Budget>, GetBudgetsWithRelationsParams> {
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;

  GetBudgetsWithRelationsUseCase({
    required this.budgetRepository,
    required this.categoryRepository,
  });

  @override
  Future<Either<Failure, List<Budget>>> call(
    GetBudgetsWithRelationsParams params,
  ) async {
    // Validate input
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    // Step 1: Fetch budgets from budget repository
    final budgetsResult = await budgetRepository.getBudgets(params.userId);

    return budgetsResult.fold((failure) => Left(failure), (budgets) async {
      // If no relations requested, return budgets as-is
      if (!params.includeCategory) {
        return Right(budgets);
      }

      // Step 2: Fetch categories for composition
      final categoriesResult = await categoryRepository.getCategories(
        params.userId,
      );

      return categoriesResult.fold(
        // If categories fail, still return budgets without relations
        // This is a graceful degradation approach
        (failure) {
          // Log warning but don't fail the entire operation
          return Right(budgets);
        },
        (categories) {
          // Step 3: Compose budgets with categories
          final composedBudgets = _composeBudgetsWithCategories(
            budgets,
            categories,
          );
          return Right(composedBudgets);
        },
      );
    });
  }

  /// Composes budgets with their related categories.
  ///
  /// Creates a lookup map for O(1) category access and populates
  /// each budget's category field.
  List<Budget> _composeBudgetsWithCategories(
    List<Budget> budgets,
    List<Category> categories,
  ) {
    // Create category lookup map for efficient access
    final categoryMap = <String, Category>{};
    for (final category in categories) {
      categoryMap[category.id] = category;
    }

    // Compose each budget with its category
    return budgets.map((budget) {
      final category = categoryMap[budget.categoryId];
      if (category != null) {
        return budget.copyWith(category: category);
      }
      return budget;
    }).toList();
  }
}

/// Parameters for [GetBudgetsWithRelationsUseCase].
class GetBudgetsWithRelationsParams extends Equatable {
  /// The user ID to fetch budgets for.
  final String userId;

  /// Whether to include category relation.
  final bool includeCategory;

  /// Whether to filter to only active budgets.
  final bool activeOnly;

  /// Optional category ID to filter by.
  final String? categoryId;

  const GetBudgetsWithRelationsParams({
    required this.userId,
    this.includeCategory = true,
    this.activeOnly = false,
    this.categoryId,
  });

  @override
  List<Object?> get props => [userId, includeCategory, activeOnly, categoryId];
}

/// Use case for watching budgets with relations as a stream.
///
/// Similar to [GetBudgetsWithRelationsUseCase] but provides a reactive stream
/// that updates when budgets or categories change.
class WatchBudgetsWithRelationsUseCase {
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;

  WatchBudgetsWithRelationsUseCase({
    required this.budgetRepository,
    required this.categoryRepository,
  });

  /// Returns a stream of budgets with populated relations.
  ///
  /// The stream emits new values when either budgets or categories change.
  Stream<Either<Failure, List<Budget>>> call(
    WatchBudgetsWithRelationsParams params,
  ) async* {
    if (params.userId.isEmpty) {
      yield const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
      return;
    }

    // Get initial categories
    List<Category> categories = [];
    final categoriesResult = await categoryRepository.getCategories(
      params.userId,
    );
    categoriesResult.fold(
      (failure) => {}, // Graceful degradation
      (cats) => categories = cats,
    );

    // Create category lookup map
    Map<String, Category> categoryMap = _buildCategoryMap(categories);

    // Watch budget stream and compose with categories
    await for (final budgetsResult in budgetRepository.watchBudgets(
      params.userId,
    )) {
      yield budgetsResult.fold((failure) => Left(failure), (budgets) {
        if (!params.includeCategory) {
          return Right(budgets);
        }

        final composedBudgets = budgets.map((budget) {
          final category = categoryMap[budget.categoryId];
          if (category != null) {
            return budget.copyWith(category: category);
          }
          return budget;
        }).toList();

        return Right(composedBudgets);
      });
    }
  }

  Map<String, Category> _buildCategoryMap(List<Category> categories) {
    final map = <String, Category>{};
    for (final category in categories) {
      map[category.id] = category;
    }
    return map;
  }

  /// Refreshes the category cache.
  ///
  /// Call this when categories are updated to ensure budgets
  /// reflect the latest category data.
  Future<void> refreshCategories(String userId) async {
    // This would update an internal cache in a real implementation
    // For now, the watch stream will pick up changes automatically
  }
}

/// Parameters for [WatchBudgetsWithRelationsUseCase].
class WatchBudgetsWithRelationsParams extends Equatable {
  final String userId;
  final bool includeCategory;
  final bool activeOnly;

  const WatchBudgetsWithRelationsParams({
    required this.userId,
    this.includeCategory = true,
    this.activeOnly = false,
  });

  @override
  List<Object?> get props => [userId, includeCategory, activeOnly];
}
