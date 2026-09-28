import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/receipt_widgets.dart';
import '../widgets/ui_kit.dart';
import 'add_transaction_screen.dart';
import 'receipt_viewer.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  String _type = 'All';
  String _period = 'All';
  String _category = 'All';
  String _search = '';

  /// Custom range from the date picker. Takes precedence over [_period].
  DateTimeRange? _range;

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'Food':
        return Icons.fastfood;
      case 'Transport':
        return Icons.directions_bus;
      case 'Subscriptions':
        return Icons.subscriptions;
      case 'Education':
        return Icons.menu_book;
      case 'Study Materials':
        return Icons.menu_book_outlined;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Entertainment':
        return Icons.movie;
      case 'Salary':
        return Icons.work;
      case 'Freelance':
        return Icons.computer;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Investment':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  Color _colorForCategory(String cat) {
    switch (cat) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.teal;
      case 'Subscriptions':
        return Colors.purple;
      case 'Education':
        return Colors.blue;
      case 'Study Materials':
        return Colors.indigo;
      case 'Shopping':
        return Colors.pink;
      case 'Healthcare':
        return Colors.red;
      case 'Entertainment':
        return Colors.amber;
      case 'Salary':
        return Colors.green;
      case 'Freelance':
        return Colors.indigo;
      case 'Gift':
        return Colors.pinkAccent;
      case 'Investment':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  bool _inPeriod(DateTime date) {
    // A custom range always wins over the quick presets.
    final range = _range;
    if (range != null) {
      final day = DateTime(date.year, date.month, date.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }
    final now = DateTime.now();
    if (_period == 'This week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final from = DateTime(start.year, start.month, start.day);
      return !date.isBefore(from);
    }
    if (_period == 'This month') {
      return date.year == now.year && date.month == now.month;
    }
    return true;
  }

  String get _periodLabel {
    final range = _range;
    if (range == null) return _period == 'All' ? 'Any date' : _period;
    return '${range.start.day}/${range.start.month} - '
        '${range.end.day}/${range.end.month}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day + 1),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final all = FinanceController.instance.transactions;
        final categories = <String>{
          'All',
          ...all.map((t) => t.category),
        }.toList();

        final txs = all.where((tx) {
          if (_type == 'Expense' && !tx.isExpense) return false;
          if (_type == 'Income' && tx.isExpense) return false;
          if (_category != 'All' && tx.category != _category) return false;
          if (!_inPeriod(tx.date)) return false;
          if (_search.trim().isNotEmpty) {
            final q = _search.toLowerCase();
            final hay = '${tx.title} ${tx.category}'.toLowerCase();
            if (!hay.contains(q)) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search title or category',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                10,
                AppSpace.gutter,
                4,
              ),
              child: Row(
                children: [
                  ...['All', 'Expense', 'Income'].map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: t == 'All'
                            ? 'All'
                            : t == 'Expense'
                            ? 'Expenses Only'
                            : 'Income Only',
                        selected: _type == t,
                        onTap: () => setState(() => _type = t),
                      ),
                    ),
                  ),
                  ...['All', 'This month', 'This week'].map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: p == 'All' ? 'Any date' : p,
                        // A custom range wins, so presets read as unselected.
                        selected: _range == null && _period == p,
                        onTap: () => setState(() {
                          _period = p;
                          _range = null;
                        }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterPill(
                      label: _range == null ? 'Custom range' : _periodLabel,
                      selected: _range != null,
                      onTap: _pickRange,
                    ),
                  ),
                  if (_range != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: 'Clear',
                        selected: false,
                        onTap: () => setState(() {
                          _range = null;
                          _period = 'All';
                        }),
                      ),
                    ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                0,
                AppSpace.gutter,
                8,
              ),
              child: Row(
                children: categories
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterPill(
                          label: cat == 'All' ? 'All' : cat,
                          selected: _category == cat,
                          onTap: () => setState(() => _category = cat),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No transactions yet',
                      subtitle: 'Record your first income or expense to start tracking.',
                      actionLabel: 'Add Transaction',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                      ),
                    )
                  : txs.isEmpty
                  ? const EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No transactions match your filter',
                      subtitle: 'Try clearing the filters above.',
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.gutter,
                            0,
                            AppSpace.gutter,
                            8,
                          ),
                          child: ResultStrip(
                            count: txs.length,
                            totalLabel: 'Total',
                            totalValue:
                                '${FinanceController.instance.currencySymbol}${_netOf(txs).toStringAsFixed(2)}',
                          ),
                        ),
                        Expanded(child: _groupedList(txs)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Net of the visible rows: expenses subtract, income adds.
  double _netOf(List<TransactionModel> txs) {
    var net = 0.0;
    for (final tx in txs) {
      net += tx.isExpense ? -tx.amount : tx.amount;
    }
    return net;
  }

  Widget _groupedList(List<TransactionModel> txs) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in txs) {
      final key = '${tx.date.day}/${tx.date.month}/${tx.date.year}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return ListView(
      // Extra bottom room so the shell's Add Transaction button never sits on
      // top of the last row.
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 96),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
            ...entry.value.map(
              (tx) => _TxCard(
                tx: tx,
                icon: _iconForCategory(tx.category),
                color: _colorForCategory(tx.category),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final IconData icon;
  final Color color;

  const _TxCard({required this.tx, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final sym = FinanceController.instance.currencySymbol;
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            scrollable: true,
            title: const Text('Delete Transaction'),
            content: Text('Delete "${tx.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => FinanceController.instance.deleteTransaction(tx.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(existing: tx),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _ReceiptThumb(tx: tx, color: color, fallbackIcon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tx.paymentMode.trim().isEmpty
                                  ? tx.category
                                  : '${tx.category} · ${tx.paymentMode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: color, fontSize: 12),
                            ),
                          ),
                          if (tx.hasReceipt) ...[
                            Text(
                              '  •  ',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.receipt_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tx.isExpense ? "-" : "+"}$sym${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tx.isExpense ? Colors.red[600] : Colors.green[600],
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

/// Shows a receipt thumbnail, or the category icon when there is no receipt.
class _ReceiptThumb extends StatelessWidget {
  final TransactionModel tx;
  final Color color;
  final IconData fallbackIcon;

  const _ReceiptThumb({
    required this.tx,
    required this.color,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiptThumb(
      data: tx.receiptData,
      color: color,
      fallbackIcon: fallbackIcon,
      onTap: tx.hasReceipt
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReceiptViewer(data: tx.receiptData, title: tx.title),
              ),
            )
          : null,
    );
  }
}
