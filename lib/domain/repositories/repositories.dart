/// Domain repository interfaces for the Finance Assistant app.
///
/// These abstract classes define the contract for data operations.
/// Implementations will be in the data layer, following Clean Architecture.
///
/// All methods return `Either<Failure, T>` for functional error handling.
///
/// Available repositories:
/// - [AuthRepository] - Authentication operations
/// - [UserRepository] - User profile operations
/// - [AccountRepository] - Financial account operations
/// - [CategoryRepository] - Category operations
/// - [TransactionRepository] - Transaction operations
/// - [BudgetRepository] - Budget operations
/// - [RecurringRuleRepository] - Recurring transaction rules
/// - [ReceiptRepository] - Receipt scanning and OCR
/// - [ChatRepository] - AI chat history
library;

export 'account_repository.dart';
export 'auth_repository.dart';
export 'budget_repository.dart';
export 'category_repository.dart';
export 'chat_repository.dart';
export 'receipt_repository.dart';
export 'recurring_rule_repository.dart';
export 'transaction_repository.dart';
export 'user_repository.dart';
