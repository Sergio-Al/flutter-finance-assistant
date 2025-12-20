import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_state.dart';
import 'package:flutter_finance_assistant/presentation/screens/budget/widgets/budget_widgets.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Screen displaying detailed view of a single budget.
class BudgetDetailScreen extends StatelessWidget {
  final String budgetId;

  const BudgetDetailScreen({
    super.key,
    required this.budgetId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BudgetBloc>()
        ..add(BudgetCheckStatusRequested(budgetId: budgetId)),
      child: _BudgetDetailView(budgetId: budgetId),
    );
  }
}

class _BudgetDetailView extends StatelessWidget {
  final String budgetId;

  const _BudgetDetailView({required this.budgetId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetOperationSuccess) {
            if (state.operation == BudgetOperationType.delete) {
              Navigator.pop(context);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.success,
              ),
            );
          } else if (state is BudgetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BudgetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BudgetDetailLoaded) {
            return _buildDetailContent(context, state.budget, isDark);
          }

          if (state is BudgetError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    Budget budget,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App Bar with status color
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: _getStatusColor(budget),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStatusColor(budget),
                    _getStatusColor(budget).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      Text(
                        budget.category?.name ?? 'Budget',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Period Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          budget.period.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditBudgetSheet(context, budget);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, budget);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 12),
                      Text('Edit Budget'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Progress Card
              _BudgetProgressCard(budget: budget),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Spent',
                      value:
                          '${AppConstants.defaultCurrencySymbol}${budget.spentAmount.toStringAsFixed(2)}',
                      icon: Icons.arrow_upward,
                      iconColor: AppTheme.expense,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Remaining',
                      value:
                          '${AppConstants.defaultCurrencySymbol}${budget.remainingAmount.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      iconColor: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Daily Budget',
                      value:
                          '${AppConstants.defaultCurrencySymbol}${budget.dailyBudgetRemaining.toStringAsFixed(2)}',
                      icon: Icons.today,
                      iconColor: AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Days Left',
                      value: '${budget.daysRemaining}',
                      icon: Icons.calendar_today,
                      iconColor: isDark ? Colors.grey[400]! : Colors.grey[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Period Info
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Period',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Start Date',
                      value: _formatDate(budget.startDate),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'End Date',
                      value: _formatDate(budget.endDate),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Rollover',
                      value: budget.rollover ? 'Enabled' : 'Disabled',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Alert Threshold',
                      value: '${(budget.alertThreshold * 100).toInt()}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Transactions in this budget (placeholder)
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Transaction history coming soon',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(Budget budget) {
    if (budget.isExceeded) return AppTheme.error;
    if (budget.isDanger) return AppTheme.error.withValues(alpha: 0.8);
    if (budget.isWarning) return AppTheme.warning;
    return AppTheme.success;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditBudgetSheet(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBudgetSheet(budget: budget),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Budget budget) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
          'Are you sure you want to delete this budget? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BudgetBloc>().add(
                    BudgetDeleteRequested(budgetId: budget.id),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final Budget budget;

  const _BudgetProgressCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        children: [
          // Amount Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppConstants.defaultCurrencySymbol}${budget.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Progress Circle
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: budget.progressCapped,
                      strokeWidth: 6,
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.getBudgetStatusColor(budget.progress),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${budget.progressPercent}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Linear Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: budget.progressCapped,
              minHeight: 10,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.getBudgetStatusColor(budget.progress),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Status Message
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(budget),
                size: 16,
                color: AppTheme.getBudgetStatusColor(budget.progress),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusMessage(budget),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getBudgetStatusColor(budget.progress),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(Budget budget) {
    if (budget.isExceeded) return Icons.error;
    if (budget.isWarning) return Icons.warning_amber;
    return Icons.check_circle;
  }

  String _getStatusMessage(Budget budget) {
    if (budget.isExceeded) {
      return 'Over budget by ${AppConstants.defaultCurrencySymbol}${(budget.spentAmount - budget.amount).toStringAsFixed(2)}';
    }
    if (budget.isWarning) {
      return 'Approaching budget limit';
    }
    return 'On track - ${budget.daysRemaining} days remaining';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
