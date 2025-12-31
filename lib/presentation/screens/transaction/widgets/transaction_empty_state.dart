import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// Empty state widget when no transactions exist.
class TransactionEmptyState extends StatelessWidget {
  final EmptyStateType type;
  final VoidCallback? onActionPressed;
  final String? customTitle;
  final String? customSubtitle;
  final String? actionLabel;

  const TransactionEmptyState({
    super.key,
    this.type = EmptyStateType.noTransactions,
    this.onActionPressed,
    this.customTitle,
    this.customSubtitle,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = _getConfig();

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Illustration
              _EmptyStateIllustration(type: type, isDark: isDark),
              const SizedBox(height: 32),

              // Title
              Text(
                customTitle ?? config.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                customSubtitle ?? config.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action button
              if (onActionPressed != null) ...[
                ElevatedButton.icon(
                  onPressed: onActionPressed,
                  icon: Icon(config.actionIcon),
                  label: Text(actionLabel ?? config.actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _EmptyStateConfig _getConfig() {
    switch (type) {
      case EmptyStateType.noTransactions:
        return _EmptyStateConfig(
          title: 'No Transactions Yet',
          subtitle:
              'Start tracking your finances by adding your first transaction.',
          actionLabel: 'Add Transaction',
          actionIcon: Icons.add,
        );
      case EmptyStateType.noSearchResults:
        return _EmptyStateConfig(
          title: 'No Results Found',
          subtitle:
              'Try adjusting your search or filters to find what you\'re looking for.',
          actionLabel: 'Clear Filters',
          actionIcon: Icons.filter_alt_off,
        );
      case EmptyStateType.noFilterResults:
        return _EmptyStateConfig(
          title: 'No Matching Transactions',
          subtitle: 'There are no transactions matching your current filters.',
          actionLabel: 'Reset Filters',
          actionIcon: Icons.refresh,
        );
      case EmptyStateType.noIncomeTransactions:
        return _EmptyStateConfig(
          title: 'No Income Recorded',
          subtitle:
              'Add your income sources to get a complete picture of your finances.',
          actionLabel: 'Add Income',
          actionIcon: Icons.add,
        );
      case EmptyStateType.noExpenseTransactions:
        return _EmptyStateConfig(
          title: 'No Expenses Recorded',
          subtitle: 'Great job! Or maybe you haven\'t added any expenses yet.',
          actionLabel: 'Add Expense',
          actionIcon: Icons.add,
        );
      case EmptyStateType.noRecurringTransactions:
        return _EmptyStateConfig(
          title: 'No Recurring Transactions',
          subtitle:
              'Set up recurring transactions for regular bills and subscriptions.',
          actionLabel: 'Add Recurring',
          actionIcon: Icons.repeat,
        );
      case EmptyStateType.error:
        return _EmptyStateConfig(
          title: 'Something Went Wrong',
          subtitle: 'We couldn\'t load your transactions. Please try again.',
          actionLabel: 'Retry',
          actionIcon: Icons.refresh,
        );
    }
  }
}

class _EmptyStateConfig {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;

  _EmptyStateConfig({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
  });
}

/// Empty state illustration widget.
class _EmptyStateIllustration extends StatelessWidget {
  final EmptyStateType type;
  final bool isDark;

  const _EmptyStateIllustration({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 160,
      child: CustomPaint(
        painter: _EmptyStatePainter(type: type, isDark: isDark),
      ),
    );
  }
}

class _EmptyStatePainter extends CustomPainter {
  final EmptyStateType type;
  final bool isDark;

  _EmptyStatePainter({required this.type, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case EmptyStateType.noTransactions:
        _paintNoTransactions(canvas, size);
        break;
      case EmptyStateType.noSearchResults:
        _paintNoSearchResults(canvas, size);
        break;
      case EmptyStateType.noFilterResults:
        _paintNoFilterResults(canvas, size);
        break;
      case EmptyStateType.error:
        _paintError(canvas, size);
        break;
      default:
        _paintNoTransactions(canvas, size);
    }
  }

  void _paintNoTransactions(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = (isDark ? Colors.grey[800] : Colors.grey[200])!.withValues(
        alpha: 0.5,
      );
    canvas.drawCircle(Offset(centerX, centerY), 60, bgPaint);

    // Wallet icon representation
    final walletPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final walletRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY), width: 80, height: 50),
      const Radius.circular(8),
    );
    canvas.drawRRect(walletRect, walletPaint);

    // Wallet outline
    final outlinePaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(walletRect, outlinePaint);

    // Plus icon
    final plusPaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX - 12, centerY),
      Offset(centerX + 12, centerY),
      plusPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 12),
      Offset(centerX, centerY + 12),
      plusPaint,
    );

    // Decorative dots
    _paintDecorativeDots(canvas, size);
  }

