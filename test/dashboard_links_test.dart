import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/theme/app_theme.dart';
import 'package:penny_pal/widgets/dashboard_shell_scope.dart';
import 'package:penny_pal/widgets/ui_kit.dart';

/// Reproduces the dashboard shape: a section header inside a child view, and a
/// shell that listens to the tab notifier and shows the selected tab.
class _ShellHarness extends StatefulWidget {
  const _ShellHarness();

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  final tabs = ValueNotifier<int>(0);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShellScope(
      tabIndex: tabs,
      child: MaterialApp(
        theme: AppTheme.light(AppColors.brand),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: tabs,
            builder: (context, _) => Column(
              children: [
                SectionHeader(
                  title: 'Monthly Budget',
                  actionLabel: 'View Budget',
                  actionTab: DashboardShellScope.tabBudget,
                ),
                SectionHeader(
                  title: 'Recent Transactions',
                  actionLabel: 'View All',
                  actionTab: DashboardShellScope.tabTransactions,
                ),
                Expanded(child: Center(child: Text('tab ${tabs.value}'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('section header links reach the shell', () {
    testWidgets('tapping View Budget switches to the budget tab', (
      tester,
    ) async {
      await tester.pumpWidget(const _ShellHarness());
      await tester.pumpAndSettle();

      expect(find.text('tab 0'), findsOneWidget);

      // This is the exact thing that looked dead before: the link was wired to
      // a static callback that was null whenever the shell was not alive.
      await tester.tap(find.text('View Budget'));
      await tester.pumpAndSettle();

      expect(find.text('tab 2'), findsOneWidget);
    });

    testWidgets('tapping View All switches to the transactions tab', (
      tester,
    ) async {
      await tester.pumpWidget(const _ShellHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('tab 1'), findsOneWidget);
    });

    testWidgets('both links work in either order', (tester) async {
      await tester.pumpWidget(const _ShellHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();
      expect(find.text('tab 1'), findsOneWidget);

      await tester.tap(find.text('View Budget'));
      await tester.pumpAndSettle();
      expect(find.text('tab 2'), findsOneWidget);

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();
      expect(find.text('tab 1'), findsOneWidget);
    });

    testWidgets('the whole pill is tappable, not only the words', (
      tester,
    ) async {
      await tester.pumpWidget(const _ShellHarness());
      await tester.pumpAndSettle();

      final pill = tester.getRect(find.byType(InkWell).first);
      // Tap the far edge, well away from the label.
      await tester.tapAt(Offset(pill.right - 4, pill.center.dy));
      await tester.pumpAndSettle();

      expect(find.text('tab 2'), findsOneWidget);
    });

    testWidgets('the arrow icon is part of the target too', (tester) async {
      await tester.pumpWidget(const _ShellHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('tab 2'), findsOneWidget);
    });

    testWidgets('a header outside a shell does not crash when tapped', (
      tester,
    ) async {
      // The shared header is also rendered on its own in tests and previews, so
      // a missing scope has to be a no-op rather than an exception.
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColors.brand),
          home: Scaffold(
            body: SectionHeader(
              title: 'Orphan',
              actionLabel: 'View All',
              actionTab: DashboardShellScope.tabSavings,
              onAction: () => taps++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // An explicit callback wins over the tab.
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('DashboardShellScope', () {
    test('the tab indices are stable and in order', () {
      expect(DashboardShellScope.tabHome, 0);
      expect(DashboardShellScope.tabTransactions, 1);
      expect(DashboardShellScope.tabBudget, 2);
      expect(DashboardShellScope.tabSavings, 3);
      expect(DashboardShellScope.tabLearning, 4);
    });

    test('goToTab switches the notifier', () {
      final tabs = ValueNotifier<int>(0);
      final scope = DashboardShellScope(
        tabIndex: tabs,
        child: const SizedBox.shrink(),
      );

      scope.goToTab(DashboardShellScope.tabSavings);
      expect(tabs.value, DashboardShellScope.tabSavings);
      tabs.dispose();
    });

    test('goToTab to the current tab is a no-op', () {
      final tabs = ValueNotifier<int>(2);
      var notified = 0;
      tabs.addListener(() => notified++);

      DashboardShellScope(
        tabIndex: tabs,
        child: const SizedBox.shrink(),
      ).goToTab(2);

      expect(notified, 0);
      tabs.dispose();
    });

    test('a listener hears a tab change', () {
      final tabs = ValueNotifier<int>(0);
      var notified = 0;
      tabs.addListener(() => notified++);

      DashboardShellScope(
        tabIndex: tabs,
        child: const SizedBox.shrink(),
      ).goToTab(3);

      expect(notified, 1);
      tabs.dispose();
    });
  });
}
