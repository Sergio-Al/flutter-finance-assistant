import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_event.dart';
import 'package:flutter_finance_assistant/presentation/widgets/category_selector.dart';

/// Bottom sheet for creating a new budget.
class CreateBudgetSheet extends StatefulWidget {
  const CreateBudgetSheet({super.key});

  @override
  State<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends State<CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  double _alertThreshold = 0.80;
  bool _rollover = false;
  bool _alertsEnabled = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                const SizedBox(height: 24),

                // Title
                Text(
                  'Create Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a spending limit for a category',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Category Selector
                _buildLabel('Category'),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    // Get userId from AuthBloc
                    final authState = context.read<AuthBloc>().state;
                    final userId = authState is AuthAuthenticated
                        ? authState.userId
                        : '';

                    return CategorySelector(
                      userId: userId,
                      selectedCategoryId: _selectedCategoryId,
                      filterType:
                          CategoryType.expense, // Budgets are for expenses
                      hintText: 'Select an expense category',
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                    );
                  },
                ),
                if (_selectedCategoryId == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Please select a category',
                    style: TextStyle(fontSize: 12, color: Colors.red[400]),
                  ),
                ],
                const SizedBox(height: 24),

                // Amount
                _buildLabel('Budget Amount'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Period
                _buildLabel('Budget Period'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BudgetPeriod.values.map((period) {
                    final isSelected = period == _selectedPeriod;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight)
                              : (isDark ? Colors.grey[900] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          period.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Alert Threshold
                _buildLabel(
                  'Alert Threshold: ${(_alertThreshold * 100).toInt()}%',
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _alertThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  activeColor: isDark
                      ? AppTheme.primaryDark
                      : AppTheme.primaryLight,
                  onChanged: (value) => setState(() => _alertThreshold = value),
                ),
                const SizedBox(height: 16),

                // Toggles
                _buildToggle(
                  'Enable Alerts',
                  'Get notified when approaching limit',
                  _alertsEnabled,
                  (value) => setState(() => _alertsEnabled = value),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  'Rollover Unused',
                  'Add remaining budget to next period',
                  _rollover,
                  (value) => setState(() => _rollover = value),
                  isDark,
                ),
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.primaryDark
                          : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        ),
      ],
    );
  }

  void _handleCreate() {
    if (!_formKey.currentState!.validate()) return;

    // Validate category selection
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    context.read<BudgetBloc>().add(
      BudgetCreateRequested(
        categoryId: _selectedCategoryId!,
        amount: amount,
        period: _selectedPeriod,
        rollover: _rollover,
        alertsEnabled: _alertsEnabled,
        alertThreshold: _alertThreshold,
      ),
    );

    Navigator.pop(context);
  }
}

/// Bottom sheet for editing an existing budget.
class EditBudgetSheet extends StatefulWidget {
  final Budget budget;

  const EditBudgetSheet({super.key, required this.budget});

  @override
  State<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<EditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  late double _alertThreshold;
  late bool _rollover;
  late bool _alertsEnabled;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amount.toString(),
    );
    _alertThreshold = widget.budget.alertThreshold;
    _rollover = widget.budget.rollover;
    _alertsEnabled = widget.budget.alertsEnabled;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                const SizedBox(height: 24),

                // Title
                Text(
                  'Edit Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.budget.category?.name ?? 'Budget',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Amount
                Text(
                  'Budget Amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Alert Threshold
                Text(
                  'Alert Threshold: ${(_alertThreshold * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _alertThreshold,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  activeColor: isDark
                      ? AppTheme.primaryDark
                      : AppTheme.primaryLight,
                  onChanged: (value) => setState(() => _alertThreshold = value),
                ),
                const SizedBox(height: 16),

                // Toggles
                _buildToggle(
                  'Enable Alerts',
                  _alertsEnabled,
                  (value) => setState(() => _alertsEnabled = value),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildToggle(
                  'Rollover Unused',
                  _rollover,
                  (value) => setState(() => _rollover = value),
                  isDark,
                ),
                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.primaryDark
                          : AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Budget',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        ),
      ],
    );
  }

  void _handleUpdate() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);

    final updatedBudget = widget.budget.copyWith(
      amount: amount,
      alertThreshold: _alertThreshold,
      rollover: _rollover,
      alertsEnabled: _alertsEnabled,
    );

    context.read<BudgetBloc>().add(
      BudgetUpdateRequested(budget: updatedBudget),
    );

    Navigator.pop(context);
  }
}
