import 'package:equatable/equatable.dart';

/// Represents a chat message in the domain layer.
///
/// Used for AI conversational interface history.
class ChatMessage extends Equatable {
  /// Unique identifier
  final String id;

  /// User ID who owns this chat
  final String userId;

  /// Session ID for grouping conversations
  final String sessionId;

  /// Role of the message sender
  final ChatRole role;

  /// Message content
  final String content;

  /// Tokens used for this message (for AI messages)
  final int? tokensUsed;

  /// AI model used (for AI messages)
  final String? model;

  /// Metadata (e.g., function calls, tool responses)
  final Map<String, dynamic>? metadata;

  /// When the message was created
  final DateTime createdAt;

  /// Sync status with remote
  final String syncStatus;

  const ChatMessage({
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

  /// Creates a copy with modified fields
  ChatMessage copyWith({
    String? id,
    String? userId,
    String? sessionId,
    ChatRole? role,
    String? content,
    int? tokensUsed,
    String? model,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      model: model ?? this.model,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Whether this is a user message
  bool get isUser => role == ChatRole.user;

  /// Whether this is an AI assistant message
  bool get isAssistant => role == ChatRole.assistant;

  /// Whether this is a system message
  bool get isSystem => role == ChatRole.system;

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionId,
        role,
        content,
        tokensUsed,
        model,
        metadata,
        createdAt,
        syncStatus,
      ];
}

/// Chat message roles
enum ChatRole {
  user,
  assistant,
  system,
}

/// Extension for ChatRole utilities
extension ChatRoleExtension on ChatRole {
  String get value {
    switch (this) {
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
      case ChatRole.system:
        return 'system';
    }
  }

  static ChatRole fromString(String value) {
    switch (value) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      case 'system':
        return ChatRole.system;
      default:
        return ChatRole.user;
    }
  }

  String get displayName {
    switch (this) {
      case ChatRole.user:
        return 'You';
      case ChatRole.assistant:
        return 'Assistant';
      case ChatRole.system:
        return 'System';
    }
  }
}

/// Represents a chat session
class ChatSession extends Equatable {
  /// Unique session identifier
  final String id;

  /// User ID who owns this session
  final String userId;

  /// Session title (auto-generated or user-defined)
  final String? title;

  /// Messages in this session
  final List<ChatMessage> messages;

  /// When the session was created
  final DateTime createdAt;

  /// When the session was last updated
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.userId,
    this.title,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy with modified fields
  ChatSession copyWith({
    String? id,
    String? userId,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total tokens used in this session
  int get totalTokensUsed {
    return messages.fold(0, (sum, msg) => sum + (msg.tokensUsed ?? 0));
  }

  /// Number of messages in session
  int get messageCount => messages.length;

  /// Last message in session
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Preview text for session list
  String get preview {
    if (messages.isEmpty) return 'No messages';
    final lastUserMessage = messages.lastWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );
    final content = lastUserMessage.content;
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        messages,
        createdAt,
        updatedAt,
      ];
}
