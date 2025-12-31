import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';

/// Filter bar for transactions with type, category, and date filters.
class TransactionFilterBar extends StatelessWidget {
  final TransactionType? selectedType;
  final String? selectedCategoryId;
  final DateTimeRange? selectedDateRange;
  final String? searchQuery;
  final ValueChanged<TransactionType?>? onTypeChanged;
  final ValueChanged<String?>? onCategoryChanged;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearFilters;

  const TransactionFilterBar({
    super.key,
    this.selectedType,
    this.selectedCategoryId,
    this.selectedDateRange,
    this.searchQuery,
    this.onTypeChanged,
    this.onCategoryChanged,
    this.onDateRangeChanged,
    this.onSearchChanged,
    this.onClearFilters,
  });

  bool get hasActiveFilters =>
      selectedType != null ||
      selectedCategoryId != null ||
      selectedDateRange != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search Bar
        if (onSearchChanged != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SearchField(
              query: searchQuery,
              onChanged: onSearchChanged!,
              isDark: isDark,
            ),
          ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Type Filter
              _TypeFilterChip(
                selectedType: selectedType,
                onChanged: onTypeChanged,
                isDark: isDark,
              ),
              const SizedBox(width: 8),

              // Date Filter
              _DateFilterChip(
                selectedRange: selectedDateRange,
                onChanged: onDateRangeChanged,
                isDark: isDark,
              ),
              const SizedBox(width: 8),

              // Clear Filters
              if (hasActiveFilters)
                _ClearFiltersChip(onClear: onClearFilters, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final String? query;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _SearchField({
    this.query,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: query),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search transactions...',
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          size: 20,
        ),
        suffixIcon: query?.isNotEmpty == true
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  size: 18,
                ),
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final TransactionType? selectedType;
  final ValueChanged<TransactionType?>? onChanged;
  final bool isDark;

  const _TypeFilterChip({
    this.selectedType,
    this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TransactionType?>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Types')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: TransactionType.expense,
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Expenses'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TransactionType.income,
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 18, color: Colors.green),
              SizedBox(width: 8),
              Text('Income'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: TransactionType.transfer,
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text('Transfers'),
            ],
          ),
        ),
      ],
      child: _FilterChip(
        label: selectedType?.displayName ?? 'All Types',
        icon: _getTypeIcon(selectedType),
        isActive: selectedType != null,
        isDark: isDark,
      ),
    );
  }

  IconData _getTypeIcon(TransactionType? type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.filter_list;
    }
  }
}

class _DateFilterChip extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?>? onChanged;
  final bool isDark;

  const _DateFilterChip({
    this.selectedRange,
    this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: _FilterChip(
        label: _getDateLabel(),
        icon: Icons.calendar_today,
        isActive: selectedRange != null,
        isDark: isDark,
      ),
    );
  }

  String _getDateLabel() {
    if (selectedRange == null) return 'Date';

    final start = selectedRange!.start;
    final end = selectedRange!.end;

    // Check for common ranges
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (start == DateTime(now.year, now.month, 1) &&
        end == DateTime(now.year, now.month + 1, 0)) {
      return 'This Month';
    }

    if (start == today.subtract(const Duration(days: 7)) && end == today) {
      return 'Last 7 Days';
    }

    if (start == today.subtract(const Duration(days: 30)) && end == today) {
      return 'Last 30 Days';
    }

    return '${_formatShortDate(start)} - ${_formatShortDate(end)}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          selectedRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryLight),
          ),
          child: child!,
        );
      },
    );

    onChanged?.call(result);
  }
}

class _ClearFiltersChip extends StatelessWidget {
  final VoidCallback? onClear;
  final bool isDark;

  const _ClearFiltersChip({this.onClear, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: AppTheme.error),
            const SizedBox(width: 4),
            Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryLight.withValues(alpha: 0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryLight.withValues(alpha: 0.3)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive
                ? AppTheme.primaryLight
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? AppTheme.primaryLight
                  : (isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isActive
                ? AppTheme.primaryLight
                : (isDark ? Colors.grey[500] : Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
