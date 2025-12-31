import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart'
    as entity;
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Bottom sheet for editing existing transactions.
class EditTransactionSheet extends StatefulWidget {
  final entity.Transaction transaction;
  final List<String> categories;
  final Function(entity.Transaction updatedTransaction) onSave;
  final VoidCallback? onDelete;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
    required this.categories,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required entity.Transaction transaction,
    required List<String> categories,
    required Function(entity.Transaction) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTransactionSheet(
        transaction: transaction,
        categories: categories,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _noteController;
  late entity.TransactionType _selectedType;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late bool _isRecurring;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    _noteController = TextEditingController();
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.categoryId;
    _selectedDate = widget.transaction.date;
    _isRecurring = widget.transaction.isRecurring;

    // Listen for changes
    _amountController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
    _noteController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with delete option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Transaction',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      onPressed: _showDeleteConfirmation,
                      icon: Icon(Icons.delete_outline, color: AppTheme.expense),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Transaction Type Selector
              _buildSectionLabel('Type', isDark),
              const SizedBox(height: 8),
              _TransactionTypeSelector(
                selectedType: _selectedType,
                onTypeChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    _hasChanges = true;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Amount
              _buildSectionLabel('Amount', isDark),
              const SizedBox(height: 8),
              _AmountField(
                controller: _amountController,
                type: _selectedType,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionLabel('Description', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Enter description',
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Category
              _buildSectionLabel('Category', isDark),
              const SizedBox(height: 8),
              _CategorySelector(
                categories: widget.categories,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _hasChanges = true;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Date
              _buildSectionLabel('Date', isDark),
              const SizedBox(height: 8),
              _DateSelector(
                selectedDate: _selectedDate,
                onDateChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                    _hasChanges = true;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Note (optional)
              _buildSectionLabel('Note (optional)', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _noteController,
                hint: 'Add a note...',
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Recurring toggle
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 20,
                      color: _isRecurring ? AppTheme.primaryLight : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recurring Transaction',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                          _hasChanges = true;
                        });
                      },
                      activeColor: AppTheme.primaryLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
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
                      onPressed: _hasChanges ? _saveTransaction : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _saveTransaction() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final updatedTransaction = widget.transaction.copyWith(
      type: _selectedType,
      amount: amount,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      categoryId: _selectedCategory,
      date: _selectedDate,
      isRecurring: _isRecurring,
    );

    widget.onSave(updatedTransaction);
    Navigator.pop(context);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  final entity.TransactionType selectedType;
  final ValueChanged<entity.TransactionType> onTypeChanged;

  const _TransactionTypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _TypeButton(
          label: 'Expense',
          icon: Icons.arrow_upward,
          isSelected: selectedType == entity.TransactionType.expense,
          color: AppTheme.expense,
          onTap: () => onTypeChanged(entity.TransactionType.expense),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _TypeButton(
          label: 'Income',
          icon: Icons.arrow_downward,
          isSelected: selectedType == entity.TransactionType.income,
          color: AppTheme.income,
          onTap: () => onTypeChanged(entity.TransactionType.income),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _TypeButton(
          label: 'Transfer',
          icon: Icons.swap_horiz,
          isSelected: selectedType == entity.TransactionType.transfer,
          color: AppTheme.info,
          onTap: () => onTypeChanged(entity.TransactionType.transfer),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : (isDark ? Colors.grey[900] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final entity.TransactionType type;
  final bool isDark;

  const _AmountField({
    required this.controller,
    required this.type,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == entity.TransactionType.expense
        ? AppTheme.expense
        : type == entity.TransactionType.income
        ? AppTheme.income
        : AppTheme.info;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      decoration: InputDecoration(
        prefixText: AppConstants.defaultCurrencySymbol,
        prefixStyle: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final bool isDark;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = category == selectedCategory;
        return GestureDetector(
          onTap: () => onCategoryChanged(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryLight.withValues(alpha: 0.15)
                  : (isDark ? Colors.grey[900] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryLight : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconConstants.getIcon(category),
                  size: 16,
                  color: isSelected ? AppTheme.primaryLight : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryLight
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isDark;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
