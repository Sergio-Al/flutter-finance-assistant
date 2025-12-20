import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/usecases/transaction/get_spending_summary.dart';

/// Base class for all transaction states.
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// BASIC STATES
// ═══════════════════════════════════════════════════════════════════════════

/// Initial state before any action.
class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// Loading state while fetching transactions.
class TransactionLoading extends TransactionState {
  final String? message;

  const TransactionLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADED STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when transactions are loaded successfully.
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final SpendingSummary? summary;
  final TransactionFilter? activeFilter;
  final String? searchQuery;
  final DateTime lastUpdated;

  const TransactionLoaded({
    required this.transactions,
    this.summary,
    this.activeFilter,
    this.searchQuery,
    required this.lastUpdated,
  });

  /// Get transactions filtered by type
  List<Transaction> get expenses =>
      transactions.where((t) => t.type == TransactionType.expense).toList();

  List<Transaction> get incomes =>
      transactions.where((t) => t.type == TransactionType.income).toList();

  List<Transaction> get transfers =>
      transactions.where((t) => t.type == TransactionType.transfer).toList();

  /// Get total amounts
  double get totalExpenses => expenses.fold(0.0, (sum, t) => sum + t.amount);

  double get totalIncome => incomes.fold(0.0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome - totalExpenses;

  /// Check if any filters are active
  bool get hasActiveFilters => activeFilter != null || searchQuery != null;

  /// Get filtered transactions based on active filter
  List<Transaction> get filteredTransactions {
    var result = transactions;

    if (activeFilter != null) {
      if (activeFilter!.type != null) {
        result = result.where((t) => t.type == activeFilter!.type).toList();
      }
      if (activeFilter!.categoryId != null) {
        result = result
            .where((t) => t.categoryId == activeFilter!.categoryId)
            .toList();
      }
    }

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((t) {
        final descriptionMatch =
            t.description?.toLowerCase().contains(query) ?? false;
        final tagMatch = t.tags.any((tag) => tag.toLowerCase().contains(query));
        final locationMatch =
            t.location?.toLowerCase().contains(query) ?? false;
        return descriptionMatch || tagMatch || locationMatch;
      }).toList();
    }

    return result;
  }

  /// Create a copy with updated fields
  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    SpendingSummary? summary,
    TransactionFilter? activeFilter,
    String? searchQuery,
    DateTime? lastUpdated,
    bool clearFilter = false,
    bool clearSearch = false,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    summary,
    activeFilter,
    searchQuery,
    lastUpdated,
  ];
}

/// State when recent transactions are loaded (for dashboard widgets).
class TransactionRecentLoaded extends TransactionState {
  final List<Transaction> recentTransactions;
  final DateTime lastUpdated;

  const TransactionRecentLoaded({
    required this.recentTransactions,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [recentTransactions, lastUpdated];
}

/// State when a single transaction is loaded (for detail view).
class TransactionDetailLoaded extends TransactionState {
  final Transaction transaction;

  const TransactionDetailLoaded({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

// ═══════════════════════════════════════════════════════════════════════════
// OPERATION STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when a transaction is being created/updated/deleted.
class TransactionOperationInProgress extends TransactionState {
  final TransactionOperationType operation;
  final String? transactionId;

  const TransactionOperationInProgress({
    required this.operation,
    this.transactionId,
  });

  @override
  List<Object?> get props => [operation, transactionId];
}

/// State when a transaction operation succeeds.
class TransactionOperationSuccess extends TransactionState {
  final TransactionOperationType operation;
  final Transaction? transaction;
  final String message;

  const TransactionOperationSuccess({
    required this.operation,
    this.transaction,
    required this.message,
  });

  @override
  List<Object?> get props => [operation, transaction, message];
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR STATES
// ═══════════════════════════════════════════════════════════════════════════

/// State when an error occurs.
class TransactionError extends TransactionState {
  final TransactionErrorType errorType;
  final String message;
  final String? code;

  const TransactionError({
    required this.errorType,
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [errorType, message, code];
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Filter criteria for transactions.
class TransactionFilter extends Equatable {
  final TransactionType? type;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.type,
    this.categoryId,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [type, categoryId, startDate, endDate];
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

/// Types of transaction operations.
enum TransactionOperationType { create, update, delete, duplicate }

/// Types of transaction errors.
enum TransactionErrorType {
  loadFailed,
  createFailed,
  updateFailed,
  deleteFailed,
  validationError,
  invalidAmount,
  missingCategory,
  missingAccount,
  transactionNotFound,
  networkError,
  unknown,
}

/// Extension for user-friendly error messages.
extension TransactionErrorTypeExtension on TransactionErrorType {
  String get defaultMessage {
    switch (this) {
      case TransactionErrorType.loadFailed:
        return 'Failed to load transactions. Please try again.';
      case TransactionErrorType.createFailed:
        return 'Failed to create transaction. Please try again.';
      case TransactionErrorType.updateFailed:
        return 'Failed to update transaction. Please try again.';
      case TransactionErrorType.deleteFailed:
        return 'Failed to delete transaction. Please try again.';
      case TransactionErrorType.validationError:
        return 'Please check your input and try again.';
      case TransactionErrorType.invalidAmount:
        return 'Amount must be greater than zero.';
      case TransactionErrorType.missingCategory:
        return 'Please select a category.';
      case TransactionErrorType.missingAccount:
        return 'Please select an account.';
      case TransactionErrorType.transactionNotFound:
        return 'Transaction not found.';
      case TransactionErrorType.networkError:
        return 'Network error. Please check your connection.';
      case TransactionErrorType.unknown:
        return 'An unexpected error occurred.';
    }
  }
}

/// Extension for operation success messages.
extension TransactionOperationTypeExtension on TransactionOperationType {
  String get successMessage {
    switch (this) {
      case TransactionOperationType.create:
        return 'Transaction created successfully!';
      case TransactionOperationType.update:
        return 'Transaction updated successfully!';
      case TransactionOperationType.delete:
        return 'Transaction deleted successfully!';
      case TransactionOperationType.duplicate:
        return 'Transaction duplicated successfully!';
    }
  }
}
