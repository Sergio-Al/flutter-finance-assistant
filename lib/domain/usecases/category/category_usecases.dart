/// Barrel export for all category-related use cases.
///
/// Import this file to access all category use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/category/category_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### CRUD Operations
/// - [CreateCategoryUseCase] - Create a custom category
/// - [UpdateCategoryUseCase] - Update a category (custom only)
/// - [DeleteCategoryUseCase] - Delete a category (custom only)
///
/// ### Query Operations
/// - [GetCategoriesUseCase] - Get all categories
/// - [GetCategoriesByTypeUseCase] - Get by expense/income type
/// - [GetExpenseCategoriesUseCase] - Get expense categories
/// - [GetIncomeCategoriesUseCase] - Get income categories
/// - [GetSubcategoriesUseCase] - Get subcategories of a parent
/// - [GetCategoryByIdUseCase] - Get a single category
///
/// ### Search & Discovery
/// - [SearchCategoriesUseCase] - Search categories by name
/// - [GetMostUsedCategoriesUseCase] - Get frequently used categories
/// - [GetCustomCategoriesUseCase] - Get user-created categories
/// - [GetSystemCategoriesUseCase] - Get system-defined categories
///
/// ### Initialization
/// - [InitializeDefaultCategoriesUseCase] - Setup default categories for new user
///
/// ### Real-time Streams
/// - [WatchCategoriesUseCase] - Stream all categories
library;

export 'create_category.dart';
export 'get_categories.dart';
export 'initialize_categories.dart';
export 'search_categories.dart';
export 'update_category.dart';
