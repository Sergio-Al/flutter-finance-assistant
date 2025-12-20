import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying a single budget item with progress.
class BudgetItemCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;
  final bool showAlert;

  const BudgetItemCard({
    super.key,
    required this.budget,
    this.onTap,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Category Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getCategoryColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Period
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget.category?.name ?? 'Budget',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showAlert) ...[
                          const SizedBox(width: 8),
                          _AlertBadge(isExceeded: budget.isExceeded),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${budget.period.displayName} • ${budget.daysRemaining} days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress Percentage
              Text(
                '${budget.progressPercent}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.progressCapped,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
            ),
          ),
          const SizedBox(height: 12),
          // Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${AppConstants.defaultCurrencySymbol}${budget.spentAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text:
                          ' / ${AppConstants.defaultCurrencySymbol}${budget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${AppConstants.defaultCurrencySymbol}${budget.remainingAmount.toStringAsFixed(0)} left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: budget.remainingAmount >= 0
                      ? AppTheme.success
                      : AppTheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    return AppTheme.getBudgetStatusColor(budget.progress);
  }

  /// Get category color if available, otherwise use status color.
  Color _getCategoryColor() {
    if (budget.category != null) {
      return Color(budget.category!.color);
    }
    return _getStatusColor();
  }

  IconData _getCategoryIcon() {
    if (budget.category != null) {
      return IconConstants.getIcon(budget.category!.icon);
    }
    return IconConstants.defaultCategoryIcon;
  }
}

class _AlertBadge extends StatelessWidget {
  final bool isExceeded;

  const _AlertBadge({required this.isExceeded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isExceeded ? AppTheme.error : AppTheme.warning).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isExceeded ? AppTheme.error : AppTheme.warning).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExceeded ? Icons.error : Icons.warning_amber,
            size: 12,
            color: isExceeded ? AppTheme.error : AppTheme.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isExceeded ? 'Over' : 'Warning',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isExceeded ? AppTheme.error : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}
