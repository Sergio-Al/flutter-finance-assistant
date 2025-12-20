import 'package:equatable/equatable.dart';

/// Represents a scanned receipt in the domain layer.
///
/// Contains OCR-extracted data from receipt images.
/// Linked to a transaction once processed.
class Receipt extends Equatable {
  /// Unique identifier
  final String id;

  /// Linked transaction ID (null if not yet linked)
  final String? transactionId;

  /// URL to receipt image (remote storage)
  final String? imageUrl;

  /// Local file path (before upload)
  final String? localPath;

  /// Raw text extracted by OCR
  final String? ocrRawText;

  /// OCR extraction confidence (0.0 - 1.0)
  final double? ocrConfidence;

  /// Extracted merchant name
  final String? merchantName;

  /// Extracted total amount
  final double? totalAmount;

  /// Extracted tax amount
  final double? taxAmount;

  /// Extracted receipt date
  final DateTime? receiptDate;

  /// Extracted line items
  final List<ReceiptItem> items;

  /// Suggested category based on merchant
  final String? suggestedCategoryId;

  /// Processing status
  final ReceiptStatus status;

  /// When the receipt was created
  final DateTime createdAt;

  /// Sync status with remote
  final String syncStatus;

  const Receipt({
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
    this.status = ReceiptStatus.pending,
    required this.createdAt,
    this.syncStatus = 'pending',
  });

  /// Creates a copy with modified fields
  Receipt copyWith({
    String? id,
    String? transactionId,
    String? imageUrl,
    String? localPath,
    String? ocrRawText,
    double? ocrConfidence,
    String? merchantName,
    double? totalAmount,
    double? taxAmount,
    DateTime? receiptDate,
    List<ReceiptItem>? items,
    String? suggestedCategoryId,
    ReceiptStatus? status,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return Receipt(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      receiptDate: receiptDate ?? this.receiptDate,
      items: items ?? this.items,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Whether OCR extraction was successful
  bool get isExtracted => status == ReceiptStatus.extracted;

  /// Whether the receipt is linked to a transaction
  bool get isLinked => transactionId != null;

  /// Whether extraction confidence is high
  bool get isHighConfidence => ocrConfidence != null && ocrConfidence! >= 0.85;

  /// Subtotal (total - tax)
  double? get subtotal {
    if (totalAmount == null) return null;
    return totalAmount! - (taxAmount ?? 0);
  }

  /// Path to display (URL or local)
  String? get displayPath => imageUrl ?? localPath;

  @override
  List<Object?> get props => [
        id,
        transactionId,
        imageUrl,
        localPath,
        ocrRawText,
        ocrConfidence,
        merchantName,
        totalAmount,
        taxAmount,
        receiptDate,
        items,
        suggestedCategoryId,
        status,
        createdAt,
        syncStatus,
      ];
}

/// Represents a line item on a receipt
class ReceiptItem extends Equatable {
  /// Item name/description
  final String name;

  /// Item quantity
  final double quantity;

  /// Unit price
  final double unitPrice;

  /// Total price for this item
  final double totalPrice;

  const ReceiptItem({
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Create from JSON map
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  @override
  List<Object?> get props => [name, quantity, unitPrice, totalPrice];
}

/// Receipt processing status
enum ReceiptStatus {
  /// Receipt captured, awaiting processing
  pending,

  /// OCR processing in progress
  processing,

  /// OCR extraction complete
  extracted,

  /// Linked to a transaction
  linked,

  /// OCR extraction failed
  failed,
}

/// Extension for ReceiptStatus utilities
extension ReceiptStatusExtension on ReceiptStatus {
  String get value {
    switch (this) {
      case ReceiptStatus.pending:
        return 'pending';
      case ReceiptStatus.processing:
        return 'processing';
      case ReceiptStatus.extracted:
        return 'extracted';
      case ReceiptStatus.linked:
        return 'linked';
      case ReceiptStatus.failed:
        return 'failed';
    }
  }

  static ReceiptStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReceiptStatus.pending;
      case 'processing':
        return ReceiptStatus.processing;
      case 'extracted':
        return ReceiptStatus.extracted;
      case 'linked':
        return ReceiptStatus.linked;
      case 'failed':
        return ReceiptStatus.failed;
      default:
        return ReceiptStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ReceiptStatus.pending:
        return 'Pending';
      case ReceiptStatus.processing:
        return 'Processing';
      case ReceiptStatus.extracted:
        return 'Ready';
      case ReceiptStatus.linked:
        return 'Linked';
      case ReceiptStatus.failed:
        return 'Failed';
    }
  }
}
