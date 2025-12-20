import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for linking a receipt to a transaction.
///
/// ## Example Usage
/// ```dart
/// final useCase = LinkReceiptToTransactionUseCase(receiptRepository);
///
/// final result = await useCase(
///   LinkReceiptToTransactionParams(
///     receiptId: 'receipt-123',
///     transactionId: 'transaction-456',
///   ),
/// );
/// ```
class LinkReceiptToTransactionUseCase
    extends UseCase<Receipt, LinkReceiptToTransactionParams> {
  final ReceiptRepository repository;

  LinkReceiptToTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(
    LinkReceiptToTransactionParams params,
  ) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    if (params.transactionId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Transaction ID is required',
          code: 'MISSING_TRANSACTION_ID',
        ),
      );
    }

    return repository.linkToTransaction(params.receiptId, params.transactionId);
  }
}

/// Parameters for [LinkReceiptToTransactionUseCase].
class LinkReceiptToTransactionParams extends Equatable {
  final String receiptId;
  final String transactionId;

  const LinkReceiptToTransactionParams({
    required this.receiptId,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [receiptId, transactionId];
}

/// Use case for unlinking a receipt from a transaction.
class UnlinkReceiptFromTransactionUseCase
    extends UseCase<Receipt, UnlinkReceiptFromTransactionParams> {
  final ReceiptRepository repository;

  UnlinkReceiptFromTransactionUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(
    UnlinkReceiptFromTransactionParams params,
  ) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    return repository.unlinkFromTransaction(params.receiptId);
  }
}

/// Parameters for [UnlinkReceiptFromTransactionUseCase].
class UnlinkReceiptFromTransactionParams extends Equatable {
  final String receiptId;

  const UnlinkReceiptFromTransactionParams({required this.receiptId});

  @override
  List<Object?> get props => [receiptId];
}

/// Use case for creating a transaction from receipt data.
///
/// Creates a new transaction based on the extracted receipt data.
class CreateTransactionFromReceiptUseCase
    extends UseCase<String, CreateTransactionFromReceiptParams> {
  final ReceiptRepository repository;

  CreateTransactionFromReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(
    CreateTransactionFromReceiptParams params,
  ) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    if (params.accountId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Account ID is required',
          code: 'MISSING_ACCOUNT_ID',
        ),
      );
    }

    if (params.categoryId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Category ID is required',
          code: 'MISSING_CATEGORY_ID',
        ),
      );
    }

    return repository.createTransactionFromReceipt(
      params.receiptId,
      params.accountId,
      params.categoryId,
    );
  }
}

/// Parameters for [CreateTransactionFromReceiptUseCase].
class CreateTransactionFromReceiptParams extends Equatable {
  final String receiptId;
  final String accountId;
  final String categoryId;

  const CreateTransactionFromReceiptParams({
    required this.receiptId,
    required this.accountId,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [receiptId, accountId, categoryId];
}
