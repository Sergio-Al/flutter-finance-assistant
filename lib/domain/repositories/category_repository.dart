import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';

/// Repository interface for category operations.
///
/// Defines the contract for transaction category data access.
/// Implementation will be in the data layer.
abstract class CategoryRepository {
  /// Get all categories for a user (including system categories).
  Future<Either<Failure, List<Category>>> getCategories(String userId);

  /// Get categories by type (expense or income).
  Future<Either<Failure, List<Category>>> getCategoriesByType(
    String userId,
    CategoryType type,
  );

  /// Get expense categories only.
  Future<Either<Failure, List<Category>>> getExpenseCategories(String userId);

  /// Get income categories only.
  Future<Either<Failure, List<Category>>> getIncomeCategories(String userId);

  /// Get category by ID.
  Future<Either<Failure, Category>> getCategoryById(String categoryId);

  /// Get subcategories of a parent category.
  Future<Either<Failure, List<Category>>> getSubcategories(String parentId);

  /// Get system-defined categories.
  Future<Either<Failure, List<Category>>> getSystemCategories();

  /// Get user-created custom categories.
  Future<Either<Failure, List<Category>>> getCustomCategories(String userId);

  /// Create a new custom category.
  Future<Either<Failure, Category>> createCategory(Category category);

  /// Update a category.
  Future<Either<Failure, Category>> updateCategory(Category category);

  /// Delete a category (only custom categories can be deleted).
  Future<Either<Failure, void>> deleteCategory(String categoryId);

  /// Initialize default categories for a new user.
  Future<Either<Failure, List<Category>>> initializeDefaultCategories(
    String userId,
  );

  /// Search categories by name.
  Future<Either<Failure, List<Category>>> searchCategories(
    String userId,
    String query,
  );

  /// Get most used categories based on transaction count.
  Future<Either<Failure, List<Category>>> getMostUsedCategories(
    String userId, {
    int limit = 5,
  });

  /// Stream of categories for real-time updates.
  Stream<Either<Failure, List<Category>>> watchCategories(String userId);
}
