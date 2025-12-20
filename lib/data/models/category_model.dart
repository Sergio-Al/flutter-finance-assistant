import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/category.dart';

part 'category_model.g.dart';

/// Data model for Category entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class CategoryModel {
  /// Unique identifier
  final String id;

  /// Owner user ID (null for system categories)
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Category display name
  final String name;

  /// Icon name for display
  final String icon;

  /// Color hex value for display
  final int color;

  /// Whether this is for expense or income
  final String type;

  /// Parent category ID for subcategories
  @JsonKey(name: 'parent_id')
  final String? parentId;

  /// Whether this is a system-defined category
  @JsonKey(name: 'is_system')
  final bool isSystem;

  /// When the category was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const CategoryModel({
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

  /// Create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  /// Convert to domain entity
  Category toEntity() => Category(
        id: id,
        userId: userId,
        name: name,
        icon: icon,
        color: color,
        type: CategoryTypeExtension.fromString(type),
        parentId: parentId,
        isSystem: isSystem,
        createdAt: createdAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory CategoryModel.fromEntity(Category entity) => CategoryModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        icon: entity.icon,
        color: entity.color,
        type: entity.type.value,
        parentId: entity.parentId,
        isSystem: entity.isSystem,
        createdAt: entity.createdAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CategoryModel.fromJson({
      'id': documentId,
      ...data,
    });
  }

  /// Convert to Firestore document (without id)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  // DateTime JSON converters
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Firestore Timestamp
    if (value != null && value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  static dynamic _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();
}
