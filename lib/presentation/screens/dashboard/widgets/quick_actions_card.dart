import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card with quick action buttons
class QuickActionsCard extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final VoidCallback? onConnectBank;
  final VoidCallback? onExportCsv;

  const QuickActionsCard({
    super.key,
    this.onAddTransaction,
    this.onConnectBank,
    this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : theme.primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add Manual Transaction',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Connect Bank',
                  onTap: onConnectBank,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryActionButton(
                  label: 'Export CSV',
                  onTap: onExportCsv,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _SecondaryActionButton({
    required this.label,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
