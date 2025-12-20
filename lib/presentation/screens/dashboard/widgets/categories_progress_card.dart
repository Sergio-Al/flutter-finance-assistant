import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card showing budget progress by category
class CategoriesProgressCard extends StatelessWidget {
  final List<CategoryBudget>? categories;
  final VoidCallback? onMoreTap;

  const CategoriesProgressCard({
    super.key,
    this.categories,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = categories ?? _sampleCategories;

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
                'Top Categories',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: onMoreTap,
                child: Icon(
                  Icons.more_horiz,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Category Items
          ...items.map((item) => _CategoryProgressItem(item: item)),
        ],
      ),
    );
  }
}

class _CategoryProgressItem extends StatelessWidget {
  final CategoryBudget item;

  const _CategoryProgressItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percentage = (item.spent / item.budget).clamp(0.0, 1.0);
    final isOverBudget = item.spent > item.budget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${AppConstants.defaultCurrencySymbol}${item.spent.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    TextSpan(
                      text: ' / ${AppConstants.defaultCurrencySymbol}${item.budget.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? AppTheme.error
                    : (percentage >= 0.8
                        ? AppTheme.warning
                        : (isDark ? Colors.grey[400]! : const Color(0xFF6366F1))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBudget {
  final String name;
  final double spent;
  final double budget;

  const CategoryBudget({
    required this.name,
    required this.spent,
    required this.budget,
  });
}

final List<CategoryBudget> _sampleCategories = [
  CategoryBudget(name: 'Housing', spent: 1200, budget: 1200),
  CategoryBudget(name: 'Food & Drink', spent: 450, budget: 600),
  CategoryBudget(name: 'Entertainment', spent: 180, budget: 150),
];
