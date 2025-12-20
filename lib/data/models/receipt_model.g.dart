// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptModel _$ReceiptModelFromJson(Map<String, dynamic> json) => ReceiptModel(
  id: json['id'] as String,
  transactionId: json['transaction_id'] as String?,
  imageUrl: json['image_url'] as String?,
  localPath: json['local_path'] as String?,
  ocrRawText: json['ocr_raw_text'] as String?,
  ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble(),
  merchantName: json['merchant_name'] as String?,
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  taxAmount: (json['tax_amount'] as num?)?.toDouble(),
  receiptDate: ReceiptModel._nullableDateTimeFromJson(json['receipt_date']),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  suggestedCategoryId: json['suggested_category_id'] as String?,
  status: json['status'] as String? ?? 'pending',
  createdAt: ReceiptModel._dateTimeFromJson(json['created_at']),
  syncStatus: json['sync_status'] as String? ?? 'pending',
);

Map<String, dynamic> _$ReceiptModelToJson(
  ReceiptModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'transaction_id': instance.transactionId,
  'image_url': instance.imageUrl,
  'local_path': instance.localPath,
  'ocr_raw_text': instance.ocrRawText,
  'ocr_confidence': instance.ocrConfidence,
  'merchant_name': instance.merchantName,
  'total_amount': instance.totalAmount,
  'tax_amount': instance.taxAmount,
  'receipt_date': ReceiptModel._nullableDateTimeToJson(instance.receiptDate),
  'items': instance.items,
  'suggested_category_id': instance.suggestedCategoryId,
  'status': instance.status,
  'created_at': ReceiptModel._dateTimeToJson(instance.createdAt),
  'sync_status': instance.syncStatus,
};

ReceiptItemModel _$ReceiptItemModelFromJson(Map<String, dynamic> json) =>
    ReceiptItemModel(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );

Map<String, dynamic> _$ReceiptItemModelToJson(ReceiptItemModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
    };
