import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// Multi-select actions bar for bulk delete/categorize transactions.
class TransactionBulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final double? totalAmount;
  final VoidCallback onClose;
  final VoidCallback? onDelete;
  final VoidCallback? onCategorize;
  final VoidCallback? onExport;
  final VoidCallback? onSelectAll;
  final bool isAllSelected;

  const TransactionBulkActionsBar({
    super.key,
    required this.selectedCount,
    this.totalAmount,
    required this.onClose,
    this.onDelete,
    this.onCategorize,
    this.onExport,
    this.onSelectAll,
    this.isAllSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Close button, count badge, and select all
              Row(
                children: [
                  // Close button
                  _ActionIconButton(
                    icon: Icons.close,
                    onTap: onClose,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),

                  // Selection count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$selectedCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'selected',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total amount (if available)
                  if (totalAmount != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      '\$${totalAmount!.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Select all button
                  if (onSelectAll != null)
                    TextButton.icon(
                      onPressed: onSelectAll,
                      icon: Icon(
                        isAllSelected ? Icons.deselect : Icons.select_all,
                        size: 18,
                      ),
                      label: Text(isAllSelected ? 'Deselect' : 'Select All'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.grey[400] : Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Bottom row: Action buttons
              Row(
                children: [
                  if (onCategorize != null)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        onTap: onCategorize!,
                        isDark: isDark,
                      ),
                    ),
                  if (onCategorize != null && onExport != null)
                    const SizedBox(width: 8),
                  if (onExport != null)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.file_download_outlined,
                        label: 'Export',
                        onTap: onExport!,
                        isDark: isDark,
                      ),
                    ),
                  if ((onCategorize != null || onExport != null) &&
                      onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: onDelete!,
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : Colors.black87,
        ),
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
        : (isDark ? Colors.white : Colors.black87);
    final bgColor = isDestructive
        ? AppTheme.expense.withValues(alpha: 0.1)
        : (isDark ? Colors.grey[800] : Colors.grey[100]);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating bulk actions bar that slides up from bottom.
class FloatingBulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final double? totalAmount;
  final VoidCallback onClose;
  final VoidCallback? onDelete;
  final VoidCallback? onCategorize;
  final VoidCallback? onExport;
  final bool visible;

  const FloatingBulkActionsBar({
    super.key,
    required this.selectedCount,
    this.totalAmount,
    required this.onClose,
    this.onDelete,
    this.onCategorize,
    this.onExport,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: visible ? 16 : -100,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Selection count badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$selectedCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    if (totalAmount != null)
                      Text(
                        '\$${totalAmount!.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),

              // Quick actions
              _FloatingActionButton(
                icon: Icons.category,
                onTap: onCategorize,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _FloatingActionButton(
                icon: Icons.delete_outline,
                onTap: onDelete,
                isDark: isDark,
                isDestructive: true,
              ),
              const SizedBox(width: 8),
              _FloatingActionButton(
                icon: Icons.close,
                onTap: onClose,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isDestructive;

  const _FloatingActionButton({
    required this.icon,
    this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.expense : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// Category selection sheet for bulk categorization.
class BulkCategorizeSheet extends StatelessWidget {
  final int selectedCount;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;

  const BulkCategorizeSheet({
    super.key,
    required this.selectedCount,
    required this.categories,
    required this.onCategorySelected,
  });

  static Future<void> show(
    BuildContext context, {
    required int selectedCount,
    required List<String> categories,
    required ValueChanged<String> onCategorySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkCategorizeSheet(
        selectedCount: selectedCount,
        categories: categories,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Categorize $selectedCount Transactions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  return GestureDetector(
                    onTap: () {
                      onCategorySelected(category);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconConstants.getIcon(category),
                            size: 18,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Delete confirmation dialog for bulk deletion.
class BulkDeleteConfirmDialog extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onConfirm;

  const BulkDeleteConfirmDialog({
    super.key,
    required this.selectedCount,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int selectedCount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => BulkDeleteConfirmDialog(
        selectedCount: selectedCount,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Transactions'),
      content: Text(
        'Are you sure you want to delete $selectedCount transactions? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: AppTheme.expense),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
