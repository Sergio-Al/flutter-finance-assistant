// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      tokensUsed: (json['tokens_used'] as num?)?.toInt(),
      model: json['model'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: ChatMessageModel._dateTimeFromJson(json['created_at']),
      syncStatus: json['sync_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'session_id': instance.sessionId,
      'role': instance.role,
      'content': instance.content,
      'tokens_used': instance.tokensUsed,
      'model': instance.model,
      'metadata': instance.metadata,
      'created_at': ChatMessageModel._dateTimeToJson(instance.createdAt),
      'sync_status': instance.syncStatus,
    };

ChatSessionModel _$ChatSessionModelFromJson(Map<String, dynamic> json) =>
    ChatSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      createdAt: ChatSessionModel._dateTimeFromJson(json['created_at']),
      updatedAt: ChatSessionModel._dateTimeFromJson(json['updated_at']),
    );

Map<String, dynamic> _$ChatSessionModelToJson(ChatSessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'created_at': ChatSessionModel._dateTimeToJson(instance.createdAt),
      'updated_at': ChatSessionModel._dateTimeToJson(instance.updatedAt),
    };
