import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Mini chart card showing spending trends.
class TransactionChartCard extends StatelessWidget {
  final List<ChartDataPoint> data;
  final ChartType chartType;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;

  const TransactionChartCard({
    super.key,
    required this.data,
    this.chartType = ChartType.bar,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (title != null || subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                ],
              ),
            ),

          // Chart
          SizedBox(
            height: 120,
            child: chartType == ChartType.bar
                ? _BarChart(data: data, isDark: isDark)
                : _LineChart(data: data, isDark: isDark),
          ),

          // Legend (if data has labels)
          if (data.isNotEmpty && data.first.label != null) ...[
            const SizedBox(height: 12),
            _ChartLegend(data: data, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

/// Bar chart implementation.
class _BarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool isDark;

  const _BarChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        final heightPercent = maxValue > 0 ? point.value / maxValue : 0.0;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == data.length - 1 ? 0 : 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label
                Text(
                  _formatValue(point.value),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80 * heightPercent,
                  decoration: BoxDecoration(
                    color: point.color ?? AppTheme.primaryLight,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    gradient: point.color == null
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryLight,
                              AppTheme.primaryLight.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Text(
                  point.label ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

/// Line chart implementation.
class _LineChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool isDark;

  const _LineChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _LineChartPainter(data: data, isDark: isDark),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final bool isDark;

  _LineChartPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final paint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryLight.withValues(alpha: 0.3),
          AppTheme.primaryLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedY = range > 0 ? (data[i].value - minValue) / range : 0.5;
      final y = size.height - (normalizedY * (size.height - 20)) - 10;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dot
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return data != oldDelegate.data;
  }
}

/// Chart legend showing labels and colors.
class _ChartLegend extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool isDark;

  const _ChartLegend({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.where((d) => d.label != null).map((point) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: point.color ?? AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              point.label!,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Data point for charts.
class ChartDataPoint {
  final double value;
  final String? label;
  final Color? color;
  final DateTime? date;

  const ChartDataPoint({
    required this.value,
    this.label,
    this.color,
    this.date,
  });
}

/// Chart type enum.
enum ChartType { bar, line }

/// Compact spending trend widget.
class SpendingTrendIndicator extends StatelessWidget {
  final double currentAmount;
  final double previousAmount;
  final String period;

  const SpendingTrendIndicator({
    super.key,
    required this.currentAmount,
    required this.previousAmount,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final change = previousAmount > 0
        ? ((currentAmount - previousAmount) / previousAmount) * 100
        : 0.0;
    final isIncrease = change > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIncrease ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: isIncrease ? AppTheme.expense : AppTheme.income,
        ),
        const SizedBox(width: 4),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isIncrease ? AppTheme.expense : AppTheme.income,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'vs $period',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
