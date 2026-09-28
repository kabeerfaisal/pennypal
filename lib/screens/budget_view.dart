import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/ui_kit.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  static const _categories = [
    'Food',
    'Transport',
    'Subscriptions',
    'Education',
    'Study Materials',
    'Shopping',
    'Healthcare',
    'Entertainment',
    'Other',
  ];

  static const _catColors = [
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFEAB308),
    Color(0xFF6B7280),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;
        final sym = c.currencySymbol;
        final expenses = c.totalExpenses;
        final budget = c.monthlyBudget;
        final rawPercent = budget > 0 ? expenses / budget : 0.0;
        final catBreakdown = c.categorySpendThisMonth();
        final now = DateTime.now();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final muted = isDark ? Colors.white60 : AppColors.textMuted;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.gutter,
            AppSpace.gutter,
            28,
          ),
          children: [
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(title: 'Current Month Overview'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${now.year} Active',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ],
            ),
            SurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ProgressRing(
                    value: rawPercent,
                    size: 178,
                    centerValue:
                        '$sym${expenses.toStringAsFixed(0)} / $sym${budget.toStringAsFixed(0)}',
                    caption: budget > 0
                        ? 'of monthly limit'
                        : 'no limit set yet',
                    color: rawPercent > 0.9
                        ? AppColors.expense
                        : AppColors.brand,
                    badge: budget > 0
                        ? '${(rawPercent * 100).toStringAsFixed(0)}% used'
                        : null,
                  ),
                  const SizedBox(height: 20),
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
                      _Rule(),
                      Expanded(
                        child: LabeledStat(
                          label: 'Spent',
                          value: '$sym${expenses.toStringAsFixed(0)}',
                          color: AppColors.expense,
                          align: CrossAxisAlignment.center,
                        ),
                      ),
                      _Rule(),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _editBudget(context, c),
                          icon: const Icon(Icons.tune_rounded, size: 19),
                          label: Text(
                            budget > 0 ? 'Edit Budget' : 'Set Budget',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _confirmClear(context, c),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  if (rawPercent > 0.9) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.tint(AppColors.expense),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.expense,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "You're near your budget limit!",
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.section),
            SectionHeader(
              title: 'Category Spending Limits',
              actionLabel: 'Edit Limits',
              onAction: () => _editFirstLimit(context, c),
            ),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: _categories.map((cat) {
                  final spent = catBreakdown[cat] ?? 0;
                  final limit = c.categoryLimits[cat] ?? 0;
                  final ratio = limit > 0 ? spent / limit : 0.0;
                  final over = ratio >= 1;
                  final color = limit <= 0
                      ? muted
                      : over
                      ? AppColors.expense
                      : AppColors.brand;
                  return ListTile(
                    onTap: () => _editLimit(context, c, cat, limit),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      cat,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    subtitle: limit <= 0
                        ? Text(
                            'No cap set · spent $sym${spent.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, color: muted),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: BudgetBar(
                              value: ratio,
                              leftLabel:
                                  '$sym${spent.toStringAsFixed(0)} / $sym${limit.toStringAsFixed(0)}',
                              rightLabel:
                                  '${(ratio * 100).toStringAsFixed(0)}% utilized',
                              color: color,
                            ),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (limit > 0)
                          Text(
                            '$sym${(limit - spent).clamp(0, limit).toStringAsFixed(0)} left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (catBreakdown.isNotEmpty) ...[
              const SizedBox(height: AppSpace.section),
              SectionHeader(
                title: 'Spending by Category',
                actionLabel: 'Excel',
                onAction: () => _export(context),
              ),
              SurfaceCard(
                child: Column(
                  children: catBreakdown.entries.toList().asMap().entries.map((
                    e,
                  ) {
                    final cat = e.value.key;
                    final amt = e.value.value;
                    final pct = expenses > 0 ? amt / expenses : 0.0;
                    final color = _catColors[e.key % _catColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Text(
                                '$sym${amt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 38,
                                child: Text(
                                  '${(pct * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: muted, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          BudgetBar(
                            value: pct,
                            leftLabel: '',
                            rightLabel: '',
                            color: color,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpace.section),
              const EmptyState(
                icon: Icons.donut_large_rounded,
                title: 'No spending recorded yet',
                subtitle: 'Add an expense to see how this month is shaping up.',
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await ReportService.shareSpendingWorkbook();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }

  void _editBudget(BuildContext context, FinanceController c) {
    final ctrl = TextEditingController(
      text: c.monthlyBudget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Set monthly budget'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(prefixText: '${c.currencySymbol} '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                c.setBudget(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, FinanceController c) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Clear monthly budget?',
      message:
          'The monthly limit goes back to the default and the ring resets. '
          'Your transactions are not affected.',
      confirmLabel: 'Clear',
      color: AppColors.expense,
      icon: Icons.restart_alt_rounded,
    );
    if (ok) await c.clearBudget();
  }

  void _editLimit(
    BuildContext context,
    FinanceController c,
    String cat,
    double limit,
  ) {
    final ctrl = TextEditingController(
      text: limit > 0 ? limit.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('Limit for $cat'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '${c.currencySymbol} ',
            helperText: 'Set 0 to remove the cap',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0;
              c.setCategoryLimit(cat, val < 0 ? 0 : val);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editFirstLimit(BuildContext context, FinanceController c) {
    final unset = _categories.firstWhere(
      (cat) => (c.categoryLimits[cat] ?? 0) <= 0,
      orElse: () => _categories.first,
    );
    _editLimit(context, c, unset, c.categoryLimits[unset] ?? 0);
  }
}

class _Rule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white12 : AppColors.border,
    );
  }
}
