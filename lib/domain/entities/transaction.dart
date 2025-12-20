import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/account.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';

/// Represents a financial transaction in the domain layer.
///
/// A transaction records money movement: expense, income, or transfer.
/// Supports AI-powered categorization and receipt attachments.
class Transaction extends Equatable {
  /// Unique identifier
  final String id;

  /// Account this transaction belongs to
  final String accountId;

  /// Category for this transaction
  final String categoryId;

  /// Transaction amount (always positive, type determines direction)
  final double amount;

  /// Type of transaction
  final TransactionType type;

  /// Description or note
  final String? description;

  /// Date of the transaction
  final DateTime date;

  /// URL to receipt image (if attached)
  final String? receiptUrl;

  /// Location where transaction occurred
  final String? location;

  /// Tags for filtering/search
  final List<String> tags;

  /// AI categorization confidence (0.0 - 1.0)
  final double? aiCategoryConfidence;

  /// Whether this is a recurring transaction
  final bool isRecurring;

  /// ID of the recurring rule (if recurring)
  final String? recurringId;

  /// Target account for transfers
  final String? toAccountId;

  /// When the transaction was created
  final DateTime createdAt;

  /// When the transaction was last updated
  final DateTime updatedAt;

  /// Sync status with remote
  final String syncStatus;

  // Optional expanded relations (populated when needed)
  final Account? account;
  final Category? category;
  final Account? toAccount;

  const Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.receiptUrl,
    this.location,
    this.tags = const [],
    this.aiCategoryConfidence,
    this.isRecurring = false,
    this.recurringId,
    this.toAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.account,
    this.category,
    this.toAccount,
  });

  /// Creates a copy with modified fields
  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? date,
    String? receiptUrl,
    String? location,
    List<String>? tags,
    double? aiCategoryConfidence,
    bool? isRecurring,
    String? recurringId,
    String? toAccountId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Account? account,
    Category? category,
    Account? toAccount,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      aiCategoryConfidence: aiCategoryConfidence ?? this.aiCategoryConfidence,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      toAccountId: toAccountId ?? this.toAccountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      account: account ?? this.account,
      category: category ?? this.category,
      toAccount: toAccount ?? this.toAccount,
    );
  }

  /// Whether this transaction has a receipt attached
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  /// Whether the AI categorization is high confidence
  bool get isHighConfidence => 
      aiCategoryConfidence != null && aiCategoryConfidence! >= 0.85;

  /// Whether the AI categorization is medium confidence
  bool get isMediumConfidence =>
      aiCategoryConfidence != null && 
      aiCategoryConfidence! >= 0.60 && 
      aiCategoryConfidence! < 0.85;

  /// Whether the AI categorization is low confidence
  bool get isLowConfidence =>
      aiCategoryConfidence != null && aiCategoryConfidence! < 0.60;

  /// Get signed amount (negative for expenses)
  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
        return amount;
      case TransactionType.transfer:
        return -amount; // Deducted from source account
    }
  }

  /// Whether this is a transfer between accounts
  bool get isTransfer => type == TransactionType.transfer;

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        amount,
        type,
        description,
        date,
        receiptUrl,
        location,
        tags,
        aiCategoryConfidence,
        isRecurring,
        recurringId,
        toAccountId,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}

/// Types of transactions
enum TransactionType {
  expense,
  income,
  transfer,
}

/// Extension for TransactionType utilities
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'expense':
        return TransactionType.expense;
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.expense:
        return 'arrow_downward';
      case TransactionType.income:
        return 'arrow_upward';
      case TransactionType.transfer:
        return 'swap_horiz';
    }
  }

  /// Color associated with this transaction type
  int get color {
    switch (this) {
      case TransactionType.expense:
        return 0xFFEF5350; // Red
      case TransactionType.income:
        return 0xFF52B788; // Green
      case TransactionType.transfer:
        return 0xFF42A5F5; // Blue
    }
  }
}
