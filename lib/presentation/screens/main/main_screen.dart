import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_state.dart';
import 'package:flutter_finance_assistant/presentation/screens/budget/budget_list_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_finance_assistant/presentation/screens/main/widgets/main_bottom_nav.dart';
import 'package:flutter_finance_assistant/presentation/screens/transaction/transaction_list_screen.dart';

/// Main screen with bottom navigation.
///
/// Contains the primary app sections:
/// - Home (Dashboard)
/// - Transactions
/// - Budgets
/// - Chat (AI Assistant)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _primaryAccountId;
  bool _isLoadingAccount = true;

  @override
  void initState() {
    super.initState();
    _loadPrimaryAccount();
  }

  Future<void> _loadPrimaryAccount() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final database = sl<AppDatabase>();
      final accounts = await database.accountsDao.getAllAccounts(
        authState.userId,
      );
      if (accounts.isNotEmpty && mounted) {
        setState(() {
          _primaryAccountId = accounts.first.id;
          _isLoadingAccount = false;
        });
      } else {
        setState(() {
          _isLoadingAccount = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _buildScreens(String userId) {
    // Use the actual account ID if available, otherwise show loading or empty state
    final accountId = _primaryAccountId ?? userId;
    return [
      const DashboardScreen(),
      _isLoadingAccount
          ? const Center(child: CircularProgressIndicator())
          : TransactionListScreen(accountId: accountId),
      BudgetListScreen(userId: userId),
      const _ChatPlaceholder(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState is AuthAuthenticated ? authState.userId : '';
        final screens = _buildScreens(userId);

        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Navigate to login if user signs out
            if (state is AuthUnauthenticated) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          },
          child: Scaffold(
            body: IndexedStack(index: _currentIndex, children: screens),
            bottomNavigationBar: MainBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
            floatingActionButton: _buildFAB(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
          ),
        );
      },
    );
  }

  Widget? _buildFAB() {
    // Only show FAB on Home tab (Transactions has its own FAB)
    if (_currentIndex != 0) return null;

    return FloatingActionButton(
      heroTag: 'main_screen_fab',
      onPressed: () => _showAddOptions(context),
      backgroundColor: AppTheme.primaryLight,
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddOptionsSheet(),
    );
  }
}

/// Bottom sheet with quick add options
class _AddOptionsSheet extends StatelessWidget {
  const _AddOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Quick Add',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AddOptionItem(
                icon: Icons.remove_circle_outline,
                label: 'Expense',
                color: AppTheme.expense,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/transactions/add',
                    arguments: {'type': 'expense'},
                  );
                },
              ),
              _AddOptionItem(
                icon: Icons.add_circle_outline,
                label: 'Income',
                color: AppTheme.income,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/transactions/add',
                    arguments: {'type': 'income'},
                  );
                },
              ),
              _AddOptionItem(
                icon: Icons.swap_horiz,
                label: 'Transfer',
                color: AppTheme.transfer,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/transactions/add',
                    arguments: {'type': 'transfer'},
                  );
                },
              ),
              _AddOptionItem(
                icon: Icons.receipt_long,
                label: 'Scan',
                color: AppTheme.info,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/receipts/scan');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AddOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddOptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Placeholder screens (to be replaced with actual implementations)
// ══════════════════════════════════════════════════════════════════════════════

class _ChatPlaceholder extends StatelessWidget {
  const _ChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'AI Assistant',
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
