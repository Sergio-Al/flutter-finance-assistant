import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'receipts_dao.g.dart';

/// Data Access Object for Receipts and ReceiptItems tables.
@DriftAccessor(tables: [Receipts, ReceiptItems])
class ReceiptsDao extends DatabaseAccessor<AppDatabase>
    with _$ReceiptsDaoMixin {
  ReceiptsDao(super.db);

  /// Get all receipts
  Future<List<ReceiptEntry>> getAllReceipts() {
    return (select(receipts)..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// Get receipt by ID
  Future<ReceiptEntry?> getReceiptById(String id) {
    return (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Get receipt by transaction ID
  Future<ReceiptEntry?> getReceiptByTransactionId(String transactionId) {
    return (select(receipts)
          ..where((r) => r.transactionId.equals(transactionId)))
        .getSingleOrNull();
  }

  /// Get pending receipts (awaiting OCR)
  Future<List<ReceiptEntry>> getPendingReceipts() {
    return (select(receipts)..where((r) => r.status.equals('pending'))).get();
  }

  /// Get extracted receipts (ready to link)
  Future<List<ReceiptEntry>> getExtractedReceipts() {
    return (select(receipts)
          ..where((r) => r.status.equals('extracted'))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// Get unlinked receipts
  Future<List<ReceiptEntry>> getUnlinkedReceipts() {
    return (select(receipts)
          ..where((r) => r.transactionId.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// Watch pending receipts
  Stream<List<ReceiptEntry>> watchPendingReceipts() {
    return (select(receipts)..where((r) => r.status.equals('pending'))).watch();
  }

  /// Watch all receipts
  Stream<List<ReceiptEntry>> watchAllReceipts() {
    return (select(receipts)..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  /// Insert new receipt
  Future<void> insertReceipt(ReceiptsCompanion receipt) {
    return into(receipts).insert(receipt);
  }

  /// Update receipt
  Future<bool> updateReceipt(ReceiptsCompanion receipt) {
    return (update(receipts)..where((r) => r.id.equals(receipt.id.value)))
        .write(receipt)
        .then((rows) => rows > 0);
  }

  /// Update OCR extraction results
  Future<bool> updateOcrResults({
    required String id,
    required String ocrRawText,
    required double ocrConfidence,
    String? merchantName,
    double? totalAmount,
    double? taxAmount,
    DateTime? receiptDate,
    String? suggestedCategoryId,
  }) {
    return (update(receipts)..where((r) => r.id.equals(id))).write(
      ReceiptsCompanion(
        ocrRawText: Value(ocrRawText),
        ocrConfidence: Value(ocrConfidence),
        merchantName: Value(merchantName),
        totalAmount: Value(totalAmount),
        taxAmount: Value(taxAmount),
        receiptDate: Value(receiptDate),
        suggestedCategoryId: Value(suggestedCategoryId),
        status: const Value('extracted'),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Update status
  Future<bool> updateStatus(String id, String status) {
    return (update(receipts)..where((r) => r.id.equals(id))).write(
      ReceiptsCompanion(
        status: Value(status),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Link receipt to transaction
  Future<bool> linkToTransaction(String receiptId, String transactionId) {
    return (update(receipts)..where((r) => r.id.equals(receiptId))).write(
      ReceiptsCompanion(
        transactionId: Value(transactionId),
        status: const Value('linked'),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Unlink receipt from transaction
  Future<bool> unlinkFromTransaction(String receiptId) {
    return (update(receipts)..where((r) => r.id.equals(receiptId))).write(
      const ReceiptsCompanion(
        transactionId: Value(null),
        status: Value('extracted'),
        syncStatus: Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Update image URL after upload
  Future<bool> updateImageUrl(String id, String imageUrl) {
    return (update(receipts)..where((r) => r.id.equals(id))).write(
      ReceiptsCompanion(
        imageUrl: Value(imageUrl),
        syncStatus: const Value('pending'),
      ),
    ).then((rows) => rows > 0);
  }

  /// Delete receipt
  Future<int> deleteReceipt(String id) async {
    // Delete items first
    await (delete(receiptItems)..where((i) => i.receiptId.equals(id))).go();
    // Then delete receipt
    return (delete(receipts)..where((r) => r.id.equals(id))).go();
  }

  // ============ Receipt Items ============

  /// Get items for a receipt
  Future<List<ReceiptItemEntry>> getReceiptItems(String receiptId) {
    return (select(receiptItems)..where((i) => i.receiptId.equals(receiptId)))
        .get();
  }

  /// Insert receipt item
  Future<int> insertReceiptItem(ReceiptItemsCompanion item) {
    return into(receiptItems).insert(item);
  }

  /// Insert multiple receipt items
  Future<void> insertReceiptItems(List<ReceiptItemsCompanion> items) {
    return batch((batch) {
      batch.insertAll(receiptItems, items);
    });
  }

  /// Delete receipt items
  Future<int> deleteReceiptItems(String receiptId) {
    return (delete(receiptItems)..where((i) => i.receiptId.equals(receiptId)))
        .go();
  }

  /// Get receipts pending sync
  Future<List<ReceiptEntry>> getPendingSync() {
    return (select(receipts)..where((r) => r.syncStatus.equals('pending')))
        .get();
  }

  /// Update sync status
  Future<bool> updateSyncStatus(String id, String status) {
    return (update(receipts)..where((r) => r.id.equals(id))).write(
      ReceiptsCompanion(syncStatus: Value(status)),
    ).then((rows) => rows > 0);
  }
}
