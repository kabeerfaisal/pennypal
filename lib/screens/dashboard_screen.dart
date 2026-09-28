import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../theme/app_theme.dart';
import '../utils/session.dart';
import '../widgets/ui_kit.dart';
import 'about_screen.dart';
import 'add_transaction_screen.dart';
import 'admin/admin_shell.dart' show AdminShell;
import 'ai_chatbot_screen.dart';
import 'budget_view.dart';
import 'contact_support_screen.dart';
import 'feedback_screen.dart';
import 'home_view.dart';
import 'learning_view.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'savings_goals_screen.dart';
import 'transactions_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  /// Tab indices, so child screens never hard code numbers.
  static const int tabHome = 0;
  static const int tabTransactions = 1;
  static const int tabBudget = 2;
  static const int tabSavings = 3;
  static const int tabLearning = 4;

  /// Switches the shell tab, e.g. from the "View All" links on Home.
  static void goToTab(int index) => _switcher?.call(index);

  static void Function(int index)? _switcher;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    DashboardScreen._switcher = (i) {
      if (mounted && i != _index) setState(() => _index = i);
    };
  }

  @override
  void dispose() {
    DashboardScreen._switcher = null;
    super.dispose();
  }

  static const List<Widget> _views = [
    HomeView(),
    TransactionsView(),
    BudgetView(),
    SavingsGoalsScreen(),
    LearningView(),
  ];

  static const List<Widget> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.grid_view_rounded),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: 'Transactions',
    ),
    NavigationDestination(
      icon: Icon(Icons.donut_large_outlined),
      selectedIcon: Icon(Icons.donut_large_rounded),
      label: 'Budget',
    ),
    NavigationDestination(
      icon: Icon(Icons.savings_outlined),
      selectedIcon: Icon(Icons.savings_rounded),
      label: 'Savings',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Learning',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;

        return Scaffold(
          appBar: AppBar(
            title: const PennyPalWordmark(),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => _push(context, const NotificationsScreen()),
              ),
              IconButton(
                tooltip: 'Platform Stats',
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () => _showStatsSheet(context, c),
              ),
              IconButton(
                tooltip: c.isAdmin ? 'Admin Panel' : 'Profile',
                icon: Icon(
                  c.isAdmin
                      ? Icons.shield_outlined
                      : Icons.person_outline_rounded,
                ),
                onPressed: () => c.isAdmin
                    ? _openAdmin(context)
                    : _push(context, const ProfileScreen()),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'ai':
                      _push(context, const AIChatbotScreen());
                    case 'profile':
                      _push(context, const ProfileScreen());
                    case 'feedback':
                      _push(context, const FeedbackScreen());
                    case 'support':
                      _push(context, const ContactSupportScreen());
                    case 'about':
                      _push(context, const AboutScreen());
                    case 'logout':
                      logoutAndGoToLogin(context);
                  }
                },
                itemBuilder: (context) => [
                  // The AI advisor moved off the app bar and into the overflow
                  // menu, which is where it stops crowding the header.
                  const PopupMenuItem(
                    value: 'ai',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.smart_toy_outlined),
                      title: Text('AI Advisor'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline_rounded),
                      title: Text('Profile & Settings'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'feedback',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.feedback_outlined),
                      title: Text('Feedback & Queries'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'support',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.support_agent_rounded),
                      title: Text('Contact Support'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('About'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Logout'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(index: _index, children: _views),
          // One FAB for the whole shell, so Add Transaction and New Goal are
          // reachable from every tab without a second button in each list.
          floatingActionButton: _fabFor(_index),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : AppColors.border,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _destinations,
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// The primary action for the visible tab. Transactions and savings both
  /// used to hide their add button whenever the list was not empty, which made
  /// a second goal or transaction impossible to add from inside the tab.
  Widget? _fabFor(int index) {
    switch (index) {
      case DashboardScreen.tabSavings:
        return FloatingActionButton.extended(
          heroTag: 'fab-savings',
          onPressed: () => SavingsGoalsScreen.showAddSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Goal'),
        );
      case DashboardScreen.tabLearning:
        return null;
      default:
        return FloatingActionButton.extended(
          heroTag: 'fab-transaction',
          onPressed: () => _push(context, const AddTransactionScreen()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Transaction'),
        );
    }
  }

  void _openAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminShell()),
    );
  }

  /// Quick read-only numbers, matching the mockup's stats action.
  void _showStatsSheet(BuildContext context, FinanceController c) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text(
              'Platform Stats',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Your money at a glance',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Transactions',
                    value: '${c.transactions.length}',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpace.gap),
                Expanded(
                  child: StatCard(
                    label: 'Savings Goals',
                    value: '${c.savingGoals.length}',
                    icon: Icons.savings_rounded,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.gap),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Spent This Month',
                    value:
                        '${c.currencySymbol}${c.totalExpenses.toStringAsFixed(2)}',
                    icon: Icons.trending_down_rounded,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(width: AppSpace.gap),
                Expanded(
                  child: StatCard(
                    label: 'Income This Month',
                    value:
                        '${c.currencySymbol}${c.totalIncome.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
