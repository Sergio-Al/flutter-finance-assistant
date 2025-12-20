import 'package:equatable/equatable.dart';

/// Represents a user in the domain layer.
///
/// Contains user profile information and preferences.
/// This is a pure Dart class with no external dependencies.
class User extends Equatable {
  /// Unique identifier (Firebase UID)
  final String id;

  /// User's email address
  final String email;

  /// Display name for the user
  final String? displayName;

  /// URL to user's profile photo
  final String? photoUrl;

  /// User's preferred currency code (e.g., 'USD', 'EUR')
  final String preferredCurrency;

  /// Whether the user has enabled biometric authentication
  final bool biometricEnabled;

  /// User's preferred theme mode
  final ThemePreference themePreference;

  /// When the user account was created
  final DateTime createdAt;

  /// When the user profile was last updated
  final DateTime updatedAt;

  /// When the user was last synced with remote
  final DateTime? syncedAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferredCurrency = 'USD',
    this.biometricEnabled = false,
    this.themePreference = ThemePreference.system,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  /// Creates a copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? preferredCurrency,
    bool? biometricEnabled,
    ThemePreference? themePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Get user's initials for avatar display
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email.substring(0, 2).toUpperCase();
    }
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName!.substring(0, displayName!.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        preferredCurrency,
        biometricEnabled,
        themePreference,
        createdAt,
        updatedAt,
        syncedAt,
      ];
}

/// User's theme preference
enum ThemePreference {
  light,
  dark,
  system,
}
