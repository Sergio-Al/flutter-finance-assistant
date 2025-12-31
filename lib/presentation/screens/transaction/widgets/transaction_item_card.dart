import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/transaction.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying a single transaction item.
class TransactionItemCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDate;
  final bool compact;

  const TransactionItemCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.showDate = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactCard(context, isDark);
    }

    return GlassCard(
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Icon
            _TransactionIcon(transaction: transaction, isDark: isDark),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.description ?? _getDefaultDescription(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isHighConfidence)
                        _AiBadge(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        transaction.category?.name ?? 'Uncategorized',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      if (showDate) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                        Text(
                          _formatDate(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _getAmountColor(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                if (transaction.isRecurring)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay,
                        size: 10,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Recurring',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else if (transaction.account != null)
                  Text(
                    transaction.account!.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icon
            _TransactionIcon(
              transaction: transaction,
              isDark: isDark,
              size: 36,
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? _getDefaultDescription(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category?.name ?? 'Uncategorized',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        ' • ${_formatTime(transaction.date)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              _formatAmount(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _getAmountColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultDescription() {
    switch (transaction.type) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String _formatAmount() {
    final prefix = transaction.type == TransactionType.income ? '+' : '-';
    return '$prefix${AppConstants.defaultCurrencySymbol}${transaction.amount.toStringAsFixed(2)}';
  }

  Color _getAmountColor(bool isDark) {
    switch (transaction.type) {
      case TransactionType.income:
        return AppTheme.income;
      case TransactionType.expense:
        return isDark ? Colors.white : Colors.black87;
      case TransactionType.transfer:
        return AppTheme.info;
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
    } else {
      return '${_monthName(date.month)} ${date.day}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }
}

/// Transaction icon with category-based styling.
class _TransactionIcon extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final double size;

  const _TransactionIcon({
    required this.transaction,
    required this.isDark,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;

    final bgColor = isIncome
        ? AppTheme.income.withValues(alpha: 0.1)
        : isTransfer
        ? AppTheme.info.withValues(alpha: 0.1)
        : (isDark ? Colors.grey[800] : Colors.grey[100]);

    final iconColor = isIncome
        ? AppTheme.income
        : isTransfer
        ? AppTheme.info
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isIncome
              ? AppTheme.income.withValues(alpha: 0.2)
              : isTransfer
              ? AppTheme.info.withValues(alpha: 0.2)
              : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getCategoryIcon(),
              size: size * 0.45,
              color: iconColor,
            ),
          ),
          // AI indicator
          if (transaction.isHighConfidence)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 8,
                  color: Color(0xFF818CF8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    if (transaction.type == TransactionType.transfer) {
      return Icons.swap_horiz;
    }

    if (transaction.type == TransactionType.income) {
      return Icons.arrow_downward_rounded;
    }

    // Try to get icon from category
    final categoryIcon = transaction.category?.icon;
    if (categoryIcon != null) {
      return IconConstants.getIcon(categoryIcon);
    }

    return Icons.receipt_long_outlined;
  }
}

/// AI categorization badge.
class _AiBadge extends StatelessWidget {
  final bool isDark;

  const _AiBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF818CF8).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 10, color: Color(0xFF818CF8)),
          SizedBox(width: 2),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF818CF8),
            ),
          ),
        ],
      ),
    );
  }
}
