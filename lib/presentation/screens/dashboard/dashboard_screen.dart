import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_event.dart';
import 'package:flutter_finance_assistant/presentation/bloc/sync/sync_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/ai_search_bar.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/anomaly_alert_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/balance_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/budget_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/categories_progress_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/quick_actions_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/recent_transactions_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/scan_receipt_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/widgets/spending_chart_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final SyncBloc _syncBloc;

  @override
  void initState() {
    super.initState();
    _syncBloc = sl<SyncBloc>();
    // Initialize sync and start listening for connectivity
    _syncBloc.add(const SyncInitialized());
  }

  @override
  void dispose() {
    _syncBloc.close();
    super.dispose();
  }

  /// Trigger sync and show feedback to user
  void _onRefreshPressed() {
    _syncBloc.add(const SyncAllRequested());
  }

  /// Get status text based on sync state
  String _getSyncStatusText(SyncState state) {
    if (state is SyncInProgress) {
      return 'Syncing...';
    } else if (state is SyncCompleted) {
      return 'Updated just now';
    } else if (state is SyncOffline) {
      return 'Offline - ${state.pendingCount} pending';
    } else if (state is SyncPartialSuccess) {
      return 'Synced with ${state.failedCount} errors';
    } else if (state is SyncError) {
      return 'Sync failed';
    }
    return 'Updated just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _syncBloc,
      child: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          // Show snackbar feedback for sync states
          if (state is SyncCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Synced ${state.itemsSynced} items successfully'),
                  ],
                ),
                backgroundColor: AppTheme.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppTheme.error,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _onRefreshPressed,
                ),
              ),
            );
          } else if (state is SyncOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Offline - ${state.pendingCount} changes pending'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is SyncPartialSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Synced with ${state.failedCount} errors'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    _syncBloc.add(const SyncRetryFailedRequested());
                  },
                ),
              ),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: CustomScrollView(
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
                        'Overview',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      BlocBuilder<SyncBloc, SyncState>(
                        builder: (context, state) {
                          return Row(
                            children: [
                              if (state is SyncInProgress) ...[
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _getSyncStatusText(state),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      state is SyncOffline || state is SyncError
                                      ? Colors.orange
                                      : theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '3 anomalies detected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    // User Avatar with dropdown menu
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: BlocBuilder<SyncBloc, SyncState>(
                        builder: (context, state) {
                          final isSyncing = state is SyncInProgress;
                          return PopupMenuButton<String>(
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'sync') {
                                _onRefreshPressed();
                              } else if (value == 'logout') {
                                context.read<AuthBloc>().add(
                                  const AuthSignOutRequested(),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'sync',
                                enabled: !isSyncing,
                                child: Row(
                                  children: [
                                    if (isSyncing)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.primary,
                                              ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.sync,
                                        size: 20,
                                        color: theme.iconTheme.color,
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isSyncing ? 'Syncing...' : 'Sync data',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 20,
                                      color: AppTheme.error,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Logout',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: AppTheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'JD',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // AI Search Bar
                      const AiSearchBar(),
                      const SizedBox(height: 16),

                      // Anomaly Alert
                      const AnomalyAlertCard(
                        title: 'Anomaly Detected',
                        description: 'We noticed a double charge of',
                        amount: 14.99,
                        merchant: 'Netflix',
                        actionText: 'Review',
                      ),
                      const SizedBox(height: 20),

                      // Key Metrics Row
                      const _MetricsRow(),
                      const SizedBox(height: 20),

                      // Analytics & Transactions
                      const _AnalyticsSection(),
                      const SizedBox(height: 20),

                      // Categories & Quick Actions
                      const _BottomSection(),
                      const SizedBox(height: 80), // Space for bottom nav
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Tablet/Desktop layout
          return Row(
            children: [
              Expanded(
                child: BalanceCard(
                  balance: 24500.80,
                  changeAmount: 1240,
                  changePercent: 5.2,
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BudgetCard(
                  spent: 1850,
                  total: 2400,
                  savingsMessage:
                      "You're on track to save \$150 more than usual.",
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: ScanReceiptCard()),
            ],
          );
        }
        // Mobile layout - Stack vertically
        return Column(
          children: [
            BalanceCard(
              balance: 24500.80,
              changeAmount: 1240,
              changePercent: 5.2,
              isPositive: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BudgetCard(
                    spent: 1850,
                    total: 2400,
                    savingsMessage: "You're on track to save \$150 more.",
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: ScanReceiptCard()),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 2, child: SpendingChartCard()),
              const SizedBox(width: 16),
              const Expanded(child: RecentTransactionsCard()),
            ],
          );
        }
        return Column(
          children: [
            const SpendingChartCard(),
            const SizedBox(height: 16),
            const RecentTransactionsCard(),
          ],
        );
      },
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: CategoriesProgressCard()),
              const SizedBox(width: 16),
              const Expanded(child: QuickActionsCard()),
            ],
          );
        }
        return Column(
          children: [
            const CategoriesProgressCard(),
            const SizedBox(height: 16),
            const QuickActionsCard(),
          ],
        );
      },
    );
  }
}
