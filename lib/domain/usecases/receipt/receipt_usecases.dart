/// Barrel export for all receipt-related use cases.
///
/// Import this file to access all receipt use cases:
/// ```dart
/// import 'package:flutter_finance_assistant/domain/usecases/receipt/receipt_usecases.dart';
/// ```
///
/// ## Available Use Cases
///
/// ### Scanning & Upload
/// - [ScanReceiptUseCase] - Upload receipt image (from bytes or file path)
///
/// ### OCR Processing
/// - [ProcessReceiptOcrUseCase] - Extract text from receipt image
/// - [ReprocessReceiptOcrUseCase] - Re-run OCR on failed/low-confidence receipts
///
/// ### Transaction Linking
/// - [LinkReceiptToTransactionUseCase] - Link receipt to existing transaction
/// - [UnlinkReceiptFromTransactionUseCase] - Unlink receipt from transaction
/// - [CreateTransactionFromReceiptUseCase] - Create new transaction from receipt data
///
/// ### Query Operations
/// - [GetReceiptsUseCase] - Get all receipts for a user
/// - [GetReceiptByIdUseCase] - Get a single receipt
/// - [GetUnlinkedReceiptsUseCase] - Get receipts not linked to transactions
/// - [GetReceiptsByStatusUseCase] - Get receipts by processing status
/// - [GetReceiptsByDateRangeUseCase] - Get receipts within date range
/// - [SearchReceiptsByMerchantUseCase] - Search by merchant name
///
/// ### Management
/// - [UpdateReceiptUseCase] - Update receipt data
/// - [DeleteReceiptUseCase] - Delete receipt and image
///
/// ### Real-time Streams
/// - [WatchReceiptsUseCase] - Stream all receipts
/// - [WatchUnlinkedReceiptsUseCase] - Stream unlinked receipts for notifications
library;

export 'delete_receipt.dart';
export 'get_receipts.dart';
export 'link_receipt.dart';
export 'process_receipt_ocr.dart';
export 'scan_receipt.dart';
