/// Barrel export for all account-related use cases.
///
/// Import this file to access all account use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/account/account_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### CRUD Operations
/// - [CreateAccountUseCase] - Create a new account
/// - [UpdateAccountUseCase] - Update account details
/// - [DeleteAccountUseCase] - Soft delete an account
/// - [PermanentlyDeleteAccountUseCase] - Hard delete with all transactions
///
/// ### Query Operations
/// - [GetAccountsUseCase] - Get all accounts
/// - [GetActiveAccountsUseCase] - Get only active accounts
/// - [GetAccountsByTypeUseCase] - Get accounts filtered by type
///
/// ### Balance Operations
/// - [UpdateAccountBalanceUseCase] - Set account balance
/// - [AdjustAccountBalanceUseCase] - Add/subtract from balance
///
/// ### Aggregations
/// - [GetNetWorthUseCase] - Calculate net worth and financial summary
///
/// ### Real-time Streams
/// - [WatchAccountsUseCase] - Stream of all accounts
/// - [WatchAccountUseCase] - Stream of single account
library;

export 'create_account.dart';
export 'delete_account.dart';
export 'get_accounts.dart';
export 'get_net_worth.dart';
export 'update_account_balance.dart';
export 'watch_accounts.dart';
