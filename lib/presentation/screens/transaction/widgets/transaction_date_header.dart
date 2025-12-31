import 'package:flutter/material.dart';

/// Sticky date header for grouping transactions by day/week/month.
class TransactionDateHeader extends StatelessWidget {
  final DateTime date;
  final double? totalAmount;
  final int? transactionCount;
  final bool isSticky;

  const TransactionDateHeader({
    super.key,
    required this.date,
    this.totalAmount,
    this.transactionCount,
    this.isSticky = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSticky
            ? (isDark ? const Color(0xFF121212) : Colors.white)
            : (isDark
                  ? Colors.grey[900]?.withValues(alpha: 0.5)
                  : Colors.grey[50]),
        border: isSticky
            ? Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Date Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDateLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (transactionCount != null)
                  Text(
                    '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          // Total Amount (if provided)
          if (totalAmount != null)
            Text(
              '\$${totalAmount!.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: totalAmount! >= 0
                    ? const Color(0xFF52B788)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return _getDayName(date.weekday);
    } else if (date.year == now.year) {
      return '${_getMonthName(date.month)} ${date.day}';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Sliver version of date header for use in CustomScrollView.
class SliverTransactionDateHeader extends StatelessWidget {
  final DateTime date;
  final double? totalAmount;
  final int? transactionCount;

  const SliverTransactionDateHeader({
    super.key,
    required this.date,
    this.totalAmount,
    this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _DateHeaderDelegate(
        date: date,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;
  final double? totalAmount;
  final int? transactionCount;

  _DateHeaderDelegate({
    required this.date,
    this.totalAmount,
    this.transactionCount,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return TransactionDateHeader(
      date: date,
      totalAmount: totalAmount,
      transactionCount: transactionCount,
      isSticky: overlapsContent || shrinkOffset > 0,
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return date != oldDelegate.date ||
        totalAmount != oldDelegate.totalAmount ||
        transactionCount != oldDelegate.transactionCount;
  }
}
