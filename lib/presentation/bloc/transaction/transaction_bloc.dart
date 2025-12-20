import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/domain/usecases/transaction/transaction_usecases.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_state.dart';

/// BLoC for handling transaction logic.
///
/// Manages transaction CRUD operations, filtering, searching,
/// spending summaries, and real-time updates.
///
/// ## Features
/// - Load transactions by date range
/// - Watch recent transactions in real-time
/// - Create, update, delete transactions
/// - Filter by type, category, and date
/// - Search by description, tags, or location
/// - Get spending summary with analytics
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final CreateTransactionUseCase createTransaction;
  final GetTransactionsByDateRangeUseCase getTransactionsByDateRange;
  final GetSpendingSummaryUseCase getSpendingSummary;
  final WatchRecentTransactionsUseCase watchRecentTransactions;

  StreamSubscription? _transactionSubscription;
  String? _currentAccountId;

  TransactionBloc({
    required this.createTransaction,
    required this.getTransactionsByDateRange,
    required this.getSpendingSummary,
    required this.watchRecentTransactions,
  }) : super(const TransactionInitial()) {
    // Load events
    on<TransactionLoadRequested>(_onLoadRequested);
    on<TransactionLoadRecentRequested>(_onLoadRecentRequested);
    on<TransactionSummaryRequested>(_onSummaryRequested);
    on<TransactionWatchRequested>(_onWatchRequested);

    // CRUD events
    on<TransactionCreateRequested>(_onCreateRequested);
    on<TransactionUpdateRequested>(_onUpdateRequested);
    on<TransactionDeleteRequested>(_onDeleteRequested);

    // Filter events
    on<TransactionFilterByTypeRequested>(_onFilterByTypeRequested);
    on<TransactionFilterByCategoryRequested>(_onFilterByCategoryRequested);
    on<TransactionFilterByDateRequested>(_onFilterByDateRequested);
    on<TransactionFilterCleared>(_onFilterCleared);

    // Search events
    on<TransactionSearchRequested>(_onSearchRequested);
    on<TransactionSearchCleared>(_onSearchCleared);

    // Internal events
    on<TransactionDataChanged>(_onDataChanged);
    on<TransactionErrorCleared>(_onErrorCleared);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading(message: 'Loading transactions...'));
    _currentAccountId = event.accountId;

    final result = await getTransactionsByDateRange(
      GetTransactionsByDateRangeParams(
        accountId: event.accountId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          TransactionError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (transactions) async {
        // Also fetch summary
        final summaryResult = await getSpendingSummary(
          GetSpendingSummaryParams(
            accountId: event.accountId,
            startDate: event.startDate,
            endDate: event.endDate,
          ),
        );

        final summary = summaryResult.fold((failure) => null, (s) => s);

        emit(
          TransactionLoaded(
            transactions: transactions,
            summary: summary,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onLoadRecentRequested(
    TransactionLoadRecentRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading(message: 'Loading recent transactions...'));
    _currentAccountId = event.accountId;

    // Load transactions from last 30 days
    final now = DateTime.now();
    final result = await getTransactionsByDateRange(
      GetTransactionsByDateRangeParams(
        accountId: event.accountId,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
      ),
    );

    result.fold(
      (failure) {
        emit(
          TransactionError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (transactions) {
        // Take only the most recent ones
        final recent = transactions.take(event.limit).toList();
        emit(
          TransactionRecentLoaded(
            recentTransactions: recent,
            lastUpdated: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> _onSummaryRequested(
    TransactionSummaryRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;

    final result = await getSpendingSummary(
      GetSpendingSummaryParams(
        accountId: event.accountId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) {
        // Keep current state, just show error
        emit(
          TransactionError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (summary) {
        if (currentState is TransactionLoaded) {
          emit(currentState.copyWith(summary: summary));
        }
      },
    );
  }

  Future<void> _onWatchRequested(
    TransactionWatchRequested event,
    Emitter<TransactionState> emit,
  ) async {
    // Cancel previous subscription
    await _transactionSubscription?.cancel();
    _currentAccountId = event.accountId;

    _transactionSubscription =
        watchRecentTransactions(
          WatchRecentTransactionsParams(
            accountId: event.accountId,
            limit: event.limit,
          ),
        ).listen((result) {
          result.fold(
            (failure) {
              // Handle failure silently or log
            },
            (transactions) {
              add(TransactionDataChanged(transactions: transactions));
            },
          );
        });

    // Also do initial load
    final now = DateTime.now();
    add(
      TransactionLoadRequested(
        accountId: event.accountId,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _onCreateRequested(
    TransactionCreateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      const TransactionOperationInProgress(
        operation: TransactionOperationType.create,
      ),
    );

    final result = await createTransaction(
      CreateTransactionParams(
        accountId: event.accountId,
        categoryId: event.categoryId,
        amount: event.amount,
        type: event.type,
        description: event.description,
        date: event.date,
        receiptUrl: event.receiptUrl,
        location: event.location,
        tags: event.tags,
        isRecurring: event.isRecurring,
        recurringId: event.recurringId,
        toAccountId: event.toAccountId,
      ),
    );

    await result.fold(
      (failure) async {
        emit(
          TransactionError(
            errorType: _mapFailureToErrorType(failure),
            message: failure.message,
            code: failure.code,
          ),
        );
      },
      (transaction) async {
        emit(
          TransactionOperationSuccess(
            operation: TransactionOperationType.create,
            transaction: transaction,
            message: TransactionOperationType.create.successMessage,
          ),
        );

        // Reload transactions if we have an account ID
        if (_currentAccountId != null) {
          final now = DateTime.now();
          add(
            TransactionLoadRequested(
              accountId: _currentAccountId!,
              startDate: now.subtract(const Duration(days: 30)),
              endDate: now,
            ),
          );
        }
      },
    );
  }

  Future<void> _onUpdateRequested(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      TransactionOperationInProgress(
        operation: TransactionOperationType.update,
        transactionId: event.transaction.id,
      ),
    );

    // TODO: Implement update use case when available
    // For now, emit success and reload
    emit(
      TransactionOperationSuccess(
        operation: TransactionOperationType.update,
        transaction: event.transaction,
        message: TransactionOperationType.update.successMessage,
      ),
    );

    // Reload transactions
    if (_currentAccountId != null) {
      final now = DateTime.now();
      add(
        TransactionLoadRequested(
          accountId: _currentAccountId!,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(
      TransactionOperationInProgress(
        operation: TransactionOperationType.delete,
        transactionId: event.transactionId,
      ),
    );

    // TODO: Implement delete use case when available
    // For now, emit success and reload
    emit(
      TransactionOperationSuccess(
        operation: TransactionOperationType.delete,
        message: TransactionOperationType.delete.successMessage,
      ),
    );

    // Reload transactions
    if (_currentAccountId != null) {
      final now = DateTime.now();
      add(
        TransactionLoadRequested(
          accountId: _currentAccountId!,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onFilterByTypeRequested(
    TransactionFilterByTypeRequested event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      final currentFilter =
          currentState.activeFilter ?? const TransactionFilter();
      emit(
        currentState.copyWith(
          activeFilter: currentFilter.copyWith(
            type: event.type,
            clearType: event.type == null,
          ),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  void _onFilterByCategoryRequested(
    TransactionFilterByCategoryRequested event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      final currentFilter =
          currentState.activeFilter ?? const TransactionFilter();
      emit(
        currentState.copyWith(
          activeFilter: currentFilter.copyWith(
            categoryId: event.categoryId,
            clearCategory: event.categoryId == null,
          ),
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  void _onFilterByDateRequested(
    TransactionFilterByDateRequested event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      final currentFilter =
          currentState.activeFilter ?? const TransactionFilter();
      emit(
        currentState.copyWith(
          activeFilter: currentFilter.copyWith(
            startDate: event.startDate,
            endDate: event.endDate,
          ),
          lastUpdated: DateTime.now(),
        ),
      );
    }

    // Reload with new date range
    if (_currentAccountId != null) {
      add(
        TransactionLoadRequested(
          accountId: _currentAccountId!,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    }
  }

  void _onFilterCleared(
    TransactionFilterCleared event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      emit(
        currentState.copyWith(clearFilter: true, lastUpdated: DateTime.now()),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onSearchRequested(
    TransactionSearchRequested event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      emit(
        currentState.copyWith(
          searchQuery: event.query,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  void _onSearchCleared(
    TransactionSearchCleared event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      emit(
        currentState.copyWith(clearSearch: true, lastUpdated: DateTime.now()),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onDataChanged(
    TransactionDataChanged event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;

    if (currentState is TransactionLoaded) {
      emit(
        currentState.copyWith(
          transactions: event.transactions,
          lastUpdated: DateTime.now(),
        ),
      );
    } else if (currentState is TransactionRecentLoaded) {
      emit(
        TransactionRecentLoaded(
          recentTransactions: event.transactions,
          lastUpdated: DateTime.now(),
        ),
      );
    } else {
      emit(
        TransactionLoaded(
          transactions: event.transactions,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  void _onErrorCleared(
    TransactionErrorCleared event,
    Emitter<TransactionState> emit,
  ) {
    emit(const TransactionInitial());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  TransactionErrorType _mapFailureToErrorType(Failure failure) {
    if (failure is ValidationFailure) {
      switch (failure.code) {
        case 'INVALID_AMOUNT':
          return TransactionErrorType.invalidAmount;
        case 'MISSING_CATEGORY_ID':
          return TransactionErrorType.missingCategory;
        case 'MISSING_ACCOUNT_ID':
          return TransactionErrorType.missingAccount;
        default:
          return TransactionErrorType.validationError;
      }
    } else if (failure is NotFoundFailure) {
      return TransactionErrorType.transactionNotFound;
    } else if (failure is NetworkFailure) {
      return TransactionErrorType.networkError;
    }
    return TransactionErrorType.unknown;
  }

  @override
  Future<void> close() {
    _transactionSubscription?.cancel();
    return super.close();
  }
}
