import 'package:equatable/equatable.dart';

/// Represents a financial account in the domain layer.
///
/// An account can be a bank account, cash, credit card, e-wallet, etc.
/// Used to track balances and organize transactions.
class Account extends Equatable {
  /// Unique identifier
  final String id;

  /// Owner user ID
  final String userId;

  /// Account display name (e.g., "Main Checking", "Cash Wallet")
  final String name;

  /// Type of account
  final AccountType type;

  /// Current balance
  final double balance;

  /// Currency code (e.g., 'USD', 'EUR')
  final String currency;

  /// Icon name for display
  final String icon;

  /// Color hex value for display
  final int color;

  /// Whether the account is active
  final bool isActive;

  /// When the account was created
  final DateTime createdAt;

  /// When the account was last updated
  final DateTime updatedAt;

  /// Sync status with remote
  final String syncStatus;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'USD',
    this.icon = 'account_balance_wallet',
    this.color = 0xFF2E7D6F,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  /// Creates a copy with modified fields
  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    String? icon,
    int? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Get formatted balance with currency symbol
  String get formattedBalance {
    final symbol = _getCurrencySymbol(currency);
    final isNegative = balance < 0;
    final absBalance = balance.abs();
    return '${isNegative ? '-' : ''}$symbol${absBalance.toStringAsFixed(2)}';
  }

  /// Whether this is a liability account (balance reduces net worth)
  bool get isLiability => type == AccountType.creditCard || type == AccountType.loan;

  /// Get currency symbol from code
  String _getCurrencySymbol(String code) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'BRL': 'R\$',
      'MXN': '\$',
    };
    return symbols[code] ?? code;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        balance,
        currency,
        icon,
        color,
        isActive,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}

/// Types of financial accounts
enum AccountType {
  cash,
  bankAccount,
  creditCard,
  debitCard,
  savings,
  investment,
  loan,
  eWallet,
}

/// Extension to convert AccountType to/from string
extension AccountTypeExtension on AccountType {
  String get value {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bankAccount:
        return 'bank_account';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.debitCard:
        return 'debit_card';
      case AccountType.savings:
        return 'savings';
      case AccountType.investment:
        return 'investment';
      case AccountType.loan:
        return 'loan';
      case AccountType.eWallet:
        return 'e_wallet';
    }
  }

  static AccountType fromString(String value) {
    switch (value) {
      case 'cash':
        return AccountType.cash;
      case 'bank_account':
        return AccountType.bankAccount;
      case 'credit_card':
        return AccountType.creditCard;
      case 'debit_card':
        return AccountType.debitCard;
      case 'savings':
        return AccountType.savings;
      case 'investment':
        return AccountType.investment;
      case 'loan':
        return AccountType.loan;
      case 'e_wallet':
        return AccountType.eWallet;
      default:
        return AccountType.bankAccount;
    }
  }

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bankAccount:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.debitCard:
        return 'Debit Card';
      case AccountType.savings:
        return 'Savings';
      case AccountType.investment:
        return 'Investment';
      case AccountType.loan:
        return 'Loan';
      case AccountType.eWallet:
        return 'E-Wallet';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return 'payments';
      case AccountType.bankAccount:
        return 'account_balance';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.debitCard:
        return 'credit_card';
      case AccountType.savings:
        return 'savings';
      case AccountType.investment:
        return 'trending_up';
      case AccountType.loan:
        return 'money_off';
      case AccountType.eWallet:
        return 'account_balance_wallet';
    }
  }
}
