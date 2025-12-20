import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/account.dart';

/// Repository interface for account operations.
///
/// Defines the contract for financial account data access.
/// Implementation will be in the data layer.
abstract class AccountRepository {
  /// Get all accounts for a user.
  Future<Either<Failure, List<Account>>> getAccounts(String userId);

  /// Get active accounts only.
  Future<Either<Failure, List<Account>>> getActiveAccounts(String userId);

  /// Get account by ID.
  Future<Either<Failure, Account>> getAccountById(String accountId);

  /// Get accounts by type.
  Future<Either<Failure, List<Account>>> getAccountsByType(
    String userId,
    AccountType type,
  );

  /// Create a new account.
  Future<Either<Failure, Account>> createAccount(Account account);

  /// Update an existing account.
  Future<Either<Failure, Account>> updateAccount(Account account);

  /// Delete an account (soft delete - marks as inactive).
  Future<Either<Failure, void>> deleteAccount(String accountId);

  /// Permanently delete an account and all transactions.
  Future<Either<Failure, void>> permanentlyDeleteAccount(String accountId);

  /// Update account balance.
  Future<Either<Failure, Account>> updateBalance(
    String accountId,
    double newBalance,
  );

  /// Adjust account balance by amount (add/subtract).
  Future<Either<Failure, Account>> adjustBalance(
    String accountId,
    double amount,
  );

  /// Get total balance across all accounts.
  Future<Either<Failure, double>> getTotalBalance(String userId);

  /// Get total balance by account type.
  Future<Either<Failure, double>> getTotalBalanceByType(
    String userId,
    AccountType type,
  );

  /// Get net worth (assets - liabilities).
  Future<Either<Failure, double>> getNetWorth(String userId);

  /// Stream of accounts for real-time updates.
  Stream<Either<Failure, List<Account>>> watchAccounts(String userId);

  /// Stream of single account changes.
  Stream<Either<Failure, Account>> watchAccount(String accountId);
}
