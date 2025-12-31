import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// Badge/indicator for recurring transactions.
class TransactionRecurringBadge extends StatelessWidget {
  final RecurringFrequency frequency;
  final DateTime? nextDate;
  final bool showLabel;
  final bool compact;
  final VoidCallback? onTap;

  const TransactionRecurringBadge({
    super.key,
    required this.frequency,
    this.nextDate,
    this.showLabel = true,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _buildCompactBadge(isDark);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.info.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat, size: 12, color: AppTheme.info),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                frequency.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.info,
                ),
              ),
            ],
            if (nextDate != null && showLabel) ...[
              const SizedBox(width: 4),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatNextDate(),
                style: TextStyle(
                  fontSize: 9,
                  color: AppTheme.info.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBadge(bool isDark) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.repeat, size: 10, color: AppTheme.info),
    );
  }

  String _formatNextDate() {
    if (nextDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(nextDate!.year, nextDate!.month, nextDate!.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return 'in ${dateOnly.difference(today).inDays}d';
    } else {
      return '${nextDate!.month}/${nextDate!.day}';
    }
  }
}

/// Recurring frequency enum with display labels.
enum RecurringFrequency {
  daily('Daily', 'Every day'),
  weekly('Weekly', 'Every week'),
  biweekly('Bi-weekly', 'Every 2 weeks'),
  monthly('Monthly', 'Every month'),
  quarterly('Quarterly', 'Every 3 months'),
  yearly('Yearly', 'Every year'),
  custom('Custom', 'Custom schedule');

  final String label;
  final String description;

  const RecurringFrequency(this.label, this.description);

  static RecurringFrequency fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (f) => f.name == value.toLowerCase(),
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

/// Extended recurring info card with more details.
class RecurringTransactionInfoCard extends StatelessWidget {
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextDate;
  final int? occurrencesCompleted;
  final int? totalOccurrences;
  final bool isActive;
  final VoidCallback? onEdit;
  final VoidCallback? onPause;
  final VoidCallback? onDelete;

  const RecurringTransactionInfoCard({
    super.key,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.nextDate,
    this.occurrencesCompleted,
    this.totalOccurrences,
    this.isActive = true,
    this.onEdit,
    this.onPause,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.repeat, size: 20, color: AppTheme.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Transaction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      frequency.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.income.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? 'Active' : 'Paused',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.income : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info rows
          _InfoRow(
            label: 'Started',
            value: _formatDate(startDate),
            isDark: isDark,
          ),
          if (endDate != null)
            _InfoRow(
              label: 'Ends',
              value: _formatDate(endDate!),
              isDark: isDark,
            ),
          if (nextDate != null && isActive)
            _InfoRow(
              label: 'Next',
              value: _formatDate(nextDate!),
              isDark: isDark,
              highlight: true,
            ),
          if (occurrencesCompleted != null)
            _InfoRow(
              label: 'Completed',
              value: totalOccurrences != null
                  ? '$occurrencesCompleted / $totalOccurrences'
                  : '$occurrencesCompleted times',
              isDark: isDark,
            ),

          // Actions
          if (onEdit != null || onPause != null || onDelete != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onEdit != null)
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit!,
                    isDark: isDark,
                  ),
                if (onPause != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: isActive ? Icons.pause : Icons.play_arrow,
                    label: isActive ? 'Pause' : 'Resume',
                    onTap: onPause!,
                    isDark: isDark,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: onDelete!,
                    isDark: isDark,
                    isDestructive: true,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    }

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

    if (date.year == now.year) {
      return '${months[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              color: highlight
                  ? AppTheme.info
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppTheme.expense
        : (isDark ? Colors.grey[400] : Colors.grey[700]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small recurring indicator icon.
class RecurringIndicator extends StatelessWidget {
  final bool isRecurring;
  final double size;

  const RecurringIndicator({
    super.key,
    required this.isRecurring,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecurring) return const SizedBox.shrink();

    return Icon(Icons.repeat, size: size, color: AppTheme.info);
  }
}
