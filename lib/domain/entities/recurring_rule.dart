import 'package:equatable/equatable.dart';

/// Represents a recurring transaction rule in the domain layer.
///
/// Defines rules for automatically creating transactions on a schedule.
class RecurringRule extends Equatable {
  /// Unique identifier
  final String id;

  /// Template transaction ID
  final String transactionId;

  /// How often the transaction recurs
  final RecurringFrequency frequency;

  /// Interval between occurrences (e.g., every 2 weeks)
  final int interval;

  /// Next scheduled date
  final DateTime nextDate;

  /// End date for the recurrence (null for indefinite)
  final DateTime? endDate;

  /// Whether the rule is active
  final bool isActive;

  /// Number of occurrences completed
  final int occurrenceCount;

  /// Maximum number of occurrences (null for unlimited)
  final int? maxOccurrences;

  /// When the rule was created
  final DateTime createdAt;

  /// When the rule was last updated
  final DateTime updatedAt;

  /// Sync status with remote
  final String syncStatus;

  const RecurringRule({
    required this.id,
    required this.transactionId,
    required this.frequency,
    this.interval = 1,
    required this.nextDate,
    this.endDate,
    this.isActive = true,
    this.occurrenceCount = 0,
    this.maxOccurrences,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  /// Creates a copy with modified fields
  RecurringRule copyWith({
    String? id,
    String? transactionId,
    RecurringFrequency? frequency,
    int? interval,
    DateTime? nextDate,
    DateTime? endDate,
    bool? isActive,
    int? occurrenceCount,
    int? maxOccurrences,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      nextDate: nextDate ?? this.nextDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Whether the rule has reached its end
  bool get isComplete {
    if (maxOccurrences != null && occurrenceCount >= maxOccurrences!) {
      return true;
    }
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return true;
    }
    return false;
  }

  /// Whether the next occurrence is due
  bool get isDue {
    return isActive && !isComplete && DateTime.now().isAfter(nextDate);
  }

  /// Days until next occurrence
  int get daysUntilNext {
    final now = DateTime.now();
    if (now.isAfter(nextDate)) return 0;
    return nextDate.difference(now).inDays;
  }

  /// Calculate the next date after processing current occurrence
  DateTime calculateNextDate() {
    return frequency.getNextDate(nextDate, interval);
  }

  /// Human-readable frequency description
  String get frequencyDescription {
    if (interval == 1) {
      return frequency.displayName;
    }
    return 'Every $interval ${frequency.unit}s';
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        frequency,
        interval,
        nextDate,
        endDate,
        isActive,
        occurrenceCount,
        maxOccurrences,
        createdAt,
        updatedAt,
        syncStatus,
      ];
}

/// Recurring frequency types
enum RecurringFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

/// Extension for RecurringFrequency utilities
extension RecurringFrequencyExtension on RecurringFrequency {
  String get value {
    switch (this) {
      case RecurringFrequency.daily:
        return 'daily';
      case RecurringFrequency.weekly:
        return 'weekly';
      case RecurringFrequency.biweekly:
        return 'biweekly';
      case RecurringFrequency.monthly:
        return 'monthly';
      case RecurringFrequency.quarterly:
        return 'quarterly';
      case RecurringFrequency.yearly:
        return 'yearly';
    }
  }

  static RecurringFrequency fromString(String value) {
    switch (value) {
      case 'daily':
        return RecurringFrequency.daily;
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'biweekly':
        return RecurringFrequency.biweekly;
      case 'monthly':
        return RecurringFrequency.monthly;
      case 'quarterly':
        return RecurringFrequency.quarterly;
      case 'yearly':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.monthly;
    }
  }

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.biweekly:
        return 'Bi-weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.quarterly:
        return 'Quarterly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  String get unit {
    switch (this) {
      case RecurringFrequency.daily:
        return 'day';
      case RecurringFrequency.weekly:
        return 'week';
      case RecurringFrequency.biweekly:
        return 'week';
      case RecurringFrequency.monthly:
        return 'month';
      case RecurringFrequency.quarterly:
        return 'quarter';
      case RecurringFrequency.yearly:
        return 'year';
    }
  }

  /// Calculate next date from current date
  DateTime getNextDate(DateTime current, int interval) {
    switch (this) {
      case RecurringFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurringFrequency.biweekly:
        return current.add(Duration(days: 14 * interval));
      case RecurringFrequency.monthly:
        return DateTime(
          current.year,
          current.month + interval,
          current.day,
        );
      case RecurringFrequency.quarterly:
        return DateTime(
          current.year,
          current.month + (3 * interval),
          current.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(
          current.year + interval,
          current.month,
          current.day,
        );
    }
  }
}
