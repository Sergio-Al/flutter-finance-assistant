import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/usecases/category/category_usecases.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_state.dart';

/// BLoC for managing category state.
///
/// Handles loading, creating, updating, and deleting categories.
/// Supports filtering, searching, and category selection for forms.
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategoriesUseCase getCategories;
  final GetCategoriesByTypeUseCase getCategoriesByType;
  final GetExpenseCategoriesUseCase getExpenseCategories;
  final GetIncomeCategoriesUseCase getIncomeCategories;
  final CreateCategoryUseCase createCategory;
  final UpdateCategoryUseCase updateCategory;
  final SearchCategoriesUseCase searchCategories;
  final WatchCategoriesUseCase watchCategories;
  final InitializeDefaultCategoriesUseCase initializeDefaults;

  /// Stream subscription for watching categories.
  StreamSubscription? _categoriesSubscription;

  /// Cached categories for maintaining state during operations.
  List<Category> _cachedCategories = [];

  /// Current filter type.
  CategoryType? _currentFilter;

  /// Currently selected category.
  Category? _selectedCategory;

  CategoryBloc({
    required this.getCategories,
    required this.getCategoriesByType,
    required this.getExpenseCategories,
    required this.getIncomeCategories,
    required this.createCategory,
    required this.updateCategory,
    required this.searchCategories,
    required this.watchCategories,
    required this.initializeDefaults,
  }) : super(const CategoryInitial()) {
    // Load events
    on<CategoryLoadRequested>(_onLoadRequested);
    on<CategoryLoadByTypeRequested>(_onLoadByTypeRequested);
    on<CategoryLoadExpenseRequested>(_onLoadExpenseRequested);
    on<CategoryLoadIncomeRequested>(_onLoadIncomeRequested);
    on<CategoryWatchRequested>(_onWatchRequested);

    // CRUD events
    on<CategoryCreateRequested>(_onCreateRequested);
    on<CategoryUpdateRequested>(_onUpdateRequested);
    on<CategoryDeleteRequested>(_onDeleteRequested);

    // Search & Filter events
    on<CategorySearchRequested>(_onSearchRequested);
    on<CategoryFilterChanged>(_onFilterChanged);

    // Selection events
    on<CategorySelected>(_onSelected);
    on<CategorySelectionCleared>(_onSelectionCleared);

    // Initialization events
    on<CategoryInitializeDefaultsRequested>(_onInitializeDefaultsRequested);

    // Internal events
    on<CategoryDataChanged>(_onDataChanged);
    on<CategoryErrorCleared>(_onErrorCleared);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Load Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onLoadRequested(
    CategoryLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Loading categories...'));

    final result = await getCategories(
      GetCategoriesParams(userId: event.userId),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      _cachedCategories = categories;
      emit(
        CategoryLoaded(
          categories: categories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onLoadByTypeRequested(
    CategoryLoadByTypeRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Loading categories...'));

    final result = await getCategoriesByType(
      GetCategoriesByTypeParams(userId: event.userId, type: event.type),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      _cachedCategories = categories;
      _currentFilter = event.type;
      emit(
        CategoryLoaded(
          categories: categories,
          filter: event.type,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onLoadExpenseRequested(
    CategoryLoadExpenseRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Loading expense categories...'));

    final result = await getExpenseCategories(
      GetExpenseCategoriesParams(userId: event.userId),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      _cachedCategories = categories;
      _currentFilter = CategoryType.expense;
      emit(
        CategoryLoaded(
          categories: categories,
          filter: CategoryType.expense,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onLoadIncomeRequested(
    CategoryLoadIncomeRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Loading income categories...'));

    final result = await getIncomeCategories(
      GetIncomeCategoriesParams(userId: event.userId),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      _cachedCategories = categories;
      _currentFilter = CategoryType.income;
      emit(
        CategoryLoaded(
          categories: categories,
          filter: CategoryType.income,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onWatchRequested(
    CategoryWatchRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Loading categories...'));

    // Cancel existing subscription
    await _categoriesSubscription?.cancel();

    // Start watching
    _categoriesSubscription =
        watchCategories(WatchCategoriesParams(userId: event.userId)).listen(
          (result) {
            result.fold(
              (failure) => add(CategoryErrorCleared()), // Could emit error
              (categories) => add(CategoryDataChanged(categories: categories)),
            );
          },
          onError: (error) {
            // Handle stream errors
          },
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onCreateRequested(
    CategoryCreateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Creating category...'));

    print('Creating category: ${event.name}');

    final result = await createCategory(
      CreateCategoryParams(
        userId: event.userId,
        name: event.name,
        icon: event.icon,
        color: event.color,
        type: event.type,
        parentId: event.parentId,
      ),
    );

    print('Create category result: $result');

    result.fold((failure) => emit(_mapFailureToState(failure)), (category) {
      print(  'Created category: ${category.name}');
      // Add to cached categories
      _cachedCategories = [..._cachedCategories, category];

      emit(
        CategoryOperationSuccess(
          operationType: CategoryOperationType.create,
          message: 'Category "${category.name}" created successfully',
          category: category,
        ),
      );

      // Return to loaded state with updated categories
      emit(
        CategoryLoaded(
          categories: _cachedCategories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onUpdateRequested(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    // Check if can edit
    if (event.category.isSystem) {
      emit(
        const CategoryError(
          errorType: CategoryErrorType.cannotEditSystem,
          message: 'System categories cannot be edited',
          code: 'CANNOT_EDIT_SYSTEM',
        ),
      );
      return;
    }

    emit(const CategoryLoading(message: 'Updating category...'));

    final result = await updateCategory(
      UpdateCategoryParams(category: event.category),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (category) {
      // Update in cached categories
      _cachedCategories = _cachedCategories.map((c) {
        return c.id == category.id ? category : c;
      }).toList();

      emit(
        CategoryOperationSuccess(
          operationType: CategoryOperationType.update,
          message: 'Category "${category.name}" updated successfully',
          category: category,
        ),
      );

      // Return to loaded state
      emit(
        CategoryLoaded(
          categories: _cachedCategories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory?.id == category.id
              ? category
              : _selectedCategory,
        ),
      );
    });
  }

  Future<void> _onDeleteRequested(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    // Find the category to check if it can be deleted
    final category = _cachedCategories.firstWhere(
      (c) => c.id == event.categoryId,
      orElse: () => throw Exception('Category not found'),
    );

    if (category.isSystem) {
      emit(
        const CategoryError(
          errorType: CategoryErrorType.cannotDeleteSystem,
          message: 'System categories cannot be deleted',
          code: 'CANNOT_DELETE_SYSTEM',
        ),
      );
      return;
    }

    // Check for subcategories
    final hasSubcategories = _cachedCategories.any(
      (c) => c.parentId == event.categoryId,
    );
    if (hasSubcategories) {
      emit(
        const CategoryError(
          errorType: CategoryErrorType.hasSubcategories,
          message: 'Cannot delete category with subcategories',
          code: 'HAS_SUBCATEGORIES',
        ),
      );
      return;
    }

    emit(const CategoryLoading(message: 'Deleting category...'));

    // TODO: Implement delete use case when available
    // For now, just remove from cache
    _cachedCategories = _cachedCategories
        .where((c) => c.id != event.categoryId)
        .toList();

    emit(
      CategoryOperationSuccess(
        operationType: CategoryOperationType.delete,
        message: 'Category deleted successfully',
      ),
    );

    // Clear selection if deleted category was selected
    if (_selectedCategory?.id == event.categoryId) {
      _selectedCategory = null;
    }

    emit(
      CategoryLoaded(
        categories: _cachedCategories,
        filter: _currentFilter,
        selectedCategory: _selectedCategory,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search & Filter Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onSearchRequested(
    CategorySearchRequested event,
    Emitter<CategoryState> emit,
  ) async {
    if (event.query.isEmpty) {
      // Clear search, return to full list
      emit(
        CategoryLoaded(
          categories: _cachedCategories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
        ),
      );
      return;
    }

    emit(const CategoryLoading(message: 'Searching...'));

    final result = await searchCategories(
      SearchCategoriesParams(userId: event.userId, query: event.query),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      emit(
        CategoryLoaded(
          categories: categories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
          searchQuery: event.query,
        ),
      );
    });
  }

  void _onFilterChanged(
    CategoryFilterChanged event,
    Emitter<CategoryState> emit,
  ) {
    _currentFilter = event.type;

    emit(
      CategoryLoaded(
        categories: _cachedCategories,
        filter: event.type,
        selectedCategory: _selectedCategory,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Selection Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  void _onSelected(CategorySelected event, Emitter<CategoryState> emit) {
    _selectedCategory = event.category;

    if (state is CategoryLoaded) {
      emit(
        (state as CategoryLoaded).copyWith(selectedCategory: event.category),
      );
    }
  }

  void _onSelectionCleared(
    CategorySelectionCleared event,
    Emitter<CategoryState> emit,
  ) {
    _selectedCategory = null;

    if (state is CategoryLoaded) {
      emit((state as CategoryLoaded).copyWith(clearSelection: true));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialization Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onInitializeDefaultsRequested(
    CategoryInitializeDefaultsRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading(message: 'Setting up categories...'));

    final result = await initializeDefaults(
      InitializeDefaultCategoriesParams(userId: event.userId),
    );

    result.fold((failure) => emit(_mapFailureToState(failure)), (categories) {
      _cachedCategories = categories;

      emit(
        CategoryOperationSuccess(
          operationType: CategoryOperationType.initialize,
          message: 'Default categories created successfully',
        ),
      );

      emit(
        CategoryLoaded(
          categories: categories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Internal Event Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDataChanged(CategoryDataChanged event, Emitter<CategoryState> emit) {
    _cachedCategories = event.categories;

    emit(
      CategoryLoaded(
        categories: event.categories,
        filter: _currentFilter,
        selectedCategory: _selectedCategory,
      ),
    );
  }

  void _onErrorCleared(
    CategoryErrorCleared event,
    Emitter<CategoryState> emit,
  ) {
    if (_cachedCategories.isNotEmpty) {
      emit(
        CategoryLoaded(
          categories: _cachedCategories,
          filter: _currentFilter,
          selectedCategory: _selectedCategory,
        ),
      );
    } else {
      emit(const CategoryInitial());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════════════════

  CategoryError _mapFailureToState(Failure failure) {
    final errorType = _mapFailureToErrorType(failure);
    return CategoryError(
      errorType: errorType,
      message: failure.message,
      code: failure.code,
    );
  }

  CategoryErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => CategoryErrorType.notFound,
      ConflictFailure() => CategoryErrorType.alreadyExists,
      ValidationFailure() => CategoryErrorType.invalidData,
      NetworkFailure() => CategoryErrorType.networkError,
      DatabaseFailure() => CategoryErrorType.databaseError,
      _ => CategoryErrorType.unknown,
    };
  }

  @override
  Future<void> close() {
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
