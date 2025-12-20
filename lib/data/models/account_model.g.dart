// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountModel _$AccountModelFromJson(Map<String, dynamic> json) => AccountModel(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
  currency: json['currency'] as String? ?? 'USD',
  icon: json['icon'] as String? ?? 'account_balance_wallet',
  color: (json['color'] as num?)?.toInt() ?? 0xFF2E7D6F,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: AccountModel._dateTimeFromJson(json['created_at']),
  updatedAt: AccountModel._dateTimeFromJson(json['updated_at']),
  syncStatus: json['sync_status'] as String? ?? 'pending',
);

Map<String, dynamic> _$AccountModelToJson(AccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'type': instance.type,
      'balance': instance.balance,
      'currency': instance.currency,
      'icon': instance.icon,
      'color': instance.color,
      'is_active': instance.isActive,
      'created_at': AccountModel._dateTimeToJson(instance.createdAt),
      'updated_at': AccountModel._dateTimeToJson(instance.updatedAt),
      'sync_status': instance.syncStatus,
    };
