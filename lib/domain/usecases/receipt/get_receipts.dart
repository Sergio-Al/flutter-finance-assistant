import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/entities/receipt.dart';
import 'package:flutter_finance_assistant/domain/repositories/receipt_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/usecase.dart';

/// Use case for getting all receipts for a user.
class GetReceiptsUseCase extends UseCase<List<Receipt>, GetReceiptsParams> {
  final ReceiptRepository repository;

  GetReceiptsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(GetReceiptsParams params) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getReceipts(params.userId);
  }
}

/// Parameters for [GetReceiptsUseCase].
class GetReceiptsParams extends Equatable {
  final String userId;

  const GetReceiptsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting a receipt by ID.
class GetReceiptByIdUseCase extends UseCase<Receipt, GetReceiptByIdParams> {
  final ReceiptRepository repository;

  GetReceiptByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(GetReceiptByIdParams params) async {
    if (params.receiptId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Receipt ID is required',
          code: 'MISSING_RECEIPT_ID',
        ),
      );
    }

    return repository.getReceiptById(params.receiptId);
  }
}

/// Parameters for [GetReceiptByIdUseCase].
class GetReceiptByIdParams extends Equatable {
  final String receiptId;

  const GetReceiptByIdParams({required this.receiptId});

  @override
  List<Object?> get props => [receiptId];
}

/// Use case for getting unlinked receipts.
///
/// Returns receipts that haven't been linked to any transaction yet.
class GetUnlinkedReceiptsUseCase
    extends UseCase<List<Receipt>, GetUnlinkedReceiptsParams> {
  final ReceiptRepository repository;

  GetUnlinkedReceiptsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(
    GetUnlinkedReceiptsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getUnlinkedReceipts(params.userId);
  }
}

/// Parameters for [GetUnlinkedReceiptsUseCase].
class GetUnlinkedReceiptsParams extends Equatable {
  final String userId;

  const GetUnlinkedReceiptsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Use case for getting receipts by status.
class GetReceiptsByStatusUseCase
    extends UseCase<List<Receipt>, GetReceiptsByStatusParams> {
  final ReceiptRepository repository;

  GetReceiptsByStatusUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(
    GetReceiptsByStatusParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    return repository.getReceiptsByStatus(params.userId, params.status);
  }
}

/// Parameters for [GetReceiptsByStatusUseCase].
class GetReceiptsByStatusParams extends Equatable {
  final String userId;
  final ReceiptStatus status;

  const GetReceiptsByStatusParams({required this.userId, required this.status});

  @override
  List<Object?> get props => [userId, status];
}

/// Use case for getting receipts within a date range.
class GetReceiptsByDateRangeUseCase
    extends UseCase<List<Receipt>, GetReceiptsByDateRangeParams> {
  final ReceiptRepository repository;

  GetReceiptsByDateRangeUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(
    GetReceiptsByDateRangeParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.startDate.isAfter(params.endDate)) {
      return const Left(
        ValidationFailure(
          message: 'Start date must be before or equal to end date',
          code: 'INVALID_DATE_RANGE',
        ),
      );
    }

    return repository.getReceiptsByDateRange(
      params.userId,
      params.startDate,
      params.endDate,
    );
  }
}

/// Parameters for [GetReceiptsByDateRangeUseCase].
class GetReceiptsByDateRangeParams extends Equatable {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const GetReceiptsByDateRangeParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Use case for searching receipts by merchant name.
class SearchReceiptsByMerchantUseCase
    extends UseCase<List<Receipt>, SearchReceiptsByMerchantParams> {
  final ReceiptRepository repository;

  SearchReceiptsByMerchantUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(
    SearchReceiptsByMerchantParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'User ID is required',
          code: 'MISSING_USER_ID',
        ),
      );
    }

    if (params.query.trim().isEmpty) {
      // Return all receipts if query is empty
      return repository.getReceipts(params.userId);
    }

    return repository.searchByMerchant(params.userId, params.query.trim());
  }
}

/// Parameters for [SearchReceiptsByMerchantUseCase].
class SearchReceiptsByMerchantParams extends Equatable {
  final String userId;
  final String query;

  const SearchReceiptsByMerchantParams({
    required this.userId,
    required this.query,
  });

  @override
  List<Object?> get props => [userId, query];
}
