import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../services/app_tour.dart';
import '../theme/app_theme.dart';
import '../utils/session.dart';
import '../widgets/dashboard_shell_scope.dart';
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

  /// Re-exported so existing call sites keep compiling, but tab switching now
  /// goes through [DashboardShellScope] rather than a static callback.
  static const int tabHome = DashboardShellScope.tabHome;
  static const int tabTransactions = DashboardShellScope.tabTransactions;
  static const int tabBudget = DashboardShellScope.tabBudget;
  static const int tabSavings = DashboardShellScope.tabSavings;
  static const int tabLearning = DashboardShellScope.tabLearning;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// The visible tab, held in a notifier so the "View All" links inside the
  /// child views can switch tabs through the scope without a static callback.
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // The walkthrough runs only for a brand new student. An account that
    // already has data has seen everything it describes, and interrupting
    // them on an app update would be worse than useless.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FinanceController.instance.transactions.isNotEmpty) return;
      if (FinanceController.instance.savingGoals.isNotEmpty) return;
      AppTour.maybeShow(
        context,
        locate: TourKeys.locate,
        steps: buildTourSteps(),
      );
    });
  }

  @override
  void dispose() {
    _tabIndex.dispose();
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
      // Rebuilds on a tab change from any child view's "View All" link, and on
      // any finance data change.
      listenable: Listenable.merge([FinanceController.instance, _tabIndex]),
      builder: (context, _) {
        final c = FinanceController.instance;

        return DashboardShellScope(
          tabIndex: _tabIndex,
          child: Scaffold(
            // Scaffold insists on a PreferredSizeWidget, so the anchor wrapper
            // sits inside one rather than around the AppBar itself.
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: TourKeys.wrap(
                TourAnchors.topBar,
                AppBar(
                  title: const PennyPalWordmark(),
                  actions: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () =>
                          _push(context, const NotificationsScreen()),
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
              ),
            ),
            body: IndexedStack(index: _tabIndex.value, children: _views),
            floatingActionButton: TourKeys.wrap(
              TourAnchors.addButton,
              _fabFor(_tabIndex.value) ?? const SizedBox.shrink(),
            ),
            bottomNavigationBar: TourKeys.wrap(
              TourAnchors.bottomNav,
              Container(
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
                  selectedIndex: _tabIndex.value,
                  onDestinationSelected: (i) => _tabIndex.value = i,
                  destinations: _destinations,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

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
