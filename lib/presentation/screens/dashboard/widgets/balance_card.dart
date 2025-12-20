import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card displaying total balance with change indicator
class BalanceCard extends StatefulWidget {
  final double balance;
  final double changeAmount;
  final double changePercent;
  final bool isPositive;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.changeAmount,
    required this.changePercent,
    this.isPositive = true,
    this.onTap,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: widget.onTap,
      height: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BALANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
          // Balance Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBalanceVisible
                    ? '${AppConstants.defaultCurrencySymbol}${_formatNumber(widget.balance)}'
                    : '${AppConstants.defaultCurrencySymbol}••••••',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Change Indicator
              Row(
                children: [
                  Icon(
                    widget.isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: widget.isPositive ? AppTheme.income : AppTheme.expense,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.isPositive ? '+' : '-'}${AppConstants.defaultCurrencySymbol}${_formatNumber(widget.changeAmount)} (${widget.changePercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isPositive ? AppTheme.income : AppTheme.expense,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'vs last month',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return number.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return number.toStringAsFixed(2);
  }
}
