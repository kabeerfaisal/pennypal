import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/finance_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';

class GoalDetailScreen extends StatelessWidget {
  final SavingGoal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final matches = FinanceController.instance.savingGoals.where(
          (g) => g.id == goal.id,
        );
        final live = matches.isEmpty ? goal : matches.first;
        final cs = Theme.of(context).colorScheme;
        final c = FinanceController.instance;
        final p = live.progress;
        final eta = live.estimatedFinish;
        return Scaffold(
          appBar: AppBar(title: Text(live.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 42,
                                startDegreeOffset: -90,
                                sections: [
                                  PieChartSectionData(
                                    color: p >= 1 ? Colors.green : cs.primary,
                                    value: live.savedAmount.clamp(
                                      0.01,
                                      double.infinity,
                                    ),
                                    title: '',
                                    radius: 16,
                                  ),
                                  PieChartSectionData(
                                    color: cs.primary.withValues(alpha: 0.12),
                                    value: live.remaining <= 0
                                        ? 0.01
                                        : live.remaining,
                                    title: '',
                                    radius: 16,
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(p * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            Text(
                              '${c.currencySymbol}${live.savedAmount.toStringAsFixed(0)} / ${c.currencySymbol}${live.targetAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(live.badge),
                              backgroundColor: cs.primary.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: p,
                minHeight: 12,
                borderRadius: BorderRadius.circular(8),
                color: p >= 1 ? Colors.green : cs.primary,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
              Text(live.motivation, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 16),
              _info(
                'Target date',
                live.targetDate == null
                    ? 'Not set'
                    : DateFormat.yMMMd().format(live.targetDate!),
              ),
              _info(
                'Monthly contribution',
                '${c.currencySymbol}${live.monthlyContribution.toStringAsFixed(0)}',
              ),
              _info(
                'Estimated completion',
                eta == null
                    ? 'Set a monthly contribution to estimate'
                    : DateFormat.yMMM().format(eta),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _editContribution(context, live),
                    child: const Text('Update contribution'),
                  ),
                  OutlinedButton(
                    onPressed: () => _addMilestone(context, live),
                    child: const Text('Add milestone'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Milestones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (live.milestones.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClearMilestones(context, live),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 17),
                      label: const Text('Clear all'),
                    ),
                ],
              ),
              if (live.milestones.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('None yet. Mark steps like â€œfirst 25%â€.'),
                ),
              ...live.milestones.asMap().entries.map((e) {
                final i = e.key;
                final m = e.value;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: m.done
                        ? AppColors.income.withValues(alpha: 0.08)
                        : (isDark ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: m.done,
                        onChanged: (v) => _toggleMilestone(live, i, v ?? false),
                      ),
                      // Expanded so a long title ellipsises instead of pushing
                      // the two buttons off a narrow screen.
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _renameMilestone(context, live, i),
                          child: Text(
                            m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: m.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: m.done && isDark ? Colors.white54 : null,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rename',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _renameMilestone(context, live, i),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.expense,
                        ),
                        onPressed: () => _deleteMilestone(context, live, i),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _editContribution(BuildContext context, SavingGoal goal) async {
    final ctrl = TextEditingController(
      text: goal.monthlyContribution > 0
          ? goal.monthlyContribution.toStringAsFixed(0)
          : '',
    );
    final val = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Monthly contribution'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (val != null && val >= 0) {
      await FinanceController.instance.updateSavingGoal(
        goal.copyWith(monthlyContribution: val),
      );
    }
  }

  Future<void> _addMilestone(BuildContext context, SavingGoal goal) async {
    final ctrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Milestone'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. First 500 saved',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    await FinanceController.instance.updateSavingGoal(
      goal.copyWith(
        milestones: [
          ...goal.milestones,
          GoalMilestone(title: title),
        ],
      ),
    );
  }

  Future<void> _toggleMilestone(SavingGoal goal, int index, bool done) async {
    final next = [...goal.milestones];
    next[index] = GoalMilestone(title: next[index].title, done: done);
    await FinanceController.instance.updateSavingGoal(
      goal.copyWith(milestones: next),
    );
  }

  /// Renames a milestone in place, keeping its ticked state.
  Future<void> _renameMilestone(
    BuildContext context,
    SavingGoal goal,
    int index,
  ) async {
    final current = goal.milestones[index];
    final ctrl = TextEditingController(text: current.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        scrollable: true,
        title: const Text('Edit milestone'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. First 500 saved',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (title == null || title.isEmpty || title == current.title) return;

    final next = [...goal.milestones];
    next[index] = GoalMilestone(title: title, done: current.done);
    await FinanceController.instance.updateSavingGoal(
      goal.copyWith(milestones: next),
    );
  }

  Future<void> _deleteMilestone(
    BuildContext context,
    SavingGoal goal,
    int index,
  ) async {
    final target = goal.milestones[index];
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete milestone?',
      message: '"${target.title}" will be removed from this goal.',
      confirmLabel: 'Delete',
      color: AppColors.expense,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok) return;

    final next = [...goal.milestones]..removeAt(index);
    await FinanceController.instance.updateSavingGoal(
      goal.copyWith(milestones: next),
    );
  }

  Future<void> _confirmClearMilestones(
    BuildContext context,
    SavingGoal goal,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Clear all milestones?',
      message:
          'All ${goal.milestones.length} milestones will be removed from '
          '"${goal.title}". This cannot be undone.',
      confirmLabel: 'Clear all',
      color: AppColors.expense,
      icon: Icons.delete_sweep_rounded,
    );
    if (!ok) return;
    await FinanceController.instance.updateSavingGoal(
      goal.copyWith(milestones: const []),
    );
  }
}
