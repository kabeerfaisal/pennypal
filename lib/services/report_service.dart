import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

// `package:web` and `dart:io` cannot compile for each other's platform, so the
// delivery step is swapped per target. Both files expose `deliverReport`.
import 'report_export_io.dart'
    if (dart.library.js_interop) 'report_export_web.dart';

import '../controllers/finance_controller.dart';

class ReportException implements Exception {
  final String message;
  const ReportException(this.message);

  @override
  String toString() => message;
}

/// Builds and delivers the Excel spending report.
///
/// The web build cannot use `dart:io`, the temporary directory or the platform
/// share sheet, so it falls back to a normal browser download. Both paths
/// produce the identical workbook.
class ReportService {
  ReportService._();

  /// Returns a short confirmation for the caller to surface in a SnackBar.
  static Future<String> shareSpendingWorkbook() async {
    final c = FinanceController.instance;
    final bytes = _buildWorkbook(c);
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final name = 'pennypal_report_$stamp.xlsx';
    return deliverReport(bytes, name);
  }

  static Uint8List _buildWorkbook(FinanceController c) {
    final book = Excel.createExcel();
    book.delete('Sheet1');

    final spending = book['Spending'];
    spending.appendRow([
      TextCellValue('Title'),
      TextCellValue('Category'),
      TextCellValue('Type'),
      TextCellValue('Amount'),
      TextCellValue('Date'),
    ]);
    for (final tx in c.transactions) {
      spending.appendRow([
        TextCellValue(tx.title),
        TextCellValue(tx.category),
        TextCellValue(tx.isExpense ? 'Expense' : 'Income'),
        DoubleCellValue(tx.amount),
        TextCellValue(DateFormat('yyyy-MM-dd').format(tx.date)),
      ]);
    }
    _autofit(spending, [28, 16, 12, 14, 14]);

    final goals = book['Goals'];
    goals.appendRow([
      TextCellValue('Goal'),
      TextCellValue('Saved'),
      TextCellValue('Target'),
      TextCellValue('Progress'),
    ]);
    for (final g in c.savingGoals) {
      goals.appendRow([
        TextCellValue(g.title),
        DoubleCellValue(g.savedAmount),
        DoubleCellValue(g.targetAmount),
        TextCellValue('${(g.progress * 100).toStringAsFixed(0)}%'),
      ]);
    }
    _autofit(goals, [24, 14, 14, 12]);

    final summary = book['Summary'];
    summary.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summary.appendRow([TextCellValue('Currency'), TextCellValue(c.currency)]);
    summary.appendRow([
      TextCellValue('Monthly budget'),
      DoubleCellValue(c.monthlyBudget),
    ]);
    summary.appendRow([
      TextCellValue('Spent this month'),
      DoubleCellValue(c.totalExpenses),
    ]);
    summary.appendRow([
      TextCellValue('Income this month'),
      DoubleCellValue(c.totalIncome),
    ]);
    summary.appendRow([
      TextCellValue('Remaining'),
      DoubleCellValue(
        (c.monthlyBudget - c.totalExpenses).clamp(0, c.monthlyBudget),
      ),
    ]);
    summary.appendRow([TextCellValue('')]);
    summary.appendRow([
      TextCellValue('Category spend'),
      TextCellValue('Amount'),
    ]);
    c.categorySpendThisMonth().forEach((cat, amt) {
      summary.appendRow([TextCellValue(cat), DoubleCellValue(amt)]);
    });
    _autofit(summary, [24, 18]);

    final bytes = book.encode();
    if (bytes == null) {
      throw const ReportException('The spreadsheet could not be built.');
    }
    return Uint8List.fromList(bytes);
  }

  /// Widens columns to fit their header, so the file is readable when opened.
  static void _autofit(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }
}
