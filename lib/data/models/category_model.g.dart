// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: (json['color'] as num).toInt(),
      type: json['type'] as String,
      parentId: json['parent_id'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: CategoryModel._dateTimeFromJson(json['created_at']),
      syncStatus: json['sync_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'type': instance.type,
      'parent_id': instance.parentId,
      'is_system': instance.isSystem,
      'created_at': CategoryModel._dateTimeToJson(instance.createdAt),
      'sync_status': instance.syncStatus,
    };
