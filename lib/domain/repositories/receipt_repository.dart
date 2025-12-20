import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';

/// Repository interface for receipt operations.
///
/// Defines the contract for receipt scanning and data access.
/// Implementation will be in the data layer.
abstract class ReceiptRepository {
  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all receipts for a user.
  Future<Either<Failure, List<Receipt>>> getReceipts(String userId);

  /// Get receipt by ID.
  Future<Either<Failure, Receipt>> getReceiptById(String receiptId);

  /// Get receipt by transaction ID.
  Future<Either<Failure, Receipt?>> getReceiptByTransaction(
    String transactionId,
  );

  /// Create a new receipt record.
  Future<Either<Failure, Receipt>> createReceipt(Receipt receipt);

  /// Update a receipt.
  Future<Either<Failure, Receipt>> updateReceipt(Receipt receipt);

  /// Delete a receipt.
  Future<Either<Failure, void>> deleteReceipt(String receiptId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Image Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload receipt image and create receipt record.
  Future<Either<Failure, Receipt>> uploadReceiptImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Upload receipt image from file path.
  Future<Either<Failure, Receipt>> uploadReceiptFromPath({
    required String userId,
    required String filePath,
  });

  /// Get receipt image bytes.
  Future<Either<Failure, Uint8List>> getReceiptImage(String receiptId);

  /// Delete receipt image from storage.
  Future<Either<Failure, void>> deleteReceiptImage(String receiptId);

  // ═══════════════════════════════════════════════════════════════════════════
  // OCR Processing
  // ═══════════════════════════════════════════════════════════════════════════

  /// Process receipt image with OCR.
  Future<Either<Failure, Receipt>> processReceiptOcr(String receiptId);

  /// Extract text from image bytes using OCR.
  Future<Either<Failure, OcrResult>> extractTextFromImage(Uint8List imageBytes);

  /// Parse extracted text to receipt data.
  Future<Either<Failure, Receipt>> parseReceiptText(
    String receiptId,
    String rawText,
  );

  /// Reprocess OCR for a receipt.
  Future<Either<Failure, Receipt>> reprocessOcr(String receiptId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Linking
  // ═══════════════════════════════════════════════════════════════════════════

  /// Link receipt to a transaction.
  Future<Either<Failure, Receipt>> linkToTransaction(
    String receiptId,
    String transactionId,
  );

  /// Unlink receipt from transaction.
  Future<Either<Failure, Receipt>> unlinkFromTransaction(String receiptId);

  /// Create transaction from receipt data.
  Future<Either<Failure, String>> createTransactionFromReceipt(
    String receiptId,
    String accountId,
    String categoryId,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get unlinked receipts (not yet matched to transactions).
  Future<Either<Failure, List<Receipt>>> getUnlinkedReceipts(String userId);

  /// Get receipts by status.
  Future<Either<Failure, List<Receipt>>> getReceiptsByStatus(
    String userId,
    ReceiptStatus status,
  );

  /// Get receipts within a date range.
  Future<Either<Failure, List<Receipt>>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Search receipts by merchant name.
  Future<Either<Failure, List<Receipt>>> searchByMerchant(
    String userId,
    String query,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of receipts for real-time updates.
  Stream<Either<Failure, List<Receipt>>> watchReceipts(String userId);

  /// Stream of unlinked receipts for notifications.
  Stream<Either<Failure, List<Receipt>>> watchUnlinkedReceipts(String userId);
}

/// Result of OCR text extraction.
class OcrResult {
  /// Raw extracted text
  final String rawText;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Detected language
  final String? language;

  /// Individual text blocks with positions
  final List<TextBlock> textBlocks;

  const OcrResult({
    required this.rawText,
    required this.confidence,
    this.language,
    this.textBlocks = const [],
  });
}

/// A block of text detected by OCR.
class TextBlock {
  final String text;
  final double confidence;
  final Rect boundingBox;

  const TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

/// Simple rectangle for bounding box.
class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
