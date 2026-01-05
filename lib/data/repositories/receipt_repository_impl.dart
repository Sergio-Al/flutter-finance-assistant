import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as mlkit;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/receipt_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/receipt_model.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';

/// Implementation of [ReceiptRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase.
/// Integrates with Google ML Kit for OCR text recognition.
class ReceiptRepositoryImpl implements ReceiptRepository {
  final AppDatabase _database;
  final ReceiptRemoteDataSource _remoteDataSource;
  final mlkit.TextRecognizer _textRecognizer;
  final Uuid _uuid;

  /// Creates [ReceiptRepositoryImpl] with required data sources.
  ReceiptRepositoryImpl({
    required AppDatabase database,
    required ReceiptRemoteDataSource remoteDataSource,
    mlkit.TextRecognizer? textRecognizer,
    Uuid? uuid,
  }) : _database = database,
       _remoteDataSource = remoteDataSource,
       _textRecognizer = textRecognizer ?? mlkit.TextRecognizer(),
       _uuid = uuid ?? const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Receipt>>> getReceipts(String userId) async {
    try {
      final entries = await _database.receiptsDao.getAllReceipts();
      final receipts = await Future.wait(
        entries.map((entry) => _entryToEntity(entry)),
      );
      return Right(receipts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> getReceiptById(String receiptId) async {
    try {
      final entry = await _database.receiptsDao.getReceiptById(receiptId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Receipt not found: $receiptId'));
      }
      final receipt = await _entryToEntity(entry);
      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt?>> getReceiptByTransaction(
    String transactionId,
  ) async {
    try {
      final entry = await _database.receiptsDao.getReceiptByTransactionId(
        transactionId,
      );
      if (entry == null) {
        return const Right(null);
      }
      final receipt = await _entryToEntity(entry);
      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipt by transaction: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> createReceipt(Receipt receipt) async {
    try {
      await _database.receiptsDao.insertReceipt(_entityToCompanion(receipt));

      // Insert receipt items if any
      if (receipt.items.isNotEmpty) {
        final itemCompanions = receipt.items.asMap().entries.map((entry) {
          return ReceiptItemsCompanion(
            receiptId: Value(receipt.id),
            name: Value(entry.value.name),
            quantity: Value(entry.value.quantity),
            unitPrice: Value(entry.value.unitPrice),
            totalPrice: Value(entry.value.totalPrice),
          );
        }).toList();
        await _database.receiptsDao.insertReceiptItems(itemCompanions);
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'receipts',
        recordId: receipt.id,
        data: jsonEncode(ReceiptModel.fromEntity(receipt).toJson()),
      );

      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> updateReceipt(Receipt receipt) async {
    try {
      final success = await _database.receiptsDao.updateReceipt(
        _entityToCompanion(receipt.copyWith(syncStatus: 'pending')),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Receipt not found for update: ${receipt.id}',
          ),
        );
      }

      // Update items - delete old and insert new
      await _database.receiptsDao.deleteReceiptItems(receipt.id);
      if (receipt.items.isNotEmpty) {
        final itemCompanions = receipt.items.asMap().entries.map((entry) {
          return ReceiptItemsCompanion(
            receiptId: Value(receipt.id),
            name: Value(entry.value.name),
            quantity: Value(entry.value.quantity),
            unitPrice: Value(entry.value.unitPrice),
            totalPrice: Value(entry.value.totalPrice),
          );
        }).toList();
        await _database.receiptsDao.insertReceiptItems(itemCompanions);
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'receipts',
        recordId: receipt.id,
        data: jsonEncode(ReceiptModel.fromEntity(receipt).toJson()),
      );

      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceipt(String receiptId) async {
    try {
      final deletedCount = await _database.receiptsDao.deleteReceipt(receiptId);
      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(
            message: 'Receipt not found for deletion: $receiptId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'receipts',
        recordId: receiptId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Image Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Receipt>> uploadReceiptImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final now = DateTime.now();
      final receiptId = 'receipt_${_uuid.v4()}';

      // Save image locally first
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/$fileName';
      final file = File(localPath);
      await file.writeAsBytes(imageBytes);

      // Create receipt record with local path
      final receipt = Receipt(
        id: receiptId,
        localPath: localPath,
        status: ReceiptStatus.pending,
        createdAt: now,
        syncStatus: 'pending',
      );

      await _database.receiptsDao.insertReceipt(_entityToCompanion(receipt));

      // Add to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'receipts',
        recordId: receiptId,
        data: jsonEncode(ReceiptModel.fromEntity(receipt).toJson()),
      );

      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to save receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error uploading receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> uploadReceiptFromPath({
    required String userId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(NotFoundFailure(message: 'File not found: $filePath'));
      }

      final imageBytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;

      return uploadReceiptImage(
        userId: userId,
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error uploading receipt from path: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Uint8List>> getReceiptImage(String receiptId) async {
    try {
      final entry = await _database.receiptsDao.getReceiptById(receiptId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Receipt not found: $receiptId'));
      }

      // Try local path first
      if (entry.localPath != null) {
        final file = File(entry.localPath!);
        if (await file.exists()) {
          return Right(await file.readAsBytes());
        }
      }

      // If no local file, we'd need to download from URL
      // This is a simplified implementation
      return Left(NotFoundFailure(message: 'Receipt image not found locally'));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipt image: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipt image: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiptImage(String receiptId) async {
    try {
      final entry = await _database.receiptsDao.getReceiptById(receiptId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Receipt not found: $receiptId'));
      }

      // Delete local file if exists
      if (entry.localPath != null) {
        final file = File(entry.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Clear image paths in database
      await _database.receiptsDao.updateReceipt(
        ReceiptsCompanion(
          id: Value(receiptId),
          localPath: const Value(null),
          imageUrl: const Value(null),
          syncStatus: const Value('pending'),
        ),
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete receipt image: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting receipt image: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OCR Processing
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Receipt>> processReceiptOcr(String receiptId) async {
    try {
      final entry = await _database.receiptsDao.getReceiptById(receiptId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Receipt not found: $receiptId'));
      }

      // Update status to processing
      await _database.receiptsDao.updateStatus(receiptId, 'processing');

      // Get image bytes
      final imageResult = await getReceiptImage(receiptId);
      final imageBytes = imageResult.fold((failure) => null, (bytes) => bytes);

      if (imageBytes == null) {
        await _database.receiptsDao.updateStatus(receiptId, 'failed');
        return Left(
          NotFoundFailure(
            message: 'Receipt image not found for OCR processing',
          ),
        );
      }

      // Extract text using OCR
      final ocrResult = await extractTextFromImage(imageBytes);
      return ocrResult.fold(
        (failure) async {
          await _database.receiptsDao.updateStatus(receiptId, 'failed');
          return Left(failure);
        },
        (result) async {
          // Parse the extracted text
          return parseReceiptText(receiptId, result.rawText);
        },
      );
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to process OCR: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        OCRFailure(
          message: 'Unexpected error processing OCR: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OcrResult>> extractTextFromImage(
    Uint8List imageBytes,
  ) async {
    try {
      // Save bytes to temp file for ML Kit
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(imageBytes);

      final inputImage = mlkit.InputImage.fromFilePath(tempFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Clean up temp file
      await tempFile.delete();

      // Calculate overall confidence
      double totalConfidence = 0;
      int blockCount = 0;
      final textBlocks = <TextBlock>[];

      for (final block in recognizedText.blocks) {
        // ML Kit doesn't provide confidence directly, use 0.9 as default
        const blockConfidence = 0.9;
        totalConfidence += blockConfidence;
        blockCount++;

        textBlocks.add(
          TextBlock(
            text: block.text,
            confidence: blockConfidence,
            boundingBox: Rect(
              left: block.boundingBox.left,
              top: block.boundingBox.top,
              width: block.boundingBox.width,
              height: block.boundingBox.height,
            ),
          ),
        );
      }

      final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

      return Right(
        OcrResult(
          rawText: recognizedText.text,
          confidence: avgConfidence,
          textBlocks: textBlocks,
        ),
      );
    } catch (e) {
      return Left(
        OCRFailure(
          message: 'Failed to extract text from image: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> parseReceiptText(
    String receiptId,
    String rawText,
  ) async {
    try {
      // Parse merchant name (usually at the top)
      final merchantName = _extractMerchantName(rawText);

      // Parse total amount
      final totalAmount = _extractTotalAmount(rawText);

      // Parse tax amount
      final taxAmount = _extractTaxAmount(rawText);

      // Parse date
      final receiptDate = _extractDate(rawText);

      // Parse line items
      final items = _extractLineItems(rawText);

      // Calculate confidence based on what was extracted
      double confidence = 0.0;
      int extractedFields = 0;
      if (merchantName != null) extractedFields++;
      if (totalAmount != null) extractedFields++;
      if (receiptDate != null) extractedFields++;
      confidence = extractedFields / 3.0;

      // Update receipt with extracted data
      await _database.receiptsDao.updateOcrResults(
        id: receiptId,
        ocrRawText: rawText,
        ocrConfidence: confidence,
        merchantName: merchantName,
        totalAmount: totalAmount,
        taxAmount: taxAmount,
        receiptDate: receiptDate,
      );

      // Insert extracted items
      if (items.isNotEmpty) {
        await _database.receiptsDao.deleteReceiptItems(receiptId);
        final itemCompanions = items.asMap().entries.map((entry) {
          return ReceiptItemsCompanion(
            receiptId: Value(receiptId),
            name: Value(entry.value.name),
            quantity: Value(entry.value.quantity),
            unitPrice: Value(entry.value.unitPrice),
            totalPrice: Value(entry.value.totalPrice),
          );
        }).toList();
        await _database.receiptsDao.insertReceiptItems(itemCompanions);
      }

      // Get updated receipt
      final updatedEntry = await _database.receiptsDao.getReceiptById(
        receiptId,
      );
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(message: 'Receipt not found after OCR update'),
        );
      }

      final receipt = await _entryToEntity(updatedEntry);
      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to parse receipt text: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        OCRFailure(
          message: 'Unexpected error parsing receipt text: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> reprocessOcr(String receiptId) async {
    // Reset status and reprocess
    await _database.receiptsDao.updateStatus(receiptId, 'pending');
    return processReceiptOcr(receiptId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Linking
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Receipt>> linkToTransaction(
    String receiptId,
    String transactionId,
  ) async {
    try {
      final success = await _database.receiptsDao.linkToTransaction(
        receiptId,
        transactionId,
      );

      if (!success) {
        return Left(
          NotFoundFailure(message: 'Receipt not found for linking: $receiptId'),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'receipts',
        recordId: receiptId,
        data: '{"transactionId": "$transactionId", "status": "linked"}',
      );

      final updatedEntry = await _database.receiptsDao.getReceiptById(
        receiptId,
      );
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(message: 'Receipt not found after linking'),
        );
      }

      final receipt = await _entryToEntity(updatedEntry);
      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to link receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error linking receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Receipt>> unlinkFromTransaction(
    String receiptId,
  ) async {
    try {
      final success = await _database.receiptsDao.unlinkFromTransaction(
        receiptId,
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Receipt not found for unlinking: $receiptId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'receipts',
        recordId: receiptId,
        data: '{"transactionId": null, "status": "extracted"}',
      );

      final updatedEntry = await _database.receiptsDao.getReceiptById(
        receiptId,
      );
      if (updatedEntry == null) {
        return Left(
          NotFoundFailure(message: 'Receipt not found after unlinking'),
        );
      }

      final receipt = await _entryToEntity(updatedEntry);
      return Right(receipt);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to unlink receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error unlinking receipt: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> createTransactionFromReceipt(
    String receiptId,
    String accountId,
    String categoryId,
  ) async {
    try {
      final entry = await _database.receiptsDao.getReceiptById(receiptId);
      if (entry == null) {
        return Left(NotFoundFailure(message: 'Receipt not found: $receiptId'));
      }

      if (entry.totalAmount == null) {
        return Left(
          ValidationFailure(
            message:
                'Receipt has no extracted amount. Please process OCR first.',
          ),
        );
      }

      // Generate transaction ID - actual transaction creation would be done
      // through TransactionRepository
      final transactionId = 'txn_${_uuid.v4()}';

      // Link receipt to the new transaction
      await linkToTransaction(receiptId, transactionId);

      return Right(transactionId);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create transaction from receipt: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating transaction: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Filtered Queries
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Receipt>>> getUnlinkedReceipts(
    String userId,
  ) async {
    try {
      final entries = await _database.receiptsDao.getUnlinkedReceipts();
      final receipts = await Future.wait(
        entries.map((entry) => _entryToEntity(entry)),
      );
      return Right(receipts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get unlinked receipts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting unlinked receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Receipt>>> getReceiptsByStatus(
    String userId,
    ReceiptStatus status,
  ) async {
    try {
      List<ReceiptEntry> entries;
      switch (status) {
        case ReceiptStatus.pending:
          entries = await _database.receiptsDao.getPendingReceipts();
          break;
        case ReceiptStatus.extracted:
          entries = await _database.receiptsDao.getExtractedReceipts();
          break;
        default:
          entries = await _database.receiptsDao.getAllReceipts();
          entries = entries.where((e) => e.status == status.value).toList();
      }

      final receipts = await Future.wait(
        entries.map((entry) => _entryToEntity(entry)),
      );
      return Right(receipts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipts by status: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Receipt>>> getReceiptsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allEntries = await _database.receiptsDao.getAllReceipts();
      final filteredEntries = allEntries.where((entry) {
        final date = entry.receiptDate ?? entry.createdAt;
        return date.isAfter(startDate) && date.isBefore(endDate);
      }).toList();

      final receipts = await Future.wait(
        filteredEntries.map((entry) => _entryToEntity(entry)),
      );
      return Right(receipts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get receipts by date range: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Receipt>>> searchByMerchant(
    String userId,
    String query,
  ) async {
    try {
      final allEntries = await _database.receiptsDao.getAllReceipts();
      final lowercaseQuery = query.toLowerCase();

      final filteredEntries = allEntries.where((entry) {
        final merchantName = entry.merchantName?.toLowerCase() ?? '';
        return merchantName.contains(lowercaseQuery);
      }).toList();

      final receipts = await Future.wait(
        filteredEntries.map((entry) => _entryToEntity(entry)),
      );
      return Right(receipts);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search receipts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error searching receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<Receipt>>> watchReceipts(String userId) {
    return _database.receiptsDao.watchAllReceipts().asyncMap((entries) async {
      try {
        final receipts = await Future.wait(
          entries.map((entry) => _entryToEntity(entry)),
        );
        return Right<Failure, List<Receipt>>(receipts);
      } catch (e) {
        return Left<Failure, List<Receipt>>(
          CacheFailure(
            message: 'Error watching receipts: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  @override
  Stream<Either<Failure, List<Receipt>>> watchUnlinkedReceipts(String userId) {
    return _database.receiptsDao.watchAllReceipts().asyncMap((entries) async {
      try {
        final unlinkedEntries = entries.where((e) => e.transactionId == null);
        final receipts = await Future.wait(
          unlinkedEntries.map((entry) => _entryToEntity(entry)),
        );
        return Right<Failure, List<Receipt>>(receipts);
      } catch (e) {
        return Left<Failure, List<Receipt>>(
          CacheFailure(
            message: 'Error watching unlinked receipts: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync receipts from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteReceipts = await _remoteDataSource.getReceipts(userId);

      for (final model in remoteReceipts) {
        final existingEntry = await _database.receiptsDao.getReceiptById(
          model.id,
        );

        if (existingEntry == null) {
          await _database.receiptsDao.insertReceipt(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else if (model.createdAt.isAfter(existingEntry.createdAt)) {
          await _database.receiptsDao.updateReceipt(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync receipts from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing receipts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingReceipts = await _database.receiptsDao.getPendingSync();

      for (final entry in pendingReceipts) {
        final receipt = await _entryToEntity(entry);
        final model = ReceiptModel.fromEntity(receipt);

        // Upload image if local path exists but no URL
        if (entry.localPath != null && entry.imageUrl == null) {
          final file = File(entry.localPath!);
          if (await file.exists()) {
            final imageUrl = await _remoteDataSource.uploadReceiptImage(
              userId,
              entry.id,
              file,
            );
            await _database.receiptsDao.updateImageUrl(entry.id, imageUrl);
          }
        }

        await _remoteDataSource.updateReceipt(userId, model);
        await _database.receiptsDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync receipts to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing receipts: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing receipts: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OCR Parsing Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extract merchant name from OCR text (usually first few lines).
  String? _extractMerchantName(String rawText) {
    final lines = rawText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    // First non-empty line is often the merchant name
    // Filter out common noise like addresses, dates
    for (final line in lines.take(3)) {
      final trimmed = line.trim();
      // Skip lines that look like addresses or dates
      if (RegExp(r'^\d+[\s/]').hasMatch(trimmed)) continue;
      if (RegExp(r'\d{2}[/-]\d{2}[/-]\d{2,4}').hasMatch(trimmed)) continue;
      if (trimmed.length < 3) continue;

      return trimmed;
    }

    return lines.first.trim();
  }

  /// Extract total amount from OCR text.
  double? _extractTotalAmount(String rawText) {
    final lowercaseText = rawText.toLowerCase();

    // Common patterns for total
    final patterns = [
      RegExp(r'total[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'amount[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'sum[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'grand total[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'balance due[:\s]*\$?(\d+[.,]\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowercaseText);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(amountStr);
      }
    }

    // Fallback: find the largest amount on the receipt
    final amountPattern = RegExp(r'\$?(\d+[.,]\d{2})');
    final matches = amountPattern.allMatches(rawText);
    double? maxAmount;

    for (final match in matches) {
      final amountStr = match.group(1)!.replaceAll(',', '.');
      final amount = double.tryParse(amountStr);
      if (amount != null && (maxAmount == null || amount > maxAmount)) {
        maxAmount = amount;
      }
    }

    return maxAmount;
  }

  /// Extract tax amount from OCR text.
  double? _extractTaxAmount(String rawText) {
    final lowercaseText = rawText.toLowerCase();

    final patterns = [
      RegExp(r'tax[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'vat[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'gst[:\s]*\$?(\d+[.,]\d{2})'),
      RegExp(r'hst[:\s]*\$?(\d+[.,]\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowercaseText);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  /// Extract date from OCR text.
  DateTime? _extractDate(String rawText) {
    // Common date patterns
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        try {
          final g1 = int.parse(match.group(1)!);
          final g2 = int.parse(match.group(2)!);
          var g3 = int.parse(match.group(3)!);

          // Adjust 2-digit year
          if (g3 < 100) g3 += 2000;

          // Try different interpretations
          if (g1 > 31) {
            // YYYY-MM-DD
            return DateTime(g1, g2, g3);
          } else if (g1 > 12) {
            // DD-MM-YYYY
            return DateTime(g3, g2, g1);
          } else {
            // MM-DD-YYYY (US format)
            return DateTime(g3, g1, g2);
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  /// Extract line items from OCR text.
  List<ReceiptItem> _extractLineItems(String rawText) {
    final items = <ReceiptItem>[];
    final lines = rawText.split('\n');

    // Pattern: item name followed by price
    final itemPattern = RegExp(r'^(.+?)\s+\$?(\d+[.,]\d{2})\s*$');

    for (final line in lines) {
      final match = itemPattern.firstMatch(line.trim());
      if (match != null) {
        final name = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr);

        if (price != null && name.length > 1) {
          // Skip common non-item lines
          final lowerName = name.toLowerCase();
          if (lowerName.contains('total') ||
              lowerName.contains('subtotal') ||
              lowerName.contains('tax') ||
              lowerName.contains('change') ||
              lowerName.contains('cash') ||
              lowerName.contains('credit')) {
            continue;
          }

          items.add(
            ReceiptItem(
              name: name,
              quantity: 1.0,
              unitPrice: price,
              totalPrice: price,
            ),
          );
        }
      }
    }

    return items;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [ReceiptEntry] to domain [Receipt] entity.
  Future<Receipt> _entryToEntity(ReceiptEntry entry) async {
    // Get items for this receipt
    final itemEntries = await _database.receiptsDao.getReceiptItems(entry.id);
    final items = itemEntries
        .map(
          (item) => ReceiptItem(
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            totalPrice: item.totalPrice,
          ),
        )
        .toList();

    return Receipt(
      id: entry.id,
      transactionId: entry.transactionId,
      imageUrl: entry.imageUrl,
      localPath: entry.localPath,
      ocrRawText: entry.ocrRawText,
      ocrConfidence: entry.ocrConfidence,
      merchantName: entry.merchantName,
      totalAmount: entry.totalAmount,
      taxAmount: entry.taxAmount,
      receiptDate: entry.receiptDate,
      items: items,
      suggestedCategoryId: entry.suggestedCategoryId,
      status: ReceiptStatusExtension.fromString(entry.status),
      createdAt: entry.createdAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [Receipt] entity to Drift [ReceiptsCompanion].
  ReceiptsCompanion _entityToCompanion(Receipt entity) {
    return ReceiptsCompanion(
      id: Value(entity.id),
      transactionId: Value(entity.transactionId),
      imageUrl: Value(entity.imageUrl),
      localPath: Value(entity.localPath),
      ocrRawText: Value(entity.ocrRawText),
      ocrConfidence: Value(entity.ocrConfidence),
      merchantName: Value(entity.merchantName),
      totalAmount: Value(entity.totalAmount),
      taxAmount: Value(entity.taxAmount),
      receiptDate: Value(entity.receiptDate),
      suggestedCategoryId: Value(entity.suggestedCategoryId),
      status: Value(entity.status.value),
      createdAt: Value(entity.createdAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [ReceiptModel] to Drift [ReceiptsCompanion].
  ReceiptsCompanion _modelToCompanion(
    ReceiptModel model, {
    String syncStatus = 'pending',
  }) {
    return ReceiptsCompanion(
      id: Value(model.id),
      transactionId: Value(model.transactionId),
      imageUrl: Value(model.imageUrl),
      localPath: Value(model.localPath),
      ocrRawText: Value(model.ocrRawText),
      ocrConfidence: Value(model.ocrConfidence),
      merchantName: Value(model.merchantName),
      totalAmount: Value(model.totalAmount),
      taxAmount: Value(model.taxAmount),
      receiptDate: Value(model.receiptDate),
      suggestedCategoryId: Value(model.suggestedCategoryId),
      status: Value(model.status),
      createdAt: Value(model.createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  /// Dispose resources.
  void dispose() {
    _textRecognizer.close();
  }
}
