import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for deleting a receipt.
///
/// Removes both the receipt record and the image from storage.
class DeleteReceiptUseCase extends UseCase<void, DeleteReceiptParams> {
  final ReceiptRepository repository;

  DeleteReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteReceiptParams params) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    // Delete image first, then receipt record
    final imageResult = await repository.deleteReceiptImage(params.receiptId);
    if (imageResult.isLeft()) {
      // Log but continue - receipt record should still be deleted
    }

    return repository.deleteReceipt(params.receiptId);
  }
}

/// Parameters for [DeleteReceiptUseCase].
class DeleteReceiptParams extends Equatable {
  final String receiptId;

  const DeleteReceiptParams({required this.receiptId});

  @override
  List<Object?> get props => [receiptId];
}

/// Use case for updating a receipt.
class UpdateReceiptUseCase extends UseCase<Receipt, UpdateReceiptParams> {
  final ReceiptRepository repository;

  UpdateReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(UpdateReceiptParams params) async {
    if (params.receipt.id.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    return repository.updateReceipt(params.receipt);
  }
}

/// Parameters for [UpdateReceiptUseCase].
class UpdateReceiptParams extends Equatable {
  final Receipt receipt;

  const UpdateReceiptParams({required this.receipt});

  @override
  List<Object?> get props => [receipt];
}

/// Use case for watching receipts in real-time.
class WatchReceiptsUseCase
    extends StreamUseCase<List<Receipt>, WatchReceiptsParams> {
  final ReceiptRepository repository;

  WatchReceiptsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Receipt>>> call(WatchReceiptsParams params) {
    if (params.userId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            code: 'MISSING_USER_ID',
          ),
        ),
      );
    }

    return repository.watchReceipts(params.userId);
  }
}

/// Parameters for [WatchReceiptsUseCase].
class WatchReceiptsParams extends Equatable {
  final String userId;

  const WatchReceiptsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for watching unlinked receipts.
///
/// Useful for showing notifications about receipts needing attention.
class WatchUnlinkedReceiptsUseCase
    extends StreamUseCase<List<Receipt>, WatchUnlinkedReceiptsParams> {
  final ReceiptRepository repository;

  WatchUnlinkedReceiptsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<Receipt>>> call(
    WatchUnlinkedReceiptsParams params,
  ) {
    if (params.userId.isEmpty) {
      return Stream.value(
        const Left(
          ValidationFailure(
            message: 'User ID is required',
            code: 'MISSING_USER_ID',
          ),
        ),
      );
    }

    return repository.watchUnlinkedReceipts(params.userId);
  }
}

/// Parameters for [WatchUnlinkedReceiptsUseCase].
class WatchUnlinkedReceiptsParams extends Equatable {
  final String userId;

  const WatchUnlinkedReceiptsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
