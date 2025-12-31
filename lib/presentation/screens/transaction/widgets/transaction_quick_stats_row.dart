import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Quick stats row showing avg daily spend, biggest expense, etc.
class TransactionQuickStatsRow extends StatelessWidget {
  final List<QuickStat> stats;
  final bool scrollable;

  const TransactionQuickStatsRow({
    super.key,
    required this.stats,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _QuickStatCard(stat: stats[index]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: stats.indexOf(stat) < stats.length - 1 ? 12 : 0,
              ),
              child: _QuickStatCard(stat: stat, expanded: true),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final QuickStat stat;
  final bool expanded;

  const _QuickStatCard({required this.stat, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: stat.onTap,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: expanded ? null : 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and Label Row
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (stat.color ?? AppTheme.info).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat.icon,
                    size: 14,
                    color: stat.color ?? AppTheme.info,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Value
            Text(
              stat.formattedValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    stat.valueColor ?? (isDark ? Colors.white : Colors.black87),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle/Change indicator
            if (stat.subtitle != null || stat.changePercent != null) ...[
              const SizedBox(height: 2),
              if (stat.changePercent != null)
                _ChangeIndicator(
                  percent: stat.changePercent!,
                  period: stat.changePeriod ?? 'vs last period',
                )
              else
                Text(
                  stat.subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeIndicator extends StatelessWidget {
  final double percent;
  final String period;

  const _ChangeIndicator({required this.percent, required this.period});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = percent >= 0;
    // For spending, positive change is bad (red), negative is good (green)
    final color = isPositive ? AppTheme.expense : AppTheme.income;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 10,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            period,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Quick stat data model.
class QuickStat {
  final String label;
  final double value;
  final String? formattedValueOverride;
  final IconData icon;
  final Color? color;
  final Color? valueColor;
  final String? subtitle;
  final double? changePercent;
  final String? changePeriod;
  final VoidCallback? onTap;

  const QuickStat({
    required this.label,
    required this.value,
    this.formattedValueOverride,
    required this.icon,
    this.color,
    this.valueColor,
    this.subtitle,
    this.changePercent,
    this.changePeriod,
    this.onTap,
  });

  String get formattedValue {
    if (formattedValueOverride != null) return formattedValueOverride!;
    return '${AppConstants.defaultCurrencySymbol}${value.toStringAsFixed(2)}';
  }
}

/// Pre-built quick stats factory.
class QuickStatsFactory {
  static QuickStat avgDailySpend({
    required double amount,
    double? changePercent,
  }) {
    return QuickStat(
      label: 'Avg Daily',
      value: amount,
      icon: Icons.calendar_today,
      color: AppTheme.info,
      changePercent: changePercent,
      changePeriod: 'vs last week',
    );
  }

  static QuickStat biggestExpense({required double amount, String? category}) {
    return QuickStat(
      label: 'Biggest Expense',
      value: amount,
      icon: Icons.trending_up,
      color: AppTheme.expense,
      valueColor: AppTheme.expense,
      subtitle: category,
    );
  }

  static QuickStat totalTransactions({
    required int count,
    double? changePercent,
  }) {
    return QuickStat(
      label: 'Transactions',
      value: count.toDouble(),
      formattedValueOverride: count.toString(),
      icon: Icons.receipt_long,
      color: AppTheme.primaryLight,
      changePercent: changePercent,
      changePeriod: 'vs last month',
    );
  }

  static QuickStat savingsRate({
    required double percent,
    double? targetPercent,
  }) {
    final onTrack = targetPercent == null || percent >= targetPercent;
    return QuickStat(
      label: 'Savings Rate',
      value: percent,
      formattedValueOverride: '${percent.toStringAsFixed(1)}%',
      icon: Icons.savings,
      color: onTrack ? AppTheme.income : AppTheme.warning,
      valueColor: onTrack ? AppTheme.income : AppTheme.warning,
      subtitle: targetPercent != null
          ? 'Target: ${targetPercent.toInt()}%'
          : null,
    );
  }

  static QuickStat topCategory({
    required String categoryName,
    required double amount,
    required double percent,
  }) {
    return QuickStat(
      label: 'Top Category',
      value: amount,
      icon: Icons.category,
      color: AppTheme.info,
      subtitle: '$categoryName (${percent.toStringAsFixed(0)}%)',
    );
  }

  static QuickStat monthlyBudgetUsed({
    required double spent,
    required double budget,
  }) {
    final percent = budget > 0 ? (spent / budget) * 100 : 0.0;
    final isOverBudget = percent > 100;
    return QuickStat(
      label: 'Budget Used',
      value: percent,
      formattedValueOverride: '${percent.toStringAsFixed(0)}%',
      icon: Icons.pie_chart,
      color: isOverBudget ? AppTheme.expense : AppTheme.income,
      valueColor: isOverBudget ? AppTheme.expense : AppTheme.income,
      subtitle:
          '${AppConstants.defaultCurrencySymbol}${spent.toStringAsFixed(0)} of ${AppConstants.defaultCurrencySymbol}${budget.toStringAsFixed(0)}',
    );
  }
}
