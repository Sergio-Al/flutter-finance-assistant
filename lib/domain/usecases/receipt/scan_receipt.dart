import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for scanning/uploading a receipt image.
///
/// Uploads the image to storage and creates a receipt record.
///
/// ## Example Usage
/// ```dart
/// final useCase = ScanReceiptUseCase(receiptRepository);
///
/// // From camera/gallery bytes
/// final result = await useCase(
///   ScanReceiptParams.fromBytes(
///     userId: 'user-123',
///     imageBytes: capturedImageBytes,
///     fileName: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
///   ),
/// );
///
/// // Or from file path
/// final result = await useCase(
///   ScanReceiptParams.fromPath(
///     userId: 'user-123',
///     filePath: '/path/to/receipt.jpg',
///   ),
/// );
/// ```
class ScanReceiptUseCase extends UseCase<Receipt, ScanReceiptParams> {
  final ReceiptRepository repository;

  ScanReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(ScanReceiptParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    // Must have either bytes or file path
    if (params.imageBytes == null && params.filePath == null) {
      return const Left(
        ValidationFailure(
          message: 'Image data or file path is required',
          code: 'MISSING_IMAGE_DATA',
        ),
      );
    }

    // Upload from bytes
    if (params.imageBytes != null) {
      if (params.imageBytes!.isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Image data cannot be empty',
            code: 'EMPTY_IMAGE_DATA',
          ),
        );
      }

      final fileName =
          params.fileName ??
          'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return repository.uploadReceiptImage(
        userId: params.userId,
        imageBytes: params.imageBytes!,
        fileName: fileName,
      );
    }

    // Upload from file path
    return repository.uploadReceiptFromPath(
      userId: params.userId,
      filePath: params.filePath!,
    );
  }
}

/// Parameters for [ScanReceiptUseCase].
class ScanReceiptParams extends Equatable {
  final String userId;
  final Uint8List? imageBytes;
  final String? fileName;
  final String? filePath;

  const ScanReceiptParams({
    required this.userId,
    this.imageBytes,
    this.fileName,
    this.filePath,
  });

  /// Create params from image bytes
  factory ScanReceiptParams.fromBytes({
    required String userId,
    required Uint8List imageBytes,
    String? fileName,
  }) {
    return ScanReceiptParams(
      userId: userId,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  /// Create params from file path
  factory ScanReceiptParams.fromPath({
    required String userId,
    required String filePath,
  }) {
    return ScanReceiptParams(userId: userId, filePath: filePath);
  }

  @override
  List<Object?> get props => [userId, imageBytes, fileName, filePath];
}
