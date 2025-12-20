import 'package:equatable/equatable.dart';

/// Represents a transaction category in the domain layer.
///
/// Categories can be system-defined or user-created.
/// Supports hierarchical structure with parent-child relationships.
class Category extends Equatable {
  /// Unique identifier
  final String id;

  /// Owner user ID (null for system categories)
  final String? userId;

  /// Category display name
  final String name;

  /// Icon name for display
  final String icon;

  /// Color hex value for display
  final int color;

  /// Whether this is for expense or income
  final CategoryType type;

  /// Parent category ID for subcategories
  final String? parentId;

  /// Whether this is a system-defined category
  final bool isSystem;

  /// When the category was created
  final DateTime createdAt;

  /// Sync status with remote
  final String syncStatus;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.parentId,
    this.isSystem = false,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  /// Creates a copy with modified fields
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    int? color,
    CategoryType? type,
    String? parentId,
    bool? isSystem,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Whether this is a subcategory
  bool get isSubcategory => parentId != null;

  /// Whether this category can be deleted (not system)
  bool get canDelete => !isSystem;

  /// Whether this category can be edited
  bool get canEdit => !isSystem;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        color,
        type,
        parentId,
        isSystem,
        createdAt,
        syncStatus,
      ];
}

/// Types of categories
enum CategoryType {
  expense,
  income,
}

/// Extension for CategoryType utilities
extension CategoryTypeExtension on CategoryType {
  String get value {
    switch (this) {
      case CategoryType.expense:
        return 'expense';
      case CategoryType.income:
        return 'income';
    }
  }

  static CategoryType fromString(String value) {
    switch (value) {
      case 'expense':
        return CategoryType.expense;
      case 'income':
        return CategoryType.income;
      default:
        return CategoryType.expense;
    }
  }

  String get displayName {
    switch (this) {
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.income:
        return 'Income';
    }
  }
}

/// Default expense categories
class DefaultCategories {
  DefaultCategories._();

  static const List<Map<String, dynamic>> expense = [
    {'name': 'Food & Dining', 'icon': 'restaurant', 'color': 0xFFFF6B6B},
    {'name': 'Transportation', 'icon': 'directions_car', 'color': 0xFF4ECDC4},
    {'name': 'Shopping', 'icon': 'shopping_bag', 'color': 0xFFFFE66D},
    {'name': 'Entertainment', 'icon': 'movie', 'color': 0xFF95E1D3},
    {'name': 'Bills & Utilities', 'icon': 'receipt_long', 'color': 0xFFF38181},
    {'name': 'Health & Medical', 'icon': 'medical_services', 'color': 0xFFAA96DA},
    {'name': 'Groceries', 'icon': 'local_grocery_store', 'color': 0xFF80ED99},
    {'name': 'Personal Care', 'icon': 'spa', 'color': 0xFFDDB892},
    {'name': 'Education', 'icon': 'school', 'color': 0xFF90DBF4},
    {'name': 'Travel', 'icon': 'flight', 'color': 0xFFF9C74F},
    {'name': 'Subscriptions', 'icon': 'subscriptions', 'color': 0xFFA8DADC},
    {'name': 'Other', 'icon': 'more_horiz', 'color': 0xFFBDBDBD},
  ];

  static const List<Map<String, dynamic>> income = [
    {'name': 'Salary', 'icon': 'work', 'color': 0xFF52B788},
    {'name': 'Freelance', 'icon': 'computer', 'color': 0xFF3D5A80},
    {'name': 'Investments', 'icon': 'trending_up', 'color': 0xFF06D6A0},
    {'name': 'Gifts', 'icon': 'card_giftcard', 'color': 0xFFE07BE0},
    {'name': 'Refunds', 'icon': 'replay', 'color': 0xFF48CAE4},
    {'name': 'Other Income', 'icon': 'attach_money', 'color': 0xFF99D98C},
  ];
}
