import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../services/app_tour.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_shell_scope.dart';
import '../widgets/ui_kit.dart';
import 'add_transaction_screen.dart';
import 'ai_chatbot_screen.dart';
import 'dashboard_screen.dart';
import 'savings_goals_screen.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;
        final sym = c.currencySymbol;
        final expenses = c.totalExpenses;
        final income = c.totalIncome;
        final budget = c.monthlyBudget;
        final percent = budget > 0 ? expenses / budget : 0.0;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final muted = isDark ? Colors.white60 : AppColors.textMuted;

        return ListView(
          // Extra bottom room for the shell's floating action button.
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.gutter,
            AppSpace.gutter,
            96,
          ),
          children: [
            // The in-body top bar. Its AI chip is the live link to the advisor.
            TourKeys.wrap(
              TourAnchors.aiLink,
              WelcomeBanner(
                name: c.userName,
                role: c.userRole,
                onTapAi: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIChatbotScreen()),
                ),
              ),
            ),

            const SizedBox(height: AppSpace.gap),

            // Three headline numbers, as in the mockup.
            TourKeys.wrap(
              TourAnchors.statCards,
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Available Balance',
                      value: '$sym${(income - expenses).toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: AppSpace.gap),
                  Expanded(
                    child: StatCard(
                      label: 'Monthly Spent',
                      value: '$sym${expenses.toStringAsFixed(2)}',
                      icon: Icons.trending_down_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                  const SizedBox(width: AppSpace.gap),
                  Expanded(
                    child: StatCard(
                      label: 'Total Income',
                      value: '$sym${income.toStringAsFixed(2)}',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.section),

            SectionHeader(
              title: 'Savings Goals',
              actionLabel: c.savingGoals.isEmpty ? null : 'View All',
              actionTab: DashboardScreen.tabSavings,
            ),
            if (c.savingGoals.isEmpty)
              SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppColors.brandTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.savings_rounded,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No savings goals created yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Set a target for a laptop, trip, or emergency fund.',
                            style: TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () => SavingsGoalsScreen.showAddSheet(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Goal'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: c.savingGoals.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpace.gap),
                  itemBuilder: (context, i) =>
                      _GoalChip(goal: c.savingGoals[i], sym: sym),
                ),
              ),

            const SizedBox(height: AppSpace.section),

            SectionHeader(
              title: 'Expenses by Category',
              actionLabel: c.categorySpendThisMonth().isEmpty
                  ? null
                  : 'All History',
              actionTab: DashboardScreen.tabTransactions,
            ),
            if (c.categorySpendThisMonth().isEmpty)
              SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppColors.brandTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.donut_large_rounded,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No spending recorded this month yet.',
                        style: TextStyle(fontSize: 13.5, color: muted),
                      ),
                    ),
                  ],
                ),
              )
            else
              _CategoryWrap(
                data: c.categorySpendThisMonth(),
                total: expenses,
                sym: sym,
              ),

            const SizedBox(height: AppSpace.section),

            // A new account has no budget. Showing "0 / 0 spent" and a "0%
            // used" ring would read as though they had blown their limit, so
            // the card asks for one instead.
            if (budget <= 0)
              TourKeys.wrap(
                TourAnchors.budget,
                SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.brandTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.donut_large_rounded,
                          color: AppColors.brand,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No budget set yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Set a monthly limit and we will warn you before '
                              'you cross it.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () =>
                            DashboardShellScope.of(context)
                                .goToTab(DashboardScreen.tabBudget),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Set'),
                      ),
                    ],
                  ),
                ),
              )
            else
              TourKeys.wrap(
                TourAnchors.budget,
                SurfaceCard(
                  child: Column(
                    children: [
                      ProgressRing(
                        value: percent,
                        centerValue:
                            '$sym${expenses.toStringAsFixed(0)} / $sym${budget.toStringAsFixed(0)}',
                        caption: 'spent this month',
                        color: percent > 0.9
                            ? AppColors.expense
                            : AppColors.brand,
                        badge:
                            '${(percent * 100).clamp(0, 999).toStringAsFixed(0)}% used',
                        size: 168,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: LabeledStat(
                              label: 'Total Limit',
                              value: '$sym${budget.toStringAsFixed(0)}',
                              color: AppColors.textPrimary,
                              align: CrossAxisAlignment.center,
                            ),
                          ),
                          _divider(muted),
                          Expanded(
                            child: LabeledStat(
                              label: 'Spent',
                              value: '$sym${expenses.toStringAsFixed(0)}',
                              color: AppColors.expense,
                              align: CrossAxisAlignment.center,
                            ),
                          ),
                          _divider(muted),
                          Expanded(
                            child: LabeledStat(
                              label: 'Remaining',
                              value:
                                  '$sym${(budget - expenses).clamp(0, budget).toStringAsFixed(0)}',
                              color: AppColors.income,
                              align: CrossAxisAlignment.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (c.transactions.isNotEmpty) ...[
              const SizedBox(height: AppSpace.section),
              TourKeys.wrap(
                TourAnchors.recent,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: 'Recent Transactions',
                      actionLabel: 'View All',
                      actionTab: DashboardScreen.tabTransactions,
                    ),
                    ...c.transactions
                        .take(5)
                        .map(
                          (tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddTransactionScreen(existing: tx),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.tint(
                                        tx.isExpense
                                            ? AppColors.expense
                                            : AppColors.income,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      tx.isExpense
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      size: 18,
                                      color: tx.isExpense
                                          ? AppColors.expense
                                          : AppColors.income,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          tx.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          tx.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${tx.isExpense ? "-" : "+"}$sym${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: tx.isExpense
                                          ? AppColors.expense
                                          : AppColors.income,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpace.gap),
            // No inline Add Transaction button here: the shell shows a
            // floating action button on this tab, so a second copy at the
            // bottom of the list was just noise.
          ],
        );
      },
    );
  }

  Widget _divider(Color muted) =>
      Container(width: 1, height: 30, color: muted.withValues(alpha: 0.18));
}

class _GoalChip extends StatelessWidget {
  final SavingGoal goal;
  final String sym;

  const _GoalChip({required this.goal, required this.sym});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      width: 172,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(goal.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$sym${goal.savedAmount.toStringAsFixed(0)} of $sym${goal.targetAmount.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            BudgetBar(
              value: progress,
              leftLabel: '${(progress * 100).toStringAsFixed(0)}%',
              rightLabel: goal.badge,
              color: AppColors.brand,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryWrap extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final String sym;

  const _CategoryWrap({
    required this.data,
    required this.total,
    required this.sym,
  });

  static const Map<String, IconData> _icons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_bus_rounded,
    'Subscriptions': Icons.play_circle_fill_rounded,
    'Education': Icons.menu_book_rounded,
    'Study Materials': Icons.collections_bookmark_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Healthcare': Icons.local_hospital_rounded,
    'Entertainment': Icons.movie_rounded,
    'Other': Icons.category_rounded,
  };

  static const Map<String, Color> _colors = {
    'Food': Color(0xFFF59E0B),
    'Transport': Color(0xFF0EA5E9),
    'Subscriptions': Color(0xFF22C55E),
    'Education': Color(0xFF3B82F6),
    'Study Materials': Color(0xFF8B5CF6),
    'Shopping': Color(0xFFEC4899),
    'Healthcare': Color(0xFFEF4444),
    'Entertainment': Color(0xFFEAB308),
    'Other': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: AppSpace.gap,
      runSpacing: AppSpace.gap,
      children: [
        for (final e in entries.take(6))
          _CategoryCard(
            name: e.key,
            amount: e.value,
            share: total > 0 ? e.value / total : 0,
            sym: sym,
            icon: _icons[e.key] ?? Icons.category_rounded,
            color: _colors[e.key] ?? const Color(0xFF6B7280),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final double amount;
  final double share;
  final String sym;
  final IconData icon;
  final Color color;

  const _CategoryCard({
    required this.name,
    required this.amount,
    required this.share,
    required this.sym,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - AppSpace.gutter * 2 - 24) / 3,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.22)
                    : AppColors.tint(color),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white60 : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$sym${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            BudgetBar(
              value: share,
              leftLabel: '',
              rightLabel: '',
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
