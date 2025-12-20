import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/budget.dart';

part 'budget_model.g.dart';

/// Data model for Budget entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class BudgetModel {
  /// Unique identifier
  final String id;

  /// Account this budget applies to (null for all accounts)
  @JsonKey(name: 'account_id')
  final String? accountId;

  /// Category this budget tracks
  @JsonKey(name: 'category_id')
  final String categoryId;

  /// Budget limit amount
  final double amount;

  /// Amount spent so far in current period
  @JsonKey(name: 'spent_amount')
  final double spentAmount;

  /// Budget period type
  final String period;

  /// Start date of current budget period
  @JsonKey(name: 'start_date', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime startDate;

  /// End date of current budget period
  @JsonKey(name: 'end_date', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime endDate;

  /// Whether to roll over unused amount
  final bool rollover;

  /// Whether budget alerts are enabled
  @JsonKey(name: 'alerts_enabled')
  final bool alertsEnabled;

  /// Custom alert threshold (0.0 - 1.0)
  @JsonKey(name: 'alert_threshold')
  final double alertThreshold;

  /// When the budget was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the budget was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const BudgetModel({
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
  });

  /// Create from JSON
  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$BudgetModelToJson(this);

  /// Convert to domain entity
  Budget toEntity() => Budget(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        amount: amount,
        spentAmount: spentAmount,
        period: BudgetPeriodExtension.fromString(period),
        startDate: startDate,
        endDate: endDate,
        rollover: rollover,
        alertsEnabled: alertsEnabled,
        alertThreshold: alertThreshold,
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory BudgetModel.fromEntity(Budget entity) => BudgetModel(
        id: entity.id,
        accountId: entity.accountId,
        categoryId: entity.categoryId,
        amount: entity.amount,
        spentAmount: entity.spentAmount,
        period: entity.period.value,
        startDate: entity.startDate,
        endDate: entity.endDate,
        rollover: entity.rollover,
        alertsEnabled: entity.alertsEnabled,
        alertThreshold: entity.alertThreshold,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory BudgetModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return BudgetModel.fromJson({
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
}
