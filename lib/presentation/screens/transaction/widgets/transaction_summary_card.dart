import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/usecases/transaction/get_spending_summary.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying transaction summary with income, expenses, and balance.
class TransactionSummaryCard extends StatelessWidget {
  final SpendingSummary? summary;
  final double? totalIncome;
  final double? totalExpense;
  final int? transactionCount;

  const TransactionSummaryCard({
    super.key,
    this.summary,
    this.totalIncome,
    this.totalExpense,
    this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final income = summary?.totalIncome ?? totalIncome ?? 0;
    final expense = summary?.totalSpent ?? totalExpense ?? 0;
    final balance = summary?.netBalance ?? (income - expense);
    final count = summary?.transactionCount ?? transactionCount ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count transaction${count != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance
          Center(
            child: Column(
              children: [
                Text(
                  'Net Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${balance >= 0 ? '+' : ''}${AppConstants.defaultCurrencySymbol}${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? AppTheme.income : AppTheme.expense,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Income / Expense Row
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Income',
                  amount: income,
                  icon: Icons.arrow_downward_rounded,
                  color: AppTheme.income,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Expenses',
                  amount: expense,
                  icon: Icons.arrow_upward_rounded,
                  color: AppTheme.expense,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${AppConstants.defaultCurrencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Compact summary row for inline display.
class TransactionSummaryRow extends StatelessWidget {
  final double income;
  final double expense;

  const TransactionSummaryRow({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _CompactSummaryChip(
          label: 'Income',
          amount: income,
          color: AppTheme.income,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _CompactSummaryChip(
          label: 'Expenses',
          amount: expense,
          color: AppTheme.expense,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _CompactSummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDark;

  const _CompactSummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '${AppConstants.defaultCurrencySymbol}${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
