import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/user.dart';

part 'user_model.g.dart';

/// Data model for User entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class UserModel {
  /// Unique identifier (Firebase UID)
  final String id;

  /// User's email address
  final String email;

  /// Display name for the user
  @JsonKey(name: 'display_name')
  final String? displayName;

  /// URL to user's profile photo
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  /// User's preferred currency code
  @JsonKey(name: 'preferred_currency')
  final String preferredCurrency;

  /// Whether biometric authentication is enabled
  @JsonKey(name: 'biometric_enabled')
  final bool biometricEnabled;

  /// User's preferred theme mode
  @JsonKey(name: 'theme_preference')
  final String themePreference;

  /// When the user account was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the user profile was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// When the user was last synced with remote
  @JsonKey(name: 'synced_at', fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? syncedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredCurrency = 'USD',
    this.biometricEnabled = false,
    this.themePreference = 'system',
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Convert to domain entity
  User toEntity() => User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        preferredCurrency: preferredCurrency,
        biometricEnabled: biometricEnabled,
        themePreference: _themePreferenceFromString(themePreference),
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncedAt: syncedAt,
      );

  /// Create from domain entity
  factory UserModel.fromEntity(User entity) => UserModel(
        id: entity.id,
        email: entity.email,
        displayName: entity.displayName,
        photoUrl: entity.photoUrl,
        preferredCurrency: entity.preferredCurrency,
        biometricEnabled: entity.biometricEnabled,
        themePreference: _themePreferenceToString(entity.themePreference),
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncedAt: entity.syncedAt,
      );

  /// Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel.fromJson({
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

  // Helper methods for ThemePreference conversion
  static ThemePreference _themePreferenceFromString(String value) {
    switch (value) {
      case 'light':
        return ThemePreference.light;
      case 'dark':
        return ThemePreference.dark;
      case 'system':
      default:
        return ThemePreference.system;
    }
  }

  static String _themePreferenceToString(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.light:
        return 'light';
      case ThemePreference.dark:
        return 'dark';
      case ThemePreference.system:
        return 'system';
    }
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
