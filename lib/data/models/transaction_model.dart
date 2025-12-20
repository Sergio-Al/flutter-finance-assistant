import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/transaction.dart';

part 'transaction_model.g.dart';

/// Data model for Transaction entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class TransactionModel {
  /// Unique identifier
  final String id;

  /// Account this transaction belongs to
  @JsonKey(name: 'account_id')
  final String accountId;

  /// Category for this transaction
  @JsonKey(name: 'category_id')
  final String categoryId;

  /// Transaction amount (always positive)
  final double amount;

  /// Type of transaction
  final String type;

  /// Description or note
  final String? description;

  /// Date of the transaction
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime date;

  /// URL to receipt image
  @JsonKey(name: 'receipt_url')
  final String? receiptUrl;

  /// Location where transaction occurred
  final String? location;

  /// Tags for filtering/search
  final List<String> tags;

  /// AI categorization confidence (0.0 - 1.0)
  @JsonKey(name: 'ai_category_confidence')
  final double? aiCategoryConfidence;

  /// Whether this is a recurring transaction
  @JsonKey(name: 'is_recurring')
  final bool isRecurring;

  /// ID of the recurring rule
  @JsonKey(name: 'recurring_id')
  final String? recurringId;

  /// Target account for transfers
  @JsonKey(name: 'to_account_id')
  final String? toAccountId;

  /// When the transaction was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the transaction was last updated
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.receiptUrl,
    this.location,
    this.tags = const [],
    this.aiCategoryConfidence,
    this.isRecurring = false,
    this.recurringId,
    this.toAccountId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  /// Create from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  /// Convert to domain entity
  Transaction toEntity() => Transaction(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        amount: amount,
        type: TransactionTypeExtension.fromString(type),
        description: description,
        date: date,
        receiptUrl: receiptUrl,
        location: location,
        tags: tags,
        aiCategoryConfidence: aiCategoryConfidence,
        isRecurring: isRecurring,
        recurringId: recurringId,
        toAccountId: toAccountId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory TransactionModel.fromEntity(Transaction entity) => TransactionModel(
        id: entity.id,
        accountId: entity.accountId,
        categoryId: entity.categoryId,
        amount: entity.amount,
        type: entity.type.value,
        description: entity.description,
        date: entity.date,
        receiptUrl: entity.receiptUrl,
        location: entity.location,
        tags: entity.tags,
        aiCategoryConfidence: entity.aiCategoryConfidence,
        isRecurring: entity.isRecurring,
        recurringId: entity.recurringId,
        toAccountId: entity.toAccountId,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory TransactionModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return TransactionModel.fromJson({
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
