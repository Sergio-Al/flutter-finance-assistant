// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  displayName: json['display_name'] as String?,
  photoUrl: json['photo_url'] as String?,
  preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
  biometricEnabled: json['biometric_enabled'] as bool? ?? false,
  themePreference: json['theme_preference'] as String? ?? 'system',
  createdAt: UserModel._dateTimeFromJson(json['created_at']),
  updatedAt: UserModel._dateTimeFromJson(json['updated_at']),
  syncedAt: UserModel._nullableDateTimeFromJson(json['synced_at']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'display_name': instance.displayName,
  'photo_url': instance.photoUrl,
  'preferred_currency': instance.preferredCurrency,
  'biometric_enabled': instance.biometricEnabled,
  'theme_preference': instance.themePreference,
  'created_at': UserModel._dateTimeToJson(instance.createdAt),
  'updated_at': UserModel._dateTimeToJson(instance.updatedAt),
  'synced_at': UserModel._nullableDateTimeToJson(instance.syncedAt),
};
