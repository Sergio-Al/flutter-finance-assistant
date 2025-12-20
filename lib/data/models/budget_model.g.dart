// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BudgetModel _$BudgetModelFromJson(Map<String, dynamic> json) => BudgetModel(
  id: json['id'] as String,
  accountId: json['account_id'] as String?,
  categoryId: json['category_id'] as String,
  amount: (json['amount'] as num).toDouble(),
  spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
  period: json['period'] as String,
  startDate: BudgetModel._dateTimeFromJson(json['start_date']),
  endDate: BudgetModel._dateTimeFromJson(json['end_date']),
  rollover: json['rollover'] as bool? ?? false,
  alertsEnabled: json['alerts_enabled'] as bool? ?? true,
  alertThreshold: (json['alert_threshold'] as num?)?.toDouble() ?? 0.80,
  createdAt: BudgetModel._dateTimeFromJson(json['created_at']),
  updatedAt: BudgetModel._dateTimeFromJson(json['updated_at']),
  syncStatus: json['sync_status'] as String? ?? 'pending',
);

Map<String, dynamic> _$BudgetModelToJson(BudgetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'category_id': instance.categoryId,
      'amount': instance.amount,
      'spent_amount': instance.spentAmount,
      'period': instance.period,
      'start_date': BudgetModel._dateTimeToJson(instance.startDate),
      'end_date': BudgetModel._dateTimeToJson(instance.endDate),
      'rollover': instance.rollover,
      'alerts_enabled': instance.alertsEnabled,
      'alert_threshold': instance.alertThreshold,
      'created_at': BudgetModel._dateTimeToJson(instance.createdAt),
      'updated_at': BudgetModel._dateTimeToJson(instance.updatedAt),
      'sync_status': instance.syncStatus,
    };
