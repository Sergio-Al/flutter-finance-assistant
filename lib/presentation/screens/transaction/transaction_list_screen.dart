import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/domain/usecases/transaction/get_spending_summary.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_state.dart';
import 'package:flutter_finance_assistant/presentation/screens/transaction/widgets/transaction_widgets.dart';

/// Screen displaying list of transactions with filtering, search, and actions.
///
/// Features:
/// - Summary card with income/expense/balance
/// - Filter bar with type, category, date filters
/// - Grouped transactions by date
/// - Pull-to-refresh
/// - Bulk selection mode
/// - FAB for creating new transactions
class TransactionListScreen extends StatelessWidget {
  final String accountId;

  const TransactionListScreen({
    super.key,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TransactionBloc>()
        ..add(
          TransactionWatchRequested(accountId: accountId),
        ),
      child: _TransactionListView(accountId: accountId),
    );
  }
}

class _TransactionListView extends StatefulWidget {
  final String accountId;

  const _TransactionListView({required this.accountId});

  @override
  State<_TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<_TransactionListView> {
  // Filter state
  TransactionType? _selectedType;
  String? _selectedCategoryId;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  // Bulk selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, theme, isDark),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return switch (state) {
            TransactionInitial() => const SizedBox.shrink(),
            TransactionLoading() => _buildLoadingState(),
            TransactionLoaded(:final transactions, :final summary) =>
              _buildLoadedState(context, transactions, summary, isDark),
            TransactionError(:final message) => _buildErrorState(message),
            _ => _buildLoadingState(),
          };
        },
      ),
      floatingActionButton: _isSelectionMode ? null : _buildFAB(context),
      bottomSheet: _isSelectionMode ? _buildBulkActionsBar(context) : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        title: Text(
          '${_selectedTransactionIds.length} selected',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              'Select All',
              style: TextStyle(color: AppTheme.primaryLight),
            ),
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Text(
        'Transactions',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Export button
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: () => _showExportSheet(context),
          tooltip: 'Export',
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Select items'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('View analytics'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: TransactionSkeletonLoader(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.expense,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    List<Transaction> transactions,
    SpendingSummary? summary,
    bool isDark,
  ) {
    // Apply filters
    final filtered = _applyFilters(transactions);

    // Calculate quick stats
    final quickStats = _buildQuickStats(transactions);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: CustomScrollView(
        slivers: [
          // Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TransactionSummaryCard(summary: summary),
            ),
          ),

          // Quick Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TransactionQuickStatsRow(
                stats: quickStats,
                scrollable: false,
              ),
            ),
          ),

          // Filter Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TransactionFilterBar(
                selectedType: _selectedType,
                selectedCategoryId: _selectedCategoryId,
                selectedDateRange: _selectedDateRange,
                searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                onTypeChanged: (type) => setState(() => _selectedType = type),
                onCategoryChanged: (id) =>
                    setState(() => _selectedCategoryId = id),
                onDateRangeChanged: (range) =>
                    setState(() => _selectedDateRange = range),
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
                onClearFilters: _clearFilters,
              ),
            ),
          ),

          // Transactions List
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: TransactionEmptyState(
                type: _hasActiveFilters
                    ? EmptyStateType.noSearchResults
                    : EmptyStateType.noTransactions,
                onActionPressed: _hasActiveFilters ? _clearFilters : null,
              ),
            )
          else
            ..._buildTransactionSlivers(context, filtered, isDark),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 88),
          ),
        ],
      ),
    );
  }

  List<QuickStat> _buildQuickStats(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return [
        QuickStatsFactory.totalTransactions(count: 0),
        QuickStatsFactory.avgDailySpend(amount: 0),
      ];
    }

    // Calculate stats
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final totalExpense = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final biggestExpense = expenses.isEmpty
        ? 0.0
        : expenses.reduce((a, b) => a.amount > b.amount ? a : b).amount;

    // Days in period
    final dates = transactions.map((t) => t.date).toList();
    dates.sort();
    final daysDiff = dates.isNotEmpty
        ? dates.last.difference(dates.first).inDays + 1
        : 1;
    final avgDaily = totalExpense / daysDiff;

    return [
      QuickStatsFactory.totalTransactions(count: transactions.length),
      QuickStatsFactory.avgDailySpend(amount: avgDaily),
      if (biggestExpense > 0)
        QuickStatsFactory.biggestExpense(amount: biggestExpense),
    ];
  }

  List<Widget> _buildTransactionSlivers(
    BuildContext context,
    List<Transaction> transactions,
    bool isDark,
  ) {
    // Group by date
    final grouped = _groupByDate(transactions);
    final slivers = <Widget>[];

    for (final entry in grouped.entries) {
      // Date header
      slivers.add(
        SliverTransactionDateHeader(
          date: entry.key,
          transactionCount: entry.value.length,
          totalAmount: entry.value.fold<double>(
            0.0,
            (sum, t) => sum + t.signedAmount,
          ),
        ),
      );

      // Transactions for this date
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final transaction = entry.value[index];
                final isSelected =
                    _selectedTransactionIds.contains(transaction.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTransactionItem(
                    context,
                    transaction,
                    isSelected,
                    isDark,
                  ),
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction transaction,
    bool isSelected,
    bool isDark,
  ) {
    return Stack(
      children: [
        TransactionItemCard(
          transaction: transaction,
          showDate: false,
          onTap: () => _isSelectionMode
              ? _toggleSelection(transaction.id)
              : _openTransactionDetail(context, transaction),
          onLongPress: () => _enterSelectionMode(transaction.id),
        ),
        // Selection indicator
        if (_isSelectionMode)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryLight : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : isDark
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        // Recurring badge
        if (transaction.isRecurring)
          Positioned(
            right: 8,
            top: 8,
            child: RecurringIndicator(
              isRecurring: transaction.isRecurring,
              size: 14,
            ),
          ),
        // AI suggestion indicator
        if (transaction.isMediumConfidence || transaction.isLowConfidence)
          Positioned(
            right: 8,
            bottom: 8,
            child: AiSuggestionBadge(
              confidence: transaction.aiCategoryConfidence ?? 0,
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING ACTION BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'transaction_list_fab',
      onPressed: () => _showCreateSheet(context),
      backgroundColor: AppTheme.primaryLight,
      child: const Icon(Icons.add),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK ACTIONS BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBulkActionsBar(BuildContext context) {
    return TransactionBulkActionsBar(
      selectedCount: _selectedTransactionIds.length,
      onCategorize: () => _bulkCategorize(context),
      onDelete: () => _bulkDelete(context),
      onExport: () => _showExportSheet(context),
      onClose: _clearSelection,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get _hasActiveFilters =>
      _selectedType != null ||
      _selectedCategoryId != null ||
      _selectedDateRange != null ||
      _searchQuery.isNotEmpty;

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    var result = transactions;

    if (_selectedType != null) {
      result = result.where((t) => t.type == _selectedType).toList();
    }

    if (_selectedCategoryId != null) {
      result = result.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    if (_selectedDateRange != null) {
      result = result.where((t) {
        return t.date.isAfter(_selectedDateRange!.start) &&
            t.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        final descMatch = t.description?.toLowerCase().contains(query) ?? false;
        final tagMatch = t.tags.any((tag) => tag.toLowerCase().contains(query));
        final locMatch = t.location?.toLowerCase().contains(query) ?? false;
        return descMatch || tagMatch || locMatch;
      }).toList();
    }

    // Sort by date descending
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <DateTime, List<Transaction>>{};

    for (final transaction in transactions) {
      final dateKey = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategoryId = null;
      _selectedDateRange = null;
      _searchQuery = '';
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTION
  // ═══════════════════════════════════════════════════════════════════════════

  void _enterSelectionMode(String transactionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactionIds.add(transactionId);
    });
  }

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _selectAll() {
    final state = context.read<TransactionBloc>().state;
    if (state is TransactionLoaded) {
      setState(() {
        _selectedTransactionIds.addAll(
          state.transactions.map((t) => t.id),
        );
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleStateChanges(BuildContext context, TransactionState state) {
    if (state is TransactionOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.income,
        ),
      );
      _clearSelection();
    } else if (state is TransactionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.expense,
        ),
      );
    }
  }

  void _refresh() {
    final now = DateTime.now();
    context.read<TransactionBloc>().add(
      TransactionLoadRequested(
        accountId: widget.accountId,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'select':
        setState(() => _isSelectionMode = true);
        break;
      case 'analytics':
        // TODO: Navigate to analytics screen
        break;
    }
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: CreateTransactionSheet(accountId: widget.accountId),
      ),
    );

    if (result != null) {
      _refresh();
    }
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final state = context.read<TransactionBloc>().state;
    final transactionCount = state is TransactionLoaded
        ? state.transactions.length
        : 0;

    await TransactionExportSheet.show(
      context,
      transactionCount: transactionCount,
      onExport: (config) {
        // TODO: Handle export with config
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exporting as ${config.format.label}...'),
          ),
        );
      },
    );
  }

  void _openTransactionDetail(BuildContext context, Transaction transaction) {
    EditTransactionSheet.show(
      context,
      transaction: transaction,
      categories: const ['Food', 'Transport', 'Shopping', 'Bills', 'Other'],
      onSave: (updatedTransaction) {
        context.read<TransactionBloc>().add(
          TransactionUpdateRequested(transaction: updatedTransaction),
        );
        Navigator.pop(context);
      },
      onDelete: () {
        context.read<TransactionBloc>().add(
          TransactionDeleteRequested(transactionId: transaction.id),
        );
        Navigator.pop(context);
      },
    );
  }

  Future<void> _bulkCategorize(BuildContext context) async {
    await BulkCategorizeSheet.show(
      context,
      selectedCount: _selectedTransactionIds.length,
      categories: const ['Food', 'Transport', 'Shopping', 'Bills', 'Other'],
      onCategorySelected: (category) {
        // TODO: Update transactions with new category
        _clearSelection();
      },
    );
  }

  Future<void> _bulkDelete(BuildContext context) async {
    final confirmed = await BulkDeleteConfirmDialog.show(
      context,
      selectedCount: _selectedTransactionIds.length,
    );

    if (confirmed == true) {
      for (final id in _selectedTransactionIds) {
        context.read<TransactionBloc>().add(
          TransactionDeleteRequested(transactionId: id),
        );
      }
      _clearSelection();
    }
  }
}
