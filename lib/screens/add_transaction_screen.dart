import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/finance_controller.dart';
import '../services/receipt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/receipt_widgets.dart';
import '../widgets/success_overlay.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  /// Base64 JPEG being attached, or empty when removed in this edit session.
  String _receiptData = '';
  bool _preparing = false;
  bool _saving = false;

  /// Payment mode / income source, from the SRS Transactions entity.
  String _paymentMode = '';

  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': 'Transport', 'icon': Icons.directions_bus, 'color': Colors.teal},
    {
      'name': 'Subscriptions',
      'icon': Icons.subscriptions,
      'color': Colors.purple,
    },
    {'name': 'Education', 'icon': Icons.menu_book, 'color': Colors.blue},
    {
      'name': 'Study Materials',
      'icon': Icons.menu_book_outlined,
      'color': Colors.indigo,
    },
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Healthcare', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.amber},
    {'name': 'Other', 'icon': Icons.category, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Salary', 'icon': Icons.work, 'color': Colors.green},
    {'name': 'Freelance', 'icon': Icons.computer, 'color': Colors.indigo},
    {'name': 'Gift', 'icon': Icons.card_giftcard, 'color': Colors.pink},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': Colors.teal},
    {'name': 'Other', 'icon': Icons.category, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _amountCtrl.text = widget.existing!.amount.toString();
      _selectedCategory = widget.existing!.category;
      _selectedDate = widget.existing!.date;
      _receiptData = widget.existing!.receiptData;
      _paymentMode = widget.existing!.paymentMode;
      _tabCtrl.index = widget.existing!.isExpense ? 0 : 1;
    }
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final cats = _tabCtrl.index == 0
            ? _expenseCategories
            : _incomeCategories;
        final names = cats.map((c) => c['name'] as String).toSet();
        setState(() {
          if (!names.contains(_selectedCategory)) {
            _selectedCategory = cats.first['name'] as String;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final source = await _askSource();
    if (source == null || !mounted) return;

    setState(() => _preparing = true);
    try {
      final result = await ReceiptService.instance.pick(source);
      if (!mounted) return;
      setState(() {
        _preparing = false;
        if (result.isEmpty) return; // user cancelled the picker
        _receiptData = result.data;
      });
    } on ReceiptException catch (e) {
      if (!mounted) return;
      setState(() => _preparing = false);
      _toast(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _preparing = false);
      _toast('Could not attach the receipt: $e');
    }
  }

  void _removeReceipt() {
    setState(() => _receiptData = '');
  }

  Future<ImageSource?> _askSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_preparing || _saving) return;
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      _toast('Please fill title and amount');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _toast('Enter a valid amount');
      return;
    }

    final isExpense = _tabCtrl.index == 0;
    setState(() => _saving = true);

    final tx = TransactionModel(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      isExpense: isExpense,
      // Receipts only make sense on an expense, so a stale one is dropped
      // when the student switches to the Income tab.
      receiptData: isExpense ? _receiptData : '',
      paymentMode: _paymentMode,
    );

    final err = widget.existing != null
        ? await FinanceController.instance.updateTransaction(tx)
        : await FinanceController.instance.addTransaction(tx);

    if (!mounted) return;
    if (err != null) {
      setState(() => _saving = false);
      _toast(err);
      return;
    }

    if (!mounted) return;
    final wasEdit = widget.existing != null;
    final sym = FinanceController.instance.currencySymbol;
    // Pop first so the confirmation is not competing with this screen's own
    // Scaffold, then confirm over whatever the student was doing before.
    Navigator.pop(context);
    await SuccessOverlay.show(
      context,
      title: wasEdit ? 'Transaction updated' : 'Transaction added',
      subtitle: wasEdit
          ? '${tx.title} was changed.'
          : '${tx.title} was recorded as '
                '${tx.isExpense ? 'an expense' : 'income'}.',
      // The amount carries the expense/income colour; the tick stays green
      // because it means the save worked, not which way the money moved.
      detail:
          '${tx.isExpense ? "-" : "+"}$sym${amount.toStringAsFixed(2)}'
          '  ·  ${tx.category}',
      actionLabel: 'Done',
      icon: Icons.check_rounded,
      color: AppColors.income,
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = _tabCtrl.index == 0
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing != null ? 'Edit Transaction' : 'Add Transaction',
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          // The app bar is light, so the tabs must not be white on white.
          labelColor: AppColors.brand,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white60
              : AppColors.textMuted,
          indicatorColor: AppColors.brand,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward, size: 20), text: 'Expense'),
            Tab(icon: Icon(Icons.arrow_upward, size: 20), text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildForm(context, categories, cs, isExpense: true),
          _buildForm(context, categories, cs, isExpense: false),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Map<String, dynamic>> categories,
    ColorScheme cs, {
    required bool isExpense,
  }) {
    final accent = isExpense ? Colors.redAccent : Colors.green;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  isExpense ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                  color: accent,
                  size: 36,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixText: '${FinanceController.instance.currencySymbol} ',
                    prefixStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 36,
                      color: accent.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: isExpense
                  ? 'e.g. Lunch, Bus ticket...'
                  : 'e.g. Monthly salary...',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final selected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? (cat['color'] as Color).withValues(alpha: 0.2)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cat['color'] : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat['icon'], color: cat['color'], size: 26),
                      const SizedBox(height: 4),
                      Text(
                        cat['name'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          // Payment mode / income source, from the SRS Transactions entity.
          const SizedBox(height: 20),
          TextFormField(
            initialValue: _paymentMode,
            onChanged: (v) => _paymentMode = v,
            decoration: InputDecoration(
              labelText: isExpense ? 'Payment mode' : 'Source',
              hintText: isExpense
                  ? 'Cash, Card, Bank transfer...'
                  : 'Allowance, Scholarship, Part-time job...',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          // Receipts only make sense on an expense, and not on desktop where
          // there is no camera or gallery.
          if (isExpense && ReceiptService.isSupported) ...[
            const SizedBox(height: 20),
            _receiptSection(accent),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _saving || _preparing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _saving
                    ? 'Saving...'
                    : widget.existing != null
                    ? 'Update Transaction'
                    : isExpense
                    ? 'Save Expense'
                    : 'Save Income',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: (_saving || _preparing) ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptSection(Color accent) {
    return ReceiptPickerField(
      receiptData: _receiptData,
      preparing: _preparing,
      accent: accent,
      onPick: _pickReceipt,
      onRemove: _removeReceipt,
    );
  }
}
