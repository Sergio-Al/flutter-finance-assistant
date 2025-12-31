import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card showing AI categorization suggestions for a transaction.
class TransactionAiSuggestionCard extends StatelessWidget {
  final String transactionDescription;
  final List<AiCategorySuggestion> suggestions;
  final String? currentCategory;
  final ValueChanged<AiCategorySuggestion>? onSuggestionAccepted;
  final VoidCallback? onDismiss;
  final bool isLoading;
  final bool compact;

  const TransactionAiSuggestionCard({
    super.key,
    required this.transactionDescription,
    required this.suggestions,
    this.currentCategory,
    this.onSuggestionAccepted,
    this.onDismiss,
    this.isLoading = false,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primaryLight.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Suggestion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Based on "$transactionDescription"',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading state
          if (isLoading)
            _buildLoadingState(isDark)
          else if (suggestions.isEmpty)
            _buildNoSuggestionsState(isDark)
          else
            // Suggestions list
            ...suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return Padding(
                padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                child: _SuggestionItem(
                  suggestion: suggestion,
                  isCurrentCategory: suggestion.categoryName == currentCategory,
                  onTap: () => onSuggestionAccepted?.call(suggestion),
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, bool isDark) {
    if (suggestions.isEmpty || isLoading) return const SizedBox.shrink();

    final topSuggestion = suggestions.first;

    return GestureDetector(
      onTap: () => onSuggestionAccepted?.call(topSuggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: AppTheme.primaryLight),
            const SizedBox(width: 6),
            Text(
              topSuggestion.categoryName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${(topSuggestion.confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryLight.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing transaction...',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuggestionsState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            'No category suggestions available',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final AiCategorySuggestion suggestion;
  final bool isCurrentCategory;
  final VoidCallback? onTap;
  final bool isDark;

  const _SuggestionItem({
    required this.suggestion,
    required this.isCurrentCategory,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCurrentCategory ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentCategory
              ? AppTheme.income.withValues(alpha: 0.1)
              : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
          border: isCurrentCategory
              ? Border.all(color: AppTheme.income.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (suggestion.categoryColor ?? AppTheme.info).withValues(
                  alpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconConstants.getIcon(suggestion.categoryName),
                size: 18,
                color: suggestion.categoryColor ?? AppTheme.info,
              ),
            ),
            const SizedBox(width: 12),
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        suggestion.categoryName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isCurrentCategory) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.income,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (suggestion.reason != null)
                    Text(
                      suggestion.reason!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Confidence indicator
            _ConfidenceIndicator(confidence: suggestion.confidence),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceIndicator extends StatelessWidget {
  final double confidence;

  const _ConfidenceIndicator({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toInt();
    final color = confidence >= 0.8
        ? AppTheme.income
        : confidence >= 0.5
        ? AppTheme.warning
        : AppTheme.expense;

    return Column(
      children: [
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 40,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

/// AI category suggestion model.
class AiCategorySuggestion {
  final String categoryId;
  final String categoryName;
  final double confidence;
  final String? reason;
  final Color? categoryColor;

  const AiCategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
    this.reason,
    this.categoryColor,
  });
}

/// Inline AI suggestion badge for transaction cards.
class AiSuggestionBadge extends StatelessWidget {
  final double confidence;
  final VoidCallback? onTap;

  const AiSuggestionBadge({super.key, required this.confidence, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryLight.withValues(alpha: 0.2),
              AppTheme.primaryLight.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 10, color: AppTheme.primaryLight),
            const SizedBox(width: 3),
            Text(
              'AI ${(confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
