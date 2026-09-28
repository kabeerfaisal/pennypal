import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Aggregate numbers for the admin analytics tab.
class AdminAnalytics {
  final int totalUsers;
  final int students;
  final int admins;
  final int newLast7;
  final int newLast30;
  final int totalTransactions;
  final int expenseCount;
  final int incomeCount;
  final int transactionsLast7;
  final double totalExpenses;
  final double totalIncome;
  final double totalBudgets;
  final int receiptCount;
  final int goalsCount;
  final Map<String, double> topCategories;

  /// Transactions per day for the last [dailyDays] days, oldest first.
  final List<DailyPoint> daily;

  const AdminAnalytics({
    required this.totalUsers,
    required this.students,
    required this.admins,
    required this.newLast7,
    required this.newLast30,
    required this.totalTransactions,
    required this.expenseCount,
    required this.incomeCount,
    required this.transactionsLast7,
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalBudgets,
    required this.receiptCount,
    required this.goalsCount,
    required this.topCategories,
    required this.daily,
  });

  static const empty = AdminAnalytics(
    totalUsers: 0,
    students: 0,
    admins: 0,
    newLast7: 0,
    newLast30: 0,
    totalTransactions: 0,
    expenseCount: 0,
    incomeCount: 0,
    transactionsLast7: 0,
    totalExpenses: 0,
    totalIncome: 0,
    totalBudgets: 0,
    receiptCount: 0,
    goalsCount: 0,
    topCategories: {},
    daily: [],
  );

  double get net => totalIncome - totalExpenses;

  int get activeStudents =>
      students == 0 ? 0 : (transactionsLast7 * 100 ~/ students);
}

class DailyPoint {
  final DateTime day;
  final int expenses;
  final int income;
  const DailyPoint(this.day, this.expenses, this.income);

  int get total => expenses + income;
}

/// Reads every user's transactions to build the analytics view.
///
/// Firestore has no aggregate query, so this walks the collection group once
/// and reduces locally. Kept behind a loading state because it scales with the
/// number of documents.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const int dailyDays = 14;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AdminAnalytics> load() async {
    try {
      final usersSnap = await _db.collection('Users').get();
      final users = usersSnap.docs;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = today.subtract(const Duration(days: 30));

      var new7 = 0;
      var new30 = 0;
      var admins = 0;
      var totalBudgets = 0.0;
      var goals = 0;

      for (final doc in users) {
        final data = doc.data();
        if ('${data['Role']}'.toLowerCase() == 'admin' ||
            data['IsAdmin'] == true) {
          admins++;
        }
        final created = data['CreatedAt'];
        final at = created is Timestamp ? created.toDate() : null;
        if (at != null) {
          if (at.isAfter(weekAgo)) new7++;
          if (at.isAfter(monthAgo)) new30++;
        }
        final budget = data['MonthlyBudget'];
        if (budget is num) totalBudgets += budget.toDouble();

        final goalsSnap = await doc.reference
            .collection('SavingGoals')
            .get(const GetOptions(source: Source.server));
        goals += goalsSnap.docs.length;
      }

      // collectionGroup walks Transactions under every user in one query
      // instead of one round trip per user.
      final txSnap = await _db
          .collectionGroup('Transactions')
          .get(const GetOptions(source: Source.server));

      var totalTx = 0;
      var expenseCount = 0;
      var incomeCount = 0;
      var last7 = 0;
      var expenses = 0.0;
      var income = 0.0;
      var receipts = 0;
      final byCategory = <String, double>{};
      final perDay = <DateTime, List<int>>{
        for (var i = dailyDays - 1; i >= 0; i--)
          today.subtract(Duration(days: i)): [0, 0],
      };

      for (final doc in txSnap.docs) {
        final data = doc.data();
        totalTx++;
        final amount = _num(data['Amount']).toDouble();
        final isExpense = data['IsExpense'] != false;
        final category = '${data['Category'] ?? 'Other'}';
        if ('${data['ReceiptData'] ?? ''}'.isNotEmpty ||
            '${data['ReceiptUrl'] ?? ''}'.isNotEmpty) {
          receipts++;
        }

        final stamp = data['Date'];
        final at = stamp is Timestamp
            ? stamp.toDate()
            : (stamp is DateTime ? stamp : null);

        if (isExpense) {
          expenseCount++;
          expenses += amount;
          byCategory.update(
            category,
            (v) => v + amount,
            ifAbsent: () => amount,
          );
        } else {
          incomeCount++;
          income += amount;
        }

        if (at != null) {
          final day = DateTime(at.year, at.month, at.day);
          if (day.isAfter(weekAgo)) last7++;
          final slot = perDay[day];
          if (slot != null) {
            slot[isExpense ? 0 : 1]++;
          }
        }
      }

      final top = Map<String, double>.fromEntries(
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      return AdminAnalytics(
        totalUsers: users.length,
        students: users.length - admins,
        admins: admins,
        newLast7: new7,
        newLast30: new30,
        totalTransactions: totalTx,
        expenseCount: expenseCount,
        incomeCount: incomeCount,
        transactionsLast7: last7,
        totalExpenses: expenses,
        totalIncome: income,
        totalBudgets: totalBudgets,
        receiptCount: receipts,
        goalsCount: goals,
        topCategories: top,
        daily: perDay.entries
            .map((e) => DailyPoint(e.key, e.value[0], e.value[1]))
            .toList(),
      );
    } catch (e) {
      debugPrint('Analytics load failed: $e');
      return AdminAnalytics.empty;
    }
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
