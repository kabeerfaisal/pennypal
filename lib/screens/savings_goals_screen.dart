import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';
import 'goal_detail_screen.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  /// Opens the create-goal sheet. Static so any screen can reach it.
  static void showAddSheet(BuildContext context) => _showAddSheet(context);

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;
        final active = c.activeGoals;
        final archived = c.archivedGoals;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: TabBar(
                controller: _tabs,
                labelColor: AppColors.brand,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.brand,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: isDark ? Colors.white12 : AppColors.border,
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'Active Goals (${active.length})'),
                  Tab(text: 'Archived (${archived.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _goalList(active, archived: false),
                  _goalList(archived, archived: true),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _goalList(List<SavingGoal> goals, {required bool archived}) {
    if (goals.isEmpty) {
      return archived
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No archived goals yet',
              subtitle:
                  'Goals you finish or archive are kept here for reference.',
            )
          : EmptyState(
              icon: Icons.savings_rounded,
              title: 'No savings goals created yet',
              subtitle: 'Set a target for a laptop, trip, or emergency fund and track it here.',
              actionLabel: 'New Savings Goal',
              onAction: () => SavingsGoalsScreen.showAddSheet(context),
            );
    }

    return ListView(
      // Extra bottom room so the shell's New Goal button never covers the last
      // goal, and so a second goal is always one tap away.
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.gutter,
        AppSpace.gutter,
        96,
      ),
      children: [
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.gap),
            child: _GoalCard(goal: g, archived: archived),
          ),
      ],
    );
  }
}

void _showAddSheet(BuildContext context) {
  final titleCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final savedCtrl = TextEditingController();
  final contribCtrl = TextEditingController();
  DateTime? targetDate;
  String emoji = '🎯';
  const emojis = ['🎯', '💻', '✈️', '📚', '🏠', '🚗', '💰', '🎓', '📱', '👟'];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Savings Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis
                        .map(
                          (e) => GestureDetector(
                            onTap: () => setS(() => emoji = e),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: emoji == e
                                    ? AppColors.brandTint
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: emoji == e
                                      ? AppColors.brand
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Goal title (e.g. New Laptop)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target amount',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: savedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Already saved (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contribCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monthly contribution',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Target date'),
                    subtitle: Text(
                      targetDate == null
                          ? 'Optional'
                          : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(
                          const Duration(days: 90),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) setS(() => targetDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty ||
                            targetCtrl.text.trim().isEmpty) {
                          return;
                        }
                        await FinanceController.instance.addSavingGoal(
                          SavingGoal(
                            id: '',
                            title: titleCtrl.text.trim(),
                            targetAmount:
                                double.tryParse(targetCtrl.text.trim()) ?? 0,
                            savedAmount:
                                double.tryParse(savedCtrl.text.trim()) ?? 0,
                            monthlyContribution:
                                double.tryParse(contribCtrl.text.trim()) ?? 0,
                            targetDate: targetDate,
                            emoji: emoji,
                          ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Add Goal'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _GoalCard extends StatelessWidget {
  final SavingGoal goal;
  final bool archived;
  const _GoalCard({required this.goal, this.archived = false});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final sym = FinanceController.instance.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sym${goal.savedAmount.toStringAsFixed(0)} / $sym${goal.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (archived)
                IconButton(
                  tooltip: 'Restore',
                  icon: const Icon(Icons.unarchive_outlined),
                  onPressed: () =>
                      FinanceController.instance.setGoalArchived(goal, false),
                )
              else
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () =>
                      FinanceController.instance.setGoalArchived(goal, true),
                ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expense,
                ),
                onPressed: () =>
                    FinanceController.instance.deleteSavingGoal(goal.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!archived)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addFunds(context, goal),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add money'),
              ),
            ),
          BudgetBar(
            value: progress,
            leftLabel: '${(progress * 100).toStringAsFixed(0)}% saved',
            rightLabel: progress >= 1.0 ? 'Goal Reached!' : goal.badge,
            color: progress >= 1.0 ? AppColors.income : AppColors.brand,
          ),
        ],
      ),
    );
  }

  Future<void> _addFunds(BuildContext context, SavingGoal goal) async {
    final ctrl = TextEditingController();
    final added = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('Add to ${goal.title}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: FinanceController.instance.currencySymbol,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added != null && added > 0) {
      await FinanceController.instance.addToGoal(goal, added);
    }
  }
}
