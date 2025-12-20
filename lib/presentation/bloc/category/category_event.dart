import 'package:equatable/equatable.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';

/// Base class for all category events.
sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// Load Events
// ═══════════════════════════════════════════════════════════════════════════

/// Load all categories for a user.
final class CategoryLoadRequested extends CategoryEvent {
  final String userId;

  const CategoryLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load categories by type (expense or income).
final class CategoryLoadByTypeRequested extends CategoryEvent {
  final String userId;
  final CategoryType type;

  const CategoryLoadByTypeRequested({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

/// Load expense categories only.
final class CategoryLoadExpenseRequested extends CategoryEvent {
  final String userId;

  const CategoryLoadExpenseRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Load income categories only.
final class CategoryLoadIncomeRequested extends CategoryEvent {
  final String userId;

  const CategoryLoadIncomeRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Start watching categories (real-time stream).
final class CategoryWatchRequested extends CategoryEvent {
  final String userId;

  const CategoryWatchRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ═══════════════════════════════════════════════════════════════════════════
// CRUD Events
// ═══════════════════════════════════════════════════════════════════════════

/// Create a new custom category.
final class CategoryCreateRequested extends CategoryEvent {
  final String userId;
  final String name;
  final String icon;
  final int color;
  final CategoryType type;
  final String? parentId;

  const CategoryCreateRequested({
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
  });

  @override
  List<Object?> get props => [userId, name, icon, color, type, parentId];
}

/// Update an existing category.
final class CategoryUpdateRequested extends CategoryEvent {
  final Category category;

  const CategoryUpdateRequested({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Delete a category.
final class CategoryDeleteRequested extends CategoryEvent {
  final String categoryId;

  const CategoryDeleteRequested({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

// ═══════════════════════════════════════════════════════════════════════════
// Search & Filter Events
// ═══════════════════════════════════════════════════════════════════════════

/// Search categories by name.
final class CategorySearchRequested extends CategoryEvent {
  final String userId;
  final String query;

  const CategorySearchRequested({required this.userId, required this.query});

  @override
  List<Object?> get props => [userId, query];
}

/// Filter categories by type.
final class CategoryFilterChanged extends CategoryEvent {
  final CategoryType? type;

  const CategoryFilterChanged({this.type});

  @override
  List<Object?> get props => [type];
}

// ═══════════════════════════════════════════════════════════════════════════
// Selection Events
// ═══════════════════════════════════════════════════════════════════════════

/// Select a category (for budget/transaction creation).
final class CategorySelected extends CategoryEvent {
  final Category category;

  const CategorySelected({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Clear category selection.
final class CategorySelectionCleared extends CategoryEvent {
  const CategorySelectionCleared();
}

// ═══════════════════════════════════════════════════════════════════════════
// Initialization Events
// ═══════════════════════════════════════════════════════════════════════════

/// Initialize default categories for a new user.
final class CategoryInitializeDefaultsRequested extends CategoryEvent {
  final String userId;

  const CategoryInitializeDefaultsRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// ═══════════════════════════════════════════════════════════════════════════
// Internal Events
// ═══════════════════════════════════════════════════════════════════════════

/// Internal event when watched categories change.
final class CategoryDataChanged extends CategoryEvent {
  final List<Category> categories;

  const CategoryDataChanged({required this.categories});

  @override
  List<Object?> get props => [categories];
}

/// Clear any error state.
final class CategoryErrorCleared extends CategoryEvent {
  const CategoryErrorCleared();
}
