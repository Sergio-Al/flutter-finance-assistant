import 'package:json_annotation/json_annotation.dart';

import 'package:flutter_finance_assistant/domain/entities/receipt.dart';

part 'receipt_model.g.dart';

/// Data model for Receipt entity.
///
/// Handles JSON serialization for Firebase/API communication.
@JsonSerializable()
class ReceiptModel {
  /// Unique identifier
  final String id;

  /// Linked transaction ID
  @JsonKey(name: 'transaction_id')
  final String? transactionId;

  /// URL to receipt image (remote storage)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Local file path (before upload)
  @JsonKey(name: 'local_path')
  final String? localPath;

  /// Raw text extracted by OCR
  @JsonKey(name: 'ocr_raw_text')
  final String? ocrRawText;

  /// OCR extraction confidence (0.0 - 1.0)
  @JsonKey(name: 'ocr_confidence')
  final double? ocrConfidence;

  /// Extracted merchant name
  @JsonKey(name: 'merchant_name')
  final String? merchantName;

  /// Extracted total amount
  @JsonKey(name: 'total_amount')
  final double? totalAmount;

  /// Extracted tax amount
  @JsonKey(name: 'tax_amount')
  final double? taxAmount;

  /// Extracted receipt date
  @JsonKey(name: 'receipt_date', fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? receiptDate;

  /// Extracted line items
  final List<ReceiptItemModel> items;

  /// Suggested category based on merchant
  @JsonKey(name: 'suggested_category_id')
  final String? suggestedCategoryId;

  /// Processing status
  final String status;

  /// When the receipt was created
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// Sync status with remote
  @JsonKey(name: 'sync_status')
  final String syncStatus;

  const ReceiptModel({
    required this.id,
    this.transactionId,
    this.imageUrl,
    this.localPath,
    this.ocrRawText,
    this.ocrConfidence,
    this.merchantName,
    this.totalAmount,
    this.taxAmount,
    this.receiptDate,
    this.items = const [],
    this.suggestedCategoryId,
    this.status = 'pending',
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  /// Create from JSON
  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ReceiptModelToJson(this);

  /// Convert to domain entity
  Receipt toEntity() => Receipt(
        id: id,
        transactionId: transactionId,
        imageUrl: imageUrl,
        localPath: localPath,
        ocrRawText: ocrRawText,
        ocrConfidence: ocrConfidence,
        merchantName: merchantName,
        totalAmount: totalAmount,
        taxAmount: taxAmount,
        receiptDate: receiptDate,
        items: items.map((item) => item.toEntity()).toList(),
        suggestedCategoryId: suggestedCategoryId,
        status: ReceiptStatusExtension.fromString(status),
        createdAt: createdAt,
        syncStatus: syncStatus,
      );

  /// Create from domain entity
  factory ReceiptModel.fromEntity(Receipt entity) => ReceiptModel(
        id: entity.id,
        transactionId: entity.transactionId,
        imageUrl: entity.imageUrl,
        localPath: entity.localPath,
        ocrRawText: entity.ocrRawText,
        ocrConfidence: entity.ocrConfidence,
        merchantName: entity.merchantName,
        totalAmount: entity.totalAmount,
        taxAmount: entity.taxAmount,
        receiptDate: entity.receiptDate,
        items: entity.items.map((item) => ReceiptItemModel.fromEntity(item)).toList(),
        suggestedCategoryId: entity.suggestedCategoryId,
        status: entity.status.value,
        createdAt: entity.createdAt,
        syncStatus: entity.syncStatus,
      );

  /// Create from Firestore document
  factory ReceiptModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ReceiptModel.fromJson({
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

  static DateTime? _nullableDateTimeFromJson(dynamic value) {
    if (value == null) return null;
    return _dateTimeFromJson(value);
  }

  static dynamic _nullableDateTimeToJson(DateTime? dateTime) =>
      dateTime?.toIso8601String();
}

/// Data model for ReceiptItem.
@JsonSerializable()
class ReceiptItemModel {
  /// Item name/description
  final String name;

  /// Item quantity
  final double quantity;

  /// Unit price
  @JsonKey(name: 'unit_price')
  final double unitPrice;

  /// Total price for this item
  @JsonKey(name: 'total_price')
  final double totalPrice;

  const ReceiptItemModel({
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Create from JSON
  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemModelFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ReceiptItemModelToJson(this);

  /// Convert to domain entity
  ReceiptItem toEntity() => ReceiptItem(
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );

  /// Create from domain entity
  factory ReceiptItemModel.fromEntity(ReceiptItem entity) => ReceiptItemModel(
        name: entity.name,
        quantity: entity.quantity,
        unitPrice: entity.unitPrice,
        totalPrice: entity.totalPrice,
      );
}
