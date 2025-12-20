import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/domain/entities/category.dart';

/// Represents a budget in the domain layer.
///
/// A budget sets spending limits for a category over a time period.
/// Tracks spent amount for progress monitoring and alerts.
class Budget extends Equatable {
  /// Unique identifier
  final String id;

  /// Account this budget applies to (null for all accounts)
  final String? accountId;

  /// Category this budget tracks
  final String categoryId;

  /// Budget limit amount
  final double amount;

  /// Amount spent so far in current period
  final double spentAmount;

  /// Budget period type
  final BudgetPeriod period;

  /// Start date of current budget period
  final DateTime startDate;

  /// End date of current budget period
  final DateTime endDate;

  /// Whether to roll over unused amount
  final bool rollover;

  /// Whether budget alerts are enabled
  final bool alertsEnabled;

  /// Custom alert threshold (0.0 - 1.0)
  final double alertThreshold;

  /// When the budget was created
  final DateTime createdAt;

  /// When the budget was last updated
  final DateTime updatedAt;

  /// Sync status with remote
  final String syncStatus;

  // Optional expanded relations
  final Category? category;

  const Budget({
    required this.id,
    this.accountId,
    required this.categoryId,
    required this.amount,
    this.spentAmount = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.rollover = false,
    this.alertsEnabled = true,
    this.alertThreshold = 0.80,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.category,
  });

  /// Creates a copy with modified fields
  Budget copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    double? spentAmount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? rollover,
    bool? alertsEnabled,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    Category? category,
  }) {
    return Budget(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spentAmount: spentAmount ?? this.spentAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rollover: rollover ?? this.rollover,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      category: category ?? this.category,
    );
  }

  /// Remaining budget amount
  double get remainingAmount => amount - spentAmount;

  /// Progress as percentage (0.0 - 1.0+)
  double get progress => amount > 0 ? spentAmount / amount : 0.0;

  /// Progress as percentage capped at 100%
  double get progressCapped => progress.clamp(0.0, 1.0);

  /// Progress as percentage (0 - 100+)
  int get progressPercent => (progress * 100).round();

  /// Whether budget is exceeded
  bool get isExceeded => spentAmount > amount;

  /// Whether budget is at warning level (default 80%)
  bool get isWarning => progress >= alertThreshold && !isExceeded;

  /// Whether budget is at danger level (95%+)
  bool get isDanger => progress >= 0.95 && !isExceeded;

  /// Budget status for display
  BudgetStatus get status {
    if (isExceeded) return BudgetStatus.exceeded;
    if (isDanger) return BudgetStatus.danger;
    if (isWarning) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  /// Days remaining in current period
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Daily budget remaining (for pacing)
  double get dailyBudgetRemaining {
    if (daysRemaining <= 0) return 0;
    return remainingAmount / daysRemaining;
  }

  /// Whether budget period is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        categoryId,
        amount,
        spentAmount,
        period,
        startDate,
        endDate,
        rollover,
        alertsEnabled,
        alertThreshold,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}

/// Budget time periods
enum BudgetPeriod {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

/// Extension for BudgetPeriod utilities
extension BudgetPeriodExtension on BudgetPeriod {
  String get value {
    switch (this) {
      case BudgetPeriod.daily:
        return 'daily';
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.biweekly:
        return 'biweekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.quarterly:
        return 'quarterly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  static BudgetPeriod fromString(String value) {
    switch (value) {
      case 'daily':
        return BudgetPeriod.daily;
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'biweekly':
        return BudgetPeriod.biweekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'quarterly':
        return BudgetPeriod.quarterly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  String get displayName {
    switch (this) {
      case BudgetPeriod.daily:
        return 'Daily';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.biweekly:
        return 'Bi-weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  /// Calculate end date from start date
  DateTime getEndDate(DateTime startDate) {
    switch (this) {
      case BudgetPeriod.daily:
        return startDate.add(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7));
      case BudgetPeriod.biweekly:
        return startDate.add(const Duration(days: 14));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case BudgetPeriod.quarterly:
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }
}

/// Budget status for UI display
enum BudgetStatus {
  safe,
  warning,
  danger,
  exceeded,
}

/// Extension for BudgetStatus utilities
extension BudgetStatusExtension on BudgetStatus {
  String get displayName {
    switch (this) {
      case BudgetStatus.safe:
        return 'On Track';
      case BudgetStatus.warning:
        return 'Warning';
      case BudgetStatus.danger:
        return 'Critical';
      case BudgetStatus.exceeded:
        return 'Exceeded';
    }
  }

  /// Color for this status
  int get color {
    switch (this) {
      case BudgetStatus.safe:
        return 0xFF52B788; // Green
      case BudgetStatus.warning:
        return 0xFFFFC107; // Amber
      case BudgetStatus.danger:
        return 0xFFFF9800; // Orange
      case BudgetStatus.exceeded:
        return 0xFFE53935; // Red
    }
  }
}
