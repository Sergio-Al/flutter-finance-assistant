import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for processing receipt OCR.
///
/// Extracts text from receipt image and parses it.
///
/// ## Example Usage
/// ```dart
/// final useCase = ProcessReceiptOcrUseCase(receiptRepository);
///
/// final result = await useCase(
///   ProcessReceiptOcrParams(receiptId: 'receipt-123'),
/// );
///
/// result.fold(
///   (failure) => showError(failure.message),
///   (receipt) {
///     print('Merchant: ${receipt.merchantName}');
///     print('Total: \$${receipt.totalAmount}');
///   },
/// );
/// ```
class ProcessReceiptOcrUseCase
    extends UseCase<Receipt, ProcessReceiptOcrParams> {
  final ReceiptRepository repository;

  ProcessReceiptOcrUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(ProcessReceiptOcrParams params) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    return repository.processReceiptOcr(params.receiptId);
  }
}

/// Parameters for [ProcessReceiptOcrUseCase].
class ProcessReceiptOcrParams extends Equatable {
  final String receiptId;

  const ProcessReceiptOcrParams({required this.receiptId});

  @override
  List<Object?> get props => [receiptId];
}

/// Use case for reprocessing OCR on a receipt.
///
/// Useful when initial OCR failed or had low confidence.
class ReprocessReceiptOcrUseCase
    extends UseCase<Receipt, ReprocessReceiptOcrParams> {
  final ReceiptRepository repository;

  ReprocessReceiptOcrUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(
    ReprocessReceiptOcrParams params,
  ) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    return repository.reprocessOcr(params.receiptId);
  }
}

/// Parameters for [ReprocessReceiptOcrUseCase].
class ReprocessReceiptOcrParams extends Equatable {
  final String receiptId;

  const ReprocessReceiptOcrParams({required this.receiptId});

  @override
  List<Object?> get props => [receiptId];
}
