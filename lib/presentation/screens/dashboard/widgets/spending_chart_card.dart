import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Spending analysis chart card with weekly/monthly toggle
class SpendingChartCard extends StatefulWidget {
  final VoidCallback? onTap;

  const SpendingChartCard({
    super.key,
    this.onTap,
  });

  @override
  State<SpendingChartCard> createState() => _SpendingChartCardState();
}

class _SpendingChartCardState extends State<SpendingChartCard> {
  bool _isWeekView = true;

  // Sample data for the chart
  final List<_ChartData> _weekData = [
    _ChartData('Mon', 120, false),
    _ChartData('Tue', 80, false),
    _ChartData('Wed', 180, true), // High spend
    _ChartData('Thu', 100, false),
    _ChartData('Fri', 200, false, isSelected: true),
    _ChartData('Sat', 60, false),
    _ChartData('Sun', 90, false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxValue = _weekData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Analysis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              // Toggle Buttons
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Week', _isWeekView, isDark, () {
                      setState(() => _isWeekView = true);
                    }),
                    _buildToggleButton('Month', !_isWeekView, isDark, () {
                      setState(() => _isWeekView = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weekData.map((data) {
                final heightRatio = data.value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bar
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Handle bar tap
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: data.isSelected
                                    ? (isDark ? Colors.white : theme.primaryColor)
                                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                boxShadow: data.isSelected
                                    ? [
                                        BoxShadow(
                                          color: (isDark ? Colors.white : theme.primaryColor)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: FractionallySizedBox(
                                heightFactor: heightRatio,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: data.isHighSpend
                                        ? AppTheme.expense.withValues(alpha: 0.3)
                                        : (data.isSelected
                                            ? theme.primaryColor
                                            : const Color(0xFF6366F1).withValues(alpha: 0.2)),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: data.isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: data.isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white10 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final bool isHighSpend;
  final bool isSelected;

  _ChartData(this.label, this.value, this.isHighSpend, {this.isSelected = false});
}
