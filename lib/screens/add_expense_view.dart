import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';

class AddExpenseView extends StatefulWidget {
  final VoidCallback onSaved;
  const AddExpenseView({super.key, required this.onSaved});

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Transaction',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isExpense
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300],
                          foregroundColor: _isExpense
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () => setState(() => _isExpense = true),
                        child: const Text('Expense'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isExpense
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[300],
                          foregroundColor: !_isExpense
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () => setState(() => _isExpense = false),
                        child: const Text('Income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (e.g. Coffee)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_titleController.text.isEmpty ||
                          _amountController.text.isEmpty) {
                        return;
                      }
                      final amount =
                          double.tryParse(_amountController.text) ?? 0.0;
                      if (amount <= 0) return;

                      FinanceController.instance.addTransaction(
                        TransactionModel(
                          id: DateTime.now().toString(),
                          title: _titleController.text,
                          amount: amount,
                          category: 'Other',
                          date: DateTime.now(),
                          isExpense: _isExpense,
                        ),
                      );

                      widget.onSaved(); // Navigate back to home
                      _titleController.clear();
                      _amountController.clear();
                    },
                    child: const Text(
                      'Save Transaction',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
