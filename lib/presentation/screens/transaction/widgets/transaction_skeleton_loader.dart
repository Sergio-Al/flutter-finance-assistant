import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Shimmer loading placeholder for transaction items.
class TransactionSkeletonLoader extends StatefulWidget {
  final int itemCount;
  final bool showHeader;
  final bool showSummary;

  const TransactionSkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.showHeader = true,
    this.showSummary = true,
  });

  @override
  State<TransactionSkeletonLoader> createState() =>
      _TransactionSkeletonLoaderState();
}

class _TransactionSkeletonLoaderState extends State<TransactionSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              // Summary card skeleton
              if (widget.showSummary) ...[
                _SummarySkeleton(
                  shimmerValue: _shimmerController.value,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],

              // Date header skeleton
              if (widget.showHeader) ...[
                _DateHeaderSkeleton(
                  shimmerValue: _shimmerController.value,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
              ],

              // Transaction items skeleton
              ...List.generate(
                widget.itemCount,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransactionItemSkeleton(
                    shimmerValue: _shimmerController.value,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Single transaction item skeleton.
class _TransactionItemSkeleton extends StatelessWidget {
  final double shimmerValue;
  final bool isDark;

  const _TransactionItemSkeleton({
    required this.shimmerValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon placeholder
          _ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: 12,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  width: 120,
                  height: 14,
                  borderRadius: 4,
                  shimmerValue: shimmerValue,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _ShimmerBox(
                  width: 80,
                  height: 10,
                  borderRadius: 4,
                  shimmerValue: shimmerValue,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          // Amount placeholder
          _ShimmerBox(
            width: 70,
            height: 18,
            borderRadius: 4,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Summary card skeleton.
class _SummarySkeleton extends StatelessWidget {
  final double shimmerValue;
  final bool isDark;

  const _SummarySkeleton({required this.shimmerValue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          _ShimmerBox(
            width: 100,
            height: 12,
            borderRadius: 4,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          // Amount
          _ShimmerBox(
            width: 150,
            height: 32,
            borderRadius: 6,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          // Row of stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  _ShimmerBox(
                    width: 60,
                    height: 10,
                    borderRadius: 4,
                    shimmerValue: shimmerValue,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _ShimmerBox(
                    width: 80,
                    height: 16,
                    borderRadius: 4,
                    shimmerValue: shimmerValue,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date header skeleton.
class _DateHeaderSkeleton extends StatelessWidget {
  final double shimmerValue;
  final bool isDark;

  const _DateHeaderSkeleton({required this.shimmerValue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ShimmerBox(
            width: 36,
            height: 36,
            borderRadius: 10,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(
                width: 80,
                height: 12,
                borderRadius: 4,
                shimmerValue: shimmerValue,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              _ShimmerBox(
                width: 50,
                height: 10,
                borderRadius: 4,
                shimmerValue: shimmerValue,
                isDark: isDark,
              ),
            ],
          ),
          const Spacer(),
          _ShimmerBox(
            width: 60,
            height: 14,
            borderRadius: 4,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Shimmer box widget with animation.
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double shimmerValue;
  final bool isDark;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2 * shimmerValue, 0),
          end: Alignment(-0.5 + 2 * shimmerValue, 0),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Filter bar skeleton.
class TransactionFilterBarSkeleton extends StatelessWidget {
  final double shimmerValue;

  const TransactionFilterBarSkeleton({super.key, this.shimmerValue = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ShimmerBox(
              width: double.infinity,
              height: 44,
              borderRadius: 12,
              shimmerValue: shimmerValue,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          _ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: 12,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: 12,
            shimmerValue: shimmerValue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// Quick stats row skeleton.
class QuickStatsRowSkeleton extends StatelessWidget {
  final int count;
  final double shimmerValue;

  const QuickStatsRowSkeleton({
    super.key,
    this.count = 3,
    this.shimmerValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _QuickStatSkeleton(shimmerValue: shimmerValue, isDark: isDark),
      ),
    );
  }
}

class _QuickStatSkeleton extends StatelessWidget {
  final double shimmerValue;
  final bool isDark;

  const _QuickStatSkeleton({required this.shimmerValue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ShimmerBox(
                  width: 28,
                  height: 28,
                  borderRadius: 8,
                  shimmerValue: shimmerValue,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _ShimmerBox(
                  width: 60,
                  height: 10,
                  borderRadius: 4,
                  shimmerValue: shimmerValue,
                  isDark: isDark,
                ),
              ],
            ),
            const Spacer(),
            _ShimmerBox(
              width: 80,
              height: 20,
              borderRadius: 4,
              shimmerValue: shimmerValue,
              isDark: isDark,
            ),
            const SizedBox(height: 4),
            _ShimmerBox(
              width: 50,
              height: 10,
              borderRadius: 4,
              shimmerValue: shimmerValue,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}
