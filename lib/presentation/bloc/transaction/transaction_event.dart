import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/transaction.dart';

/// Base class for all transaction events.
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════════════════
// LOAD EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to load transactions for a specific date range.
class TransactionLoadRequested extends TransactionEvent {
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const TransactionLoadRequested({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [accountId, startDate, endDate];
}

/// Event to load recent transactions.
class TransactionLoadRecentRequested extends TransactionEvent {
  final String accountId;
  final int limit;

  const TransactionLoadRecentRequested({
    required this.accountId,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [accountId, limit];
}

/// Event to load spending summary.
class TransactionSummaryRequested extends TransactionEvent {
  final String accountId;
  final DateTime startDate;
  final DateTime endDate;

  const TransactionSummaryRequested({
    required this.accountId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [accountId, startDate, endDate];
}

/// Event to start watching recent transactions in real-time.
class TransactionWatchRequested extends TransactionEvent {
  final String accountId;
  final int limit;

  const TransactionWatchRequested({required this.accountId, this.limit = 10});

  @override
  List<Object?> get props => [accountId, limit];
}

// ═══════════════════════════════════════════════════════════════════════════
// CRUD EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to create a new transaction.
class TransactionCreateRequested extends TransactionEvent {
  final String accountId;
  final String categoryId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final String? receiptUrl;
  final String? location;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringId;
  final String? toAccountId;

  const TransactionCreateRequested({
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.receiptUrl,
    this.location,
    this.tags = const [],
    this.isRecurring = false,
    this.recurringId,
    this.toAccountId,
  });

  @override
  List<Object?> get props => [
    accountId,
    categoryId,
    amount,
    type,
    description,
    date,
    receiptUrl,
    location,
    tags,
    isRecurring,
    recurringId,
    toAccountId,
  ];
}

/// Event to update an existing transaction.
class TransactionUpdateRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionUpdateRequested({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a transaction.
class TransactionDeleteRequested extends TransactionEvent {
  final String transactionId;

  const TransactionDeleteRequested({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to filter transactions by type.
class TransactionFilterByTypeRequested extends TransactionEvent {
  final TransactionType? type;

  const TransactionFilterByTypeRequested({this.type});

  @override
  List<Object?> get props => [type];
}

/// Event to filter transactions by category.
class TransactionFilterByCategoryRequested extends TransactionEvent {
  final String? categoryId;

  const TransactionFilterByCategoryRequested({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Event to filter transactions by date range.
class TransactionFilterByDateRequested extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;

  const TransactionFilterByDateRequested({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to clear all filters.
class TransactionFilterCleared extends TransactionEvent {
  const TransactionFilterCleared();
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Event to search transactions by description or tags.
class TransactionSearchRequested extends TransactionEvent {
  final String query;

  const TransactionSearchRequested({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to clear search.
class TransactionSearchCleared extends TransactionEvent {
  const TransactionSearchCleared();
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERNAL EVENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Internal event when transactions change from stream.
class TransactionDataChanged extends TransactionEvent {
  final List<Transaction> transactions;

  const TransactionDataChanged({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

/// Event to clear any error state.
class TransactionErrorCleared extends TransactionEvent {
  const TransactionErrorCleared();
}
