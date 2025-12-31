import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Sheet for splitting a transaction into multiple categories.
class TransactionSplitSheet extends StatefulWidget {
  final String transactionId;
  final double totalAmount;
  final String? originalCategory;
  final String? description;
  final List<String> categories;
  final Function(List<SplitItem> splits) onSave;

  const TransactionSplitSheet({
    super.key,
    required this.transactionId,
    required this.totalAmount,
    this.originalCategory,
    this.description,
    required this.categories,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String transactionId,
    required double totalAmount,
    String? originalCategory,
    String? description,
    required List<String> categories,
    required Function(List<SplitItem> splits) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionSplitSheet(
        transactionId: transactionId,
        totalAmount: totalAmount,
        originalCategory: originalCategory,
        description: description,
        categories: categories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TransactionSplitSheet> createState() => _TransactionSplitSheetState();
}

class _TransactionSplitSheetState extends State<TransactionSplitSheet> {
  late List<SplitItem> _splits;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Initialize with original category if available
    _splits = [
      SplitItem(
        category: widget.originalCategory ?? widget.categories.first,
        amount: widget.totalAmount,
      ),
    ];
    _validateSplits();
  }

  void _addSplit() {
    setState(() {
      // Find remaining amount
      final usedAmount = _splits.fold<double>(
        0,
        (sum, split) => sum + split.amount,
      );
      final remainingAmount = widget.totalAmount - usedAmount;

      _splits.add(
        SplitItem(
          category: widget.categories.first,
          amount: remainingAmount > 0 ? remainingAmount : 0,
        ),
      );
      _validateSplits();
    });
  }

  void _removeSplit(int index) {
    if (_splits.length <= 1) return;
    setState(() {
      _splits.removeAt(index);
      _validateSplits();
    });
  }

  void _updateSplitCategory(int index, String category) {
    setState(() {
      _splits[index] = _splits[index].copyWith(category: category);
    });
  }

  void _updateSplitAmount(int index, double amount) {
    setState(() {
      _splits[index] = _splits[index].copyWith(amount: amount);
      _validateSplits();
    });
  }

  void _validateSplits() {
    final totalSplitAmount = _splits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    // Allow small floating point differences
    _isValid =
        (totalSplitAmount - widget.totalAmount).abs() < 0.01 &&
        _splits.every((s) => s.amount > 0);
  }

  void _distributeSplitsEvenly() {
    setState(() {
      final splitAmount = widget.totalAmount / _splits.length;
      for (int i = 0; i < _splits.length; i++) {
        _splits[i] = _splits[i].copyWith(amount: splitAmount);
      }
      // Handle rounding - put remainder in first split
      final total = splitAmount * _splits.length;
      final diff = widget.totalAmount - total;
      if (diff.abs() > 0.001) {
        _splits[0] = _splits[0].copyWith(amount: _splits[0].amount + diff);
      }
      _validateSplits();
    });
  }

  double get _remainingAmount {
    final used = _splits.fold<double>(0, (sum, s) => sum + s.amount);
    return widget.totalAmount - used;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.call_split, color: AppTheme.info),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Split Transaction',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Total amount card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${AppConstants.defaultCurrencySymbol}${widget.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${AppConstants.defaultCurrencySymbol}${_remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _remainingAmount.abs() < 0.01
                                  ? AppTheme.income
                                  : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Splits list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ..._splits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final split = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SplitItemCard(
                        split: split,
                        index: index,
                        categories: widget.categories,
                        canRemove: _splits.length > 1,
                        onCategoryChanged: (cat) =>
                            _updateSplitCategory(index, cat),
                        onAmountChanged: (amt) =>
                            _updateSplitAmount(index, amt),
                        onRemove: () => _removeSplit(index),
                        isDark: isDark,
                      ),
                    );
                  }),

                  // Add split button
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addSplit,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Split'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _distributeSplitsEvenly,
                        icon: const Icon(Icons.balance, size: 18),
                        label: const Text('Split Evenly'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isValid
                        ? () {
                            widget.onSave(_splits);
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save ${_splits.length} Splits',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitItemCard extends StatelessWidget {
  final SplitItem split;
  final int index;
  final List<String> categories;
  final bool canRemove;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onRemove;
  final bool isDark;

  const _SplitItemCard({
    required this.split,
    required this.index,
    required this.categories,
    required this.canRemove,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // Header with index and remove
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Split ${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: AppTheme.expense.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Category selector
          _CategoryDropdown(
            value: split.category,
            categories: categories,
            onChanged: onCategoryChanged,
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // Amount input
          _AmountInput(
            value: split.amount,
            onChanged: onAmountChanged,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
          dropdownColor: isDark ? Colors.grey[850] : Colors.white,
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    IconConstants.getIcon(category),
                    size: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _AmountInput extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool isDark;

  const _AmountInput({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  State<_AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<_AmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final newText = widget.value.toStringAsFixed(2);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (value) {
        final amount = double.tryParse(value) ?? 0;
        widget.onChanged(amount);
      },
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: widget.isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        prefixText: AppConstants.defaultCurrencySymbol,
        prefixStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
        filled: true,
        fillColor: widget.isDark ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Split item data model.
class SplitItem {
  final String category;
  final double amount;
  final String? note;

  const SplitItem({required this.category, required this.amount, this.note});

  SplitItem copyWith({String? category, double? amount, String? note}) {
    return SplitItem(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}

/// Visual representation of a split transaction.
class SplitTransactionIndicator extends StatelessWidget {
  final int splitCount;
  final VoidCallback? onTap;

  const SplitTransactionIndicator({
    super.key,
    required this.splitCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (splitCount <= 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.info.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_split, size: 10, color: AppTheme.info),
            const SizedBox(width: 2),
            Text(
              '$splitCount',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
