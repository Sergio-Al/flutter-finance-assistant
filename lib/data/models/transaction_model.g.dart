// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String?,
      date: TransactionModel._dateTimeFromJson(json['date']),
      receiptUrl: json['receipt_url'] as String?,
      location: json['location'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      aiCategoryConfidence: (json['ai_category_confidence'] as num?)
          ?.toDouble(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringId: json['recurring_id'] as String?,
      toAccountId: json['to_account_id'] as String?,
      createdAt: TransactionModel._dateTimeFromJson(json['created_at']),
      updatedAt: TransactionModel._dateTimeFromJson(json['updated_at']),
      syncStatus: json['sync_status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'category_id': instance.categoryId,
      'amount': instance.amount,
      'type': instance.type,
      'description': instance.description,
      'date': TransactionModel._dateTimeToJson(instance.date),
      'receipt_url': instance.receiptUrl,
      'location': instance.location,
      'tags': instance.tags,
      'ai_category_confidence': instance.aiCategoryConfidence,
      'is_recurring': instance.isRecurring,
      'recurring_id': instance.recurringId,
      'to_account_id': instance.toAccountId,
      'created_at': TransactionModel._dateTimeToJson(instance.createdAt),
      'updated_at': TransactionModel._dateTimeToJson(instance.updatedAt),
      'sync_status': instance.syncStatus,
    };
