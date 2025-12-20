import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/budget.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_state.dart';
import 'package:flutter_finance_assistant/presentation/screens/budget/budget_detail_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/budget/widgets/budget_widgets.dart';

/// Screen displaying all budgets with summary and alerts.
class BudgetListScreen extends StatelessWidget {
  final String? userId;

  const BudgetListScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    // Check if BudgetBloc is registered in DI
    final isBlocRegistered = sl.isRegistered<BudgetBloc>();

    if (!isBlocRegistered || userId == null || userId!.isEmpty) {
      return const _BudgetPlaceholder();
    }

    return BlocProvider(
      create: (context) =>
          sl<BudgetBloc>()..add(BudgetWatchRequested(userId: userId!)),
      child: const _BudgetListView(),
    );
  }
}

/// Placeholder shown when BudgetBloc is not yet available.
class _BudgetPlaceholder extends StatelessWidget {
  const _BudgetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Budgets',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetListView extends StatelessWidget {
  const _BudgetListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<BudgetBloc, BudgetState>(
          listener: (context, state) {
            if (state is BudgetOperationSuccess) {
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
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  toolbarHeight: 70,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budgets',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildSubtitle(state, isDark),
                    ],
                  ),
                  actions: [
                    // Add Budget Button
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        onPressed: () => _showCreateBudgetSheet(context),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.primaryDark.withValues(alpha: 0.2)
                                : AppTheme.primaryLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            color: isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _buildContent(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubtitle(BudgetState state, bool isDark) {
    if (state is BudgetLoaded) {
      final alertCount =
          state.exceededBudgets.length + state.warningBudgets.length;

      if (alertCount > 0) {
        return Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: state.exceededBudgets.isNotEmpty
                    ? AppTheme.error
                    : AppTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$alertCount budget${alertCount > 1 ? 's' : ''} need attention',
              style: TextStyle(
                fontSize: 12,
                color: state.exceededBudgets.isNotEmpty
                    ? AppTheme.error
                    : AppTheme.warning,
              ),
            ),
          ],
        );
      }

      return Text(
        '${state.budgets.length} active budget${state.budgets.length != 1 ? 's' : ''}',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildContent(BuildContext context, BudgetState state) {
    if (state is BudgetLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is BudgetError) {
      return SliverFillRemaining(
        child: _BudgetErrorWidget(
          message: state.message,
          onRetry: () {
            // Retry loading
          },
        ),
      );
    }

    if (state is BudgetLoaded) {
      if (state.budgets.isEmpty) {
        return const SliverFillRemaining(child: _EmptyBudgetsWidget());
      }

      return SliverList(
        delegate: SliverChildListDelegate([
          // Summary Card
          BudgetSummaryCard(
            totalBudgeted: state.totalBudgeted,
            totalSpent: state.totalSpent,
            overallProgress: state.overallProgress,
            budgetCount: state.budgets.length,
          ),
          const SizedBox(height: 20),

          // Alerts Section (if any)
          if (state.hasAlerts) ...[
            _SectionHeader(
              title: 'Needs Attention',
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.warning,
            ),
            const SizedBox(height: 12),
            ...state.exceededBudgets.map(
              (budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetItemCard(
                  budget: budget,
                  onTap: () => _navigateToBudgetDetail(context, budget),
                  showAlert: true,
                ),
              ),
            ),
            ...state.warningBudgets.map(
              (budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetItemCard(
                  budget: budget,
                  onTap: () => _navigateToBudgetDetail(context, budget),
                  showAlert: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // All Budgets Section
          _SectionHeader(
            title: 'All Budgets',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 12),
          ...state.budgets
              .where((b) => !b.isExceeded && !b.isWarning)
              .map(
                (budget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BudgetItemCard(
                    budget: budget,
                    onTap: () => _navigateToBudgetDetail(context, budget),
                  ),
                ),
              ),

          // Bottom padding for FAB
          const SizedBox(height: 80),
        ]),
      );
    }

    return const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _showCreateBudgetSheet(BuildContext context) {
    final budgetBloc = context.read<BudgetBloc>();
    final authBloc = context.read<AuthBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: budgetBloc),
          BlocProvider.value(value: authBloc),
        ],
        child: const CreateBudgetSheet(),
      ),
    );
  }

  void _navigateToBudgetDetail(BuildContext context, Budget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetDetailScreen(budgetId: budget.id),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? (isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class _EmptyBudgetsWidget extends StatelessWidget {
  const _EmptyBudgetsWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.primaryDark.withValues(alpha: 0.1)
                    : AppTheme.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Budgets Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first budget to start\ntracking your spending',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final budgetBloc = context.read<BudgetBloc>();
                final authBloc = context.read<AuthBloc>();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: budgetBloc),
                      BlocProvider.value(value: authBloc),
                    ],
                    child: const CreateBudgetSheet(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.primaryDark
                    : AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _BudgetErrorWidget({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
