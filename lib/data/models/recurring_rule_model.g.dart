// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRuleModel _$RecurringRuleModelFromJson(Map<String, dynamic> json) =>
    RecurringRuleModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      frequency: json['frequency'] as String,
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      nextDate: RecurringRuleModel._dateTimeFromJson(json['next_date']),
      endDate: RecurringRuleModel._nullableDateTimeFromJson(json['end_date']),
      isActive: json['is_active'] as bool? ?? true,
      occurrenceCount: (json['occurrence_count'] as num?)?.toInt() ?? 0,
      maxOccurrences: (json['max_occurrences'] as num?)?.toInt(),
      createdAt: RecurringRuleModel._dateTimeFromJson(json['created_at']),
      updatedAt: RecurringRuleModel._dateTimeFromJson(json['updated_at']),
      syncStatus: json['sync_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$RecurringRuleModelToJson(RecurringRuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transaction_id': instance.transactionId,
      'frequency': instance.frequency,
      'interval': instance.interval,
      'next_date': RecurringRuleModel._dateTimeToJson(instance.nextDate),
      'end_date': RecurringRuleModel._nullableDateTimeToJson(instance.endDate),
      'is_active': instance.isActive,
      'occurrence_count': instance.occurrenceCount,
      'max_occurrences': instance.maxOccurrences,
      'created_at': RecurringRuleModel._dateTimeToJson(instance.createdAt),
      'updated_at': RecurringRuleModel._dateTimeToJson(instance.updatedAt),
      'sync_status': instance.syncStatus,
    };
