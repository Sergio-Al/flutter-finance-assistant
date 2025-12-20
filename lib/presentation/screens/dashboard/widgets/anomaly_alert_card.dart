import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';

/// Alert card for displaying anomaly detection warnings
class AnomalyAlertCard extends StatelessWidget {
  final String title;
  final String description;
  final double amount;
  final String merchant;
  final String actionText;
  final VoidCallback? onActionTap;
  final VoidCallback? onDismiss;

  const AnomalyAlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.amount,
    required this.merchant,
    this.actionText = 'Review',
    this.onActionTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF4C1D1D).withValues(alpha: 0.3),
                  const Color(0xFF1A1A1A),
                ]
              : [
                  const Color(0xFFFEE2E2),
                  Colors.white,
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: '$description '),
                      TextSpan(
                        text: '${AppConstants.defaultCurrencySymbol}${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const TextSpan(text: ' from '),
                      TextSpan(
                        text: merchant,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const TextSpan(text: ' today. Would you like to dispute one?'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Button
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.error.withValues(alpha: 0.15),
              foregroundColor: isDark ? Colors.white : AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
