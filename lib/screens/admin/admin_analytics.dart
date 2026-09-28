import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';

/// Admin only: app level numbers derived from every user's data.
class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  late Future<AdminAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AnalyticsService.instance.load();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAnalytics>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.connectionState == ConnectionState.done && snap.hasError) {
          return _message(
            Icons.cloud_off_rounded,
            'Could not load analytics',
            '${snap.error}',
          );
        }
        final a = snap.data ?? AdminAnalytics.empty;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _section('People', Icons.people_rounded),
              _row([
                _metric(
                  'Total users',
                  '${a.totalUsers}',
                  Icons.people,
                  Colors.blue,
                ),
                _metric('Students', '${a.students}', Icons.person, Colors.teal),
                _metric('Admins', '${a.admins}', Icons.shield, Colors.indigo),
              ]),
              _row([
                _metric(
                  'New (7d)',
                  '${a.newLast7}',
                  Icons.person_add,
                  Colors.green,
                ),
                _metric(
                  'New (30d)',
                  '${a.newLast30}',
                  Icons.trending_up,
                  Colors.orange,
                ),
                _metric(
                  'Active (7d)',
                  '${a.transactionsLast7}',
                  Icons.bolt,
                  Colors.purple,
                ),
              ]),
              const SizedBox(height: 20),
              _section('Activity', Icons.receipt_long_rounded),
              _row([
                _metric(
                  'Transactions',
                  '${a.totalTransactions}',
                  Icons.list_alt,
                  Colors.blue,
                ),
                _metric(
                  'Expenses',
                  '${a.expenseCount}',
                  Icons.trending_down,
                  Colors.red,
                ),
                _metric(
                  'Income',
                  '${a.incomeCount}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ]),
              _row([
                _metric(
                  'Receipts',
                  '${a.receiptCount}',
                  Icons.photo_camera,
                  Colors.purple,
                ),
                _metric('Goals', '${a.goalsCount}', Icons.flag, Colors.teal),
                _metric(
                  'Transactions (7d)',
                  '${a.transactionsLast7}',
                  Icons.bolt,
                  Colors.orange,
                ),
              ]),
              const SizedBox(height: 20),
              _section('Money tracked', Icons.payments_rounded),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _moneyRow('Total income', a.totalIncome, Colors.green),
                      const Divider(height: 20),
                      _moneyRow('Total expenses', a.totalExpenses, Colors.red),
                      const Divider(height: 20),
                      _moneyRow(
                        'Net tracked',
                        a.net,
                        a.net >= 0 ? Colors.green : Colors.red,
                      ),
                      const Divider(height: 20),
                      _moneyRow(
                        'Budgets set by students',
                        a.totalBudgets,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _section('Top spending categories', Icons.pie_chart_rounded),
              if (a.topCategories.isEmpty)
                _emptyChart('No expenses recorded yet')
              else
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                    child: SizedBox(height: 220, child: BarChart(_barData(a))),
                  ),
                ),
              const SizedBox(height: 20),
              _section(
                'Last ${AnalyticsService.dailyDays} days',
                Icons.show_chart_rounded,
              ),
              if (a.daily.isEmpty)
                _emptyChart('No activity yet')
              else
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                    child: SizedBox(
                      height: 220,
                      child: LineChart(_lineData(a)),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _section('Category split', Icons.list_rounded),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: a.topCategories.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No category data yet'),
                      )
                    : Column(
                        children: a.topCategories.entries.map((e) {
                          final share = a.totalExpenses == 0
                              ? 0.0
                              : e.value / a.totalExpenses * 100;
                          return ListTile(
                            dense: true,
                            title: Text(e.key),
                            trailing: Text('${share.toStringAsFixed(1)}%'),
                            subtitle: LinearProgressIndicator(
                              value: share.clamp(0.0, 1.0),
                              minHeight: 6,
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _message(IconData icon, String title, String body) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: children
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: c,
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _emptyChart(String text) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(child: Text(text)),
      ),
    );
  }

  BarChartData _barData(AdminAnalytics a) {
    final entries = a.topCategories.entries.take(6).toList();
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: entries.isEmpty
          ? 1
          : entries.map((e) => e.value).reduce((x, y) => x > y ? x : y) * 1.2,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= entries.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  entries[i].key.length > 9
                      ? '${entries[i].key.substring(0, 9)}â€¦'
                      : entries[i].key,
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < entries.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                width: 18,
                borderRadius: BorderRadius.circular(4),
                color: Colors.teal,
              ),
            ],
          ),
      ],
    );
  }

  LineChartData _lineData(AdminAnalytics a) {
    final maxY = a.daily.isEmpty
        ? 1.0
        : a.daily
                  .map((d) => d.total)
                  .fold(0, (m, e) => e > m ? e : m)
                  .toDouble() *
              1.25;
    return LineChartData(
      minY: 0,
      maxY: maxY <= 0 ? 1 : maxY,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= a.daily.length) return const SizedBox.shrink();
              // Label every other day so the axis stays readable.
              if (i.isOdd) return const SizedBox.shrink();
              final d = a.daily[i].day;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${d.day}/${d.month}',
                  style: const TextStyle(fontSize: 9),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < a.daily.length; i++)
              FlSpot(i.toDouble(), a.daily[i].expenses.toDouble()),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          color: Colors.red,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.12),
          ),
        ),
        LineChartBarData(
          spots: [
            for (var i = 0; i < a.daily.length; i++)
              FlSpot(i.toDouble(), a.daily[i].income.toDouble()),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          color: Colors.green,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}