  void _paintNoSearchResults(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = (isDark ? Colors.grey[800] : Colors.grey[200])!.withValues(
        alpha: 0.5,
      );
    canvas.drawCircle(Offset(centerX, centerY), 60, bgPaint);

    // Magnifying glass
    final glassPaint = Paint()
      ..color = AppTheme.info
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(centerX - 10, centerY - 10), 25, glassPaint);

    // Handle
    canvas.drawLine(
      Offset(centerX + 10, centerY + 10),
      Offset(centerX + 30, centerY + 30),
      glassPaint,
    );

    // X mark inside
    final xPaint = Paint()
      ..color = AppTheme.expense.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX - 18, centerY - 18),
      Offset(centerX - 2, centerY - 2),
      xPaint,
    );
    canvas.drawLine(
      Offset(centerX - 2, centerY - 18),
      Offset(centerX - 18, centerY - 2),
      xPaint,
    );

    _paintDecorativeDots(canvas, size);
  }

  void _paintNoFilterResults(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = (isDark ? Colors.grey[800] : Colors.grey[200])!.withValues(
        alpha: 0.5,
      );
    canvas.drawCircle(Offset(centerX, centerY), 60, bgPaint);

    // Filter funnel
    final funnelPaint = Paint()
      ..color = AppTheme.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final funnelPath = Path()
      ..moveTo(centerX - 30, centerY - 20)
      ..lineTo(centerX + 30, centerY - 20)
      ..lineTo(centerX + 10, centerY + 5)
      ..lineTo(centerX + 10, centerY + 25)
      ..lineTo(centerX - 10, centerY + 25)
      ..lineTo(centerX - 10, centerY + 5)
      ..close();

    canvas.drawPath(funnelPath, funnelPaint);

    _paintDecorativeDots(canvas, size);
  }

  void _paintError(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background circle
    final bgPaint = Paint()..color = AppTheme.expense.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(centerX, centerY), 60, bgPaint);

    // Warning triangle
    final trianglePaint = Paint()
      ..color = AppTheme.expense
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final trianglePath = Path()
      ..moveTo(centerX, centerY - 30)
      ..lineTo(centerX + 35, centerY + 25)
      ..lineTo(centerX - 35, centerY + 25)
      ..close();

    canvas.drawPath(trianglePath, trianglePaint);

    // Exclamation mark
    final exclamationPaint = Paint()
      ..color = AppTheme.expense
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY - 15),
      Offset(centerX, centerY + 5),
      exclamationPaint,
    );

    canvas.drawCircle(
      Offset(centerX, centerY + 15),
      2,
      Paint()..color = AppTheme.expense,
    );
  }

  void _paintDecorativeDots(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (isDark ? Colors.grey[700] : Colors.grey[300])!;

    // Scattered dots
    final dots = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.45),
    ];

    for (int i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], 3 + (i % 3), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyStatePainter oldDelegate) {
    return type != oldDelegate.type || isDark != oldDelegate.isDark;
  }
}

/// Empty state type enum.
enum EmptyStateType {
  noTransactions,
  noSearchResults,
  noFilterResults,
  noIncomeTransactions,
  noExpenseTransactions,
  noRecurringTransactions,
  error,
}

/// Compact empty state for inline use.
class TransactionEmptyStateCompact extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? actionLabel;

  const TransactionEmptyStateCompact({
    super.key,
    required this.message,
    this.icon,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onTap != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onTap, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
