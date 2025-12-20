import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/recurring_rule.dart';

part 'recurring_rule_model.g.dart';

/// Data model for RecurringRule entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class RecurringRuleModel {
  /// Unique identifier
  final String id;

  /// Template transaction ID
  @JsonKey(name: 'transaction_id')
  final String transactionId;

  /// How often the transaction recurs
  final String frequency;

  /// Interval between occurrences
  final int interval;

  /// Next scheduled date
  @JsonKey(name: 'next_date', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime nextDate;

  /// End date for the recurrence
  @JsonKey(name: 'end_date', fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? endDate;

  /// Whether the rule is active
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// Number of occurrences completed
  @JsonKey(name: 'occurrence_count')
  final int occurrenceCount;

  /// Maximum number of occurrences
  @JsonKey(name: 'max_occurrences')
  final int? maxOccurrences;

  /// When the rule was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the rule was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const RecurringRuleModel({
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

  /// Create from JSON
  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) =>
      _$RecurringRuleModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RecurringRuleModelToJson(this);

  /// Convert to domain entity
  RecurringRule toEntity() => RecurringRule(
        id: id,
        transactionId: transactionId,
        frequency: RecurringFrequencyExtension.fromString(frequency),
        interval: interval,
        nextDate: nextDate,
        endDate: endDate,
        isActive: isActive,
        occurrenceCount: occurrenceCount,
        maxOccurrences: maxOccurrences,
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory RecurringRuleModel.fromEntity(RecurringRule entity) => RecurringRuleModel(
        id: entity.id,
        transactionId: entity.transactionId,
        frequency: entity.frequency.value,
        interval: entity.interval,
        nextDate: entity.nextDate,
        endDate: entity.endDate,
        isActive: entity.isActive,
        occurrenceCount: entity.occurrenceCount,
        maxOccurrences: entity.maxOccurrences,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory RecurringRuleModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return RecurringRuleModel.fromJson({
      'id': documentId,
      ...data,
    });
  }

  /// Convert to Firestore document (without id)
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  // DateTime JSON converters
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Firestore Timestamp
    if (value != null && value.runtimeType.toString().contains('Timestamp')) {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }

  static dynamic _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();

  static DateTime? _nullableDateTimeFromJson(dynamic value) {
    if (value == null) return null;
    return _dateTimeFromJson(value);
  }

  static dynamic _nullableDateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}
