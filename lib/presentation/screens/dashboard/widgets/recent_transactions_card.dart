import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying recent transactions list
class RecentTransactionsCard extends StatelessWidget {
  final List<TransactionItem>? transactions;
  final VoidCallback? onSeeAllTap;

  const RecentTransactionsCard({
    super.key,
    this.transactions,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sample transactions data
    final items = transactions ?? _sampleTransactions;

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
                'Recent Activity',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transactions List
          ...items.map((item) => _TransactionTile(item: item)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem item;

  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = item.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppTheme.income.withValues(alpha: 0.1)
                  : (isDark ? Colors.grey[800] : Colors.grey[100]),
              shape: BoxShape.circle,
              border: Border.all(
                color: isIncome
                    ? AppTheme.income.withValues(alpha: 0.2)
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: isIncome
                        ? AppTheme.income
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                // AI categorized indicator
                if (item.isAiCategorized)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 8,
                        color: const Color(0xFF818CF8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      ' • ${item.time}',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${AppConstants.defaultCurrencySymbol}${item.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? AppTheme.income : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              if (item.isRecurring)
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
              else
                Text(
                  item.account,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum TransactionType { income, expense, transfer }

class TransactionItem {
  final String title;
  final String category;
  final String time;
  final double amount;
  final TransactionType type;
  final IconData icon;
  final String account;
  final bool isRecurring;
  final bool isAiCategorized;

  const TransactionItem({
    required this.title,
    required this.category,
    required this.time,
    required this.amount,
    required this.type,
    required this.icon,
    this.account = '',
    this.isRecurring = false,
    this.isAiCategorized = false,
  });
}

final List<TransactionItem> _sampleTransactions = [
  TransactionItem(
    title: 'Whole Foods',
    category: 'Groceries',
    time: '10:42 AM',
    amount: 84.20,
    type: TransactionType.expense,
    icon: Icons.shopping_bag_outlined,
    account: 'Chase ...4205',
    isAiCategorized: true,
  ),
  TransactionItem(
    title: 'Starbucks',
    category: 'Dining',
    time: 'Yesterday',
    amount: 5.40,
    type: TransactionType.expense,
    icon: Icons.coffee_outlined,
    account: 'Apple Card',
  ),
  TransactionItem(
    title: 'Electric Bill',
    category: 'Utilities',
    time: 'Yesterday',
    amount: 120.00,
    type: TransactionType.expense,
    icon: Icons.flash_on_outlined,
    isRecurring: true,
  ),
  TransactionItem(
    title: 'Direct Deposit',
    category: 'Income',
    time: 'Oct 28',
    amount: 2450.00,
    type: TransactionType.income,
    icon: Icons.arrow_downward_rounded,
    account: 'Chase ...4205',
  ),
  TransactionItem(
    title: 'Uber',
    category: 'Transport',
    time: 'Oct 27',
    amount: 18.20,
    type: TransactionType.expense,
    icon: Icons.directions_car_outlined,
    account: 'Apple Card',
  ),
];
