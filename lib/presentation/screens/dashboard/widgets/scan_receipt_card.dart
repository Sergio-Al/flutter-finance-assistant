import 'package:flutter/material.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Card button for scanning receipts using OCR
class ScanReceiptCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ScanReceiptCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      height: 130,
      isDashed: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          // Label
          Text(
            'Scan Receipt (OCR)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
