import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/chat_message.dart';

part 'chat_message_model.g.dart';

/// Data model for ChatMessage entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class ChatMessageModel {
  /// Unique identifier
  final String id;

  /// User ID who owns this chat
  @JsonKey(name: 'user_id')
  final String userId;

  /// Session ID for grouping conversations
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// Role of the message sender
  final String role;

  /// Message content
  final String content;

  /// Tokens used for this message (for AI messages)
  @JsonKey(name: 'tokens_used')
  final int? tokensUsed;

  /// AI model used (for AI messages)
  final String? model;

  /// Metadata (e.g., function calls, tool responses)
  final Map<String, dynamic>? metadata;

  /// When the message was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const ChatMessageModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.content,
    this.tokensUsed,
    this.model,
    this.metadata,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  /// Create from JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  /// Convert to domain entity
  ChatMessage toEntity() => ChatMessage(
        id: id,
        userId: userId,
        sessionId: sessionId,
        role: ChatRoleExtension.fromString(role),
        content: content,
        tokensUsed: tokensUsed,
        model: model,
        metadata: metadata,
        createdAt: createdAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory ChatMessageModel.fromEntity(ChatMessage entity) => ChatMessageModel(
        id: entity.id,
        userId: entity.userId,
        sessionId: entity.sessionId,
        role: entity.role.value,
        content: entity.content,
        tokensUsed: entity.tokensUsed,
        model: entity.model,
        metadata: entity.metadata,
        createdAt: entity.createdAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory ChatMessageModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ChatMessageModel.fromJson({
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

/// Data model for ChatSession.
@JsonSerializable()
class ChatSessionModel {
  /// Unique session identifier
  final String id;

  /// User ID who owns this session
  @JsonKey(name: 'user_id')
  final String userId;

  /// Session title (auto-generated or user-defined)
  final String? title;

  /// When the session was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the session was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const ChatSessionModel({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from JSON
  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ChatSessionModelToJson(this);

  /// Convert to domain entity
  ChatSession toEntity({List<ChatMessage> messages = const []}) => ChatSession(
        id: id,
        userId: userId,
        title: title,
        messages: messages,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Create from domain entity
  factory ChatSessionModel.fromEntity(ChatSession entity) => ChatSessionModel(
        id: entity.id,
        userId: entity.userId,
        title: entity.title,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  /// Create from Firestore document
  factory ChatSessionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ChatSessionModel.fromJson({
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

  // DateTime JSON converters (duplicated for self-containment)
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
