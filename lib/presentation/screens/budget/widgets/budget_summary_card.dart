import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying overall budget summary.
class BudgetSummaryCard extends StatelessWidget {
  final double totalBudgeted;
  final double totalSpent;
  final double overallProgress;
  final int budgetCount;

  const BudgetSummaryCard({
    super.key,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.overallProgress,
    required this.budgetCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = totalBudgeted - totalSpent;
    final progressPercent = (overallProgress * 100).toInt();

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
                'Total Budget Overview',
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
                  color: isDark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$budgetCount budget${budgetCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Progress Circle
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                  ),
                  // Progress Circle
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: overallProgress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getBudgetStatusColor(overallProgress),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Center Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Used',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _SummaryStatItem(
                  label: 'Total Budget',
                  value: '${AppConstants.defaultCurrencySymbol}${totalBudgeted.toStringAsFixed(0)}',
                  color: isDark ? Colors.grey[400]! : Colors.grey[700]!,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Expanded(
                child: _SummaryStatItem(
                  label: 'Spent',
                  value: '${AppConstants.defaultCurrencySymbol}${totalSpent.toStringAsFixed(0)}',
                  color: AppTheme.expense,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              Expanded(
                child: _SummaryStatItem(
                  label: 'Remaining',
                  value: '${AppConstants.defaultCurrencySymbol}${remaining.toStringAsFixed(0)}',
                  color: remaining >= 0 ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
