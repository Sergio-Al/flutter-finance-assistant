/// Domain entities for the Finance Assistant app.
///
/// These are pure Dart classes representing business objects.
/// They have no external dependencies and can be used across all layers.
///
/// Available entities:
/// - [User] - User profile and preferences
/// - [Account] - Financial accounts (bank, cash, cards, etc.)
/// - [Category] - Transaction categories
/// - [Transaction] - Financial transactions
/// - [Budget] - Budget limits and tracking
/// - [RecurringRule] - Recurring transaction rules
/// - [Receipt] - OCR-scanned receipts
/// - [ChatMessage] - AI chat messages
/// - [ChatSession] - AI chat sessions
library;

export 'account.dart';
export 'budget.dart';
export 'category.dart';
export 'chat_message.dart';
export 'receipt.dart';
export 'recurring_rule.dart';
export 'transaction.dart';
export 'user.dart';
