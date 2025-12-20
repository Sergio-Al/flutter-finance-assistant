import 'package:equatable/equatable.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';

/// Enum for category operation types.
enum CategoryOperationType { create, update, delete, initialize }

/// Enum for category error types with user-friendly messages.
enum CategoryErrorType {
  notFound('Category not found'),
  alreadyExists('A category with this name already exists'),
  invalidData('Invalid category data'),
  cannotDeleteSystem('System categories cannot be deleted'),
  cannotEditSystem('System categories cannot be edited'),
  hasSubcategories('Cannot delete category with subcategories'),
  networkError('Network error occurred'),
  databaseError('Database error occurred'),
  unknown('An unexpected error occurred');

  final String message;
  const CategoryErrorType(this.message);
}

/// Base class for all category states.
sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
final class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

/// Loading state while fetching categories.
final class CategoryLoading extends CategoryState {
  final String? message;

  const CategoryLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when categories are successfully loaded.
final class CategoryLoaded extends CategoryState {
  /// All loaded categories.
  final List<Category> categories;

  /// Currently applied filter (null = all).
  final CategoryType? filter;

  /// Currently selected category.
  final Category? selectedCategory;

  /// Search query if any.
  final String? searchQuery;

  const CategoryLoaded({
    required this.categories,
    this.filter,
    this.selectedCategory,
    this.searchQuery,
  });

  /// Get expense categories.
  List<Category> get expenseCategories =>
      categories.where((c) => c.type == CategoryType.expense).toList();

  /// Get income categories.
  List<Category> get incomeCategories =>
      categories.where((c) => c.type == CategoryType.income).toList();

  /// Get filtered categories based on current filter.
  List<Category> get filteredCategories {
    if (filter == null) return categories;
    return categories.where((c) => c.type == filter).toList();
  }

  /// Get system categories.
  List<Category> get systemCategories =>
      categories.where((c) => c.isSystem).toList();

  /// Get custom (user-created) categories.
  List<Category> get customCategories =>
      categories.where((c) => !c.isSystem).toList();

  /// Get parent categories (no parentId).
  List<Category> get parentCategories =>
      categories.where((c) => c.parentId == null).toList();

  /// Get subcategories for a parent.
  List<Category> getSubcategoriesFor(String parentId) =>
      categories.where((c) => c.parentId == parentId).toList();

  /// Copy with modifications.
  CategoryLoaded copyWith({
    List<Category>? categories,
    CategoryType? filter,
    Category? selectedCategory,
    String? searchQuery,
    bool clearFilter = false,
    bool clearSelection = false,
    bool clearSearch = false,
  }) {
    return CategoryLoaded(
      categories: categories ?? this.categories,
      filter: clearFilter ? null : (filter ?? this.filter),
      selectedCategory: clearSelection
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [
    categories,
    filter,
    selectedCategory,
    searchQuery,
  ];
}

/// State when a category operation succeeds.
final class CategoryOperationSuccess extends CategoryState {
  final CategoryOperationType operationType;
  final String message;
  final Category? category;

  const CategoryOperationSuccess({
    required this.operationType,
    required this.message,
    this.category,
  });

  @override
  List<Object?> get props => [operationType, message, category];
}

/// State when an error occurs.
final class CategoryError extends CategoryState {
  final CategoryErrorType errorType;
  final String message;
  final String? code;

  const CategoryError({
    required this.errorType,
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [errorType, message, code];
}
