import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/account.dart';

part 'account_model.g.dart';

/// Data model for Account entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class AccountModel {
  /// Unique identifier
  final String id;

  /// Owner user ID
  @JsonKey(name: 'user_id')
  final String userId;

  /// Account display name
  final String name;

  /// Type of account
  final String type;

  /// Current balance
  final double balance;

  /// Currency code
  final String currency;

  /// Icon name for display
  final String icon;

  /// Color hex value for display
  final int color;

  /// Whether the account is active
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// When the account was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the account was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const AccountModel({
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

  /// Create from JSON
  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$AccountModelToJson(this);

  /// Convert to domain entity
  Account toEntity() => Account(
        id: id,
        userId: userId,
        name: name,
        type: AccountTypeExtension.fromString(type),
        balance: balance,
        currency: currency,
        icon: icon,
        color: color,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory AccountModel.fromEntity(Account entity) => AccountModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        type: entity.type.value,
        balance: entity.balance,
        currency: entity.currency,
        icon: entity.icon,
        color: entity.color,
        isActive: entity.isActive,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory AccountModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AccountModel.fromJson({
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
