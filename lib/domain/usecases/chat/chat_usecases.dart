/// Barrel export for all chat-related use cases.
///
/// Import this file to access all chat use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/chat/chat_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### Session Management
/// - [CreateChatSessionUseCase] - Create a new chat session
/// - [GetChatSessionUseCase] - Get a session by ID
/// - [GetChatSessionsUseCase] - Get all sessions for a user
/// - [GetRecentSessionsUseCase] - Get recent sessions
/// - [UpdateChatSessionUseCase] - Update session details
/// - [DeleteChatSessionUseCase] - Delete a session
///
/// ### Message Management
/// - [GetMessagesUseCase] - Get all messages in a session
/// - [GetMessageByIdUseCase] - Get a specific message
/// - [AddMessageUseCase] - Add a message to a session
/// - [UpdateMessageUseCase] - Update a message
/// - [DeleteMessageUseCase] - Delete a message
/// - [GetRecentMessagesUseCase] - Get recent messages
///
/// ### AI Interaction
/// - [SendChatMessageUseCase] - Send message and get AI response
/// - [StreamChatResponseUseCase] - Stream AI response for real-time display
/// - [GetConversationContextUseCase] - Get context for AI
///
/// ### Search
/// - [SearchMessagesUseCase] - Search messages across sessions
///
/// ### Analytics
/// - [GetTotalTokensUsedUseCase] - Get total tokens used
/// - [GetTokensUsedInPeriodUseCase] - Get tokens used in period
/// - [GetMessageCountUseCase] - Get total message count
///
/// ### Cleanup
/// - [DeleteOldSessionsUseCase] - Delete sessions older than N days
/// - [ClearAllHistoryUseCase] - Clear all chat history
///
/// ### Real-time Streams
/// - [WatchSessionsUseCase] - Stream session changes
/// - [WatchMessagesUseCase] - Stream message changes
library;

export 'chat_analytics.dart';
export 'clear_chat_history.dart';
export 'manage_messages.dart';
export 'manage_sessions.dart';
export 'search_messages.dart';
export 'send_chat_message.dart';
export 'watch_chat.dart';
