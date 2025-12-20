/// Barrel export for all use cases in the domain layer.
///
/// Import this file to access all use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/usecases.dart';
/// ```
///
/// ## Use Case Categories
///
/// ### Transaction Use Cases
/// - [GetTransactionsByDateRangeUseCase] - Fetch transactions within a date range
/// - [CreateTransactionUseCase] - Create a new transaction
/// - [GetSpendingSummaryUseCase] - Get aggregated spending data
/// - [WatchRecentTransactionsUseCase] - Stream of recent transactions
///
/// ## Adding New Use Cases
///
/// 1. Create a new file in the appropriate feature folder (e.g., `transaction/`)
/// 2. Extend [UseCase] or [StreamUseCase] base class
/// 3. Create a params class extending [Equatable]
/// 4. Export from the feature barrel file (e.g., `transaction_usecases.dart`)
/// 5. Export from this main barrel file
///
/// ## Example Structure
/// ```
/// usecases/
/// ├── usecase.dart              # Base classes
/// ├── usecases.dart             # This barrel file
/// ├── transaction/
/// │   ├── transaction_usecases.dart
/// │   ├── create_transaction.dart
/// │   └── get_transactions_by_date_range.dart
/// ├── account/
/// │   ├── account_usecases.dart
/// │   ├── create_account.dart
/// │   └── get_account_balance.dart
/// └── budget/
///     ├── budget_usecases.dart
///     └── check_budget_status.dart
/// ```
library;

// Base classes
export 'usecase.dart';

// Feature use cases
export 'account/account_usecases.dart';
export 'auth/auth_usecases.dart';
export 'budget/budget_usecases.dart';
export 'category/category_usecases.dart';
export 'chat/chat_usecases.dart';
export 'receipt/receipt_usecases.dart';
export 'transaction/transaction_usecases.dart';
export 'user/user_usecases.dart';
