import 'package:flutter/widgets.dart';

/// Lets a child view switch the dashboard tab without reaching for a static.
///
/// The old approach stored a callback in a static field, which silently did
/// nothing whenever the shell had not been built yet or had been disposed, so
/// the "View All" and "View Budget" links appeared dead. Going through the
/// element tree means a link always finds the live shell, and it can be tested
/// without standing up the whole Firebase backed screen.
class DashboardShellScope extends InheritedWidget {
  /// The visible tab. Writable so a child can switch tabs; the shell listens
  /// to it to know when to rebuild.
  final ValueNotifier<int> tabIndex;

  /// Tab indices, so no screen has to hard code a number.
  static const int tabHome = 0;
  static const int tabTransactions = 1;
  static const int tabBudget = 2;
  static const int tabSavings = 3;
  static const int tabLearning = 4;

  const DashboardShellScope({
    super.key,
    required this.tabIndex,
    required super.child,
  });

  @override
  bool updateShouldNotify(DashboardShellScope oldWidget) =>
      tabIndex != oldWidget.tabIndex;

  /// Switches to [index]. A no-op when the shell is not in the tree, which is
  /// the case in a test that renders a single view on its own.
  void goToTab(int index) {
    if (index == tabIndex.value) return;
    tabIndex.value = index;
  }

  static DashboardShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardShellScope>();

  /// The scope, or a detached one that safely does nothing. Used by the shared
  /// section headers, which are also rendered in isolation by tests.
  static DashboardShellScope of(BuildContext context) =>
      maybeOf(context) ??
      DashboardShellScope(
        tabIndex: ValueNotifier<int>(tabHome),
        child: const SizedBox.shrink(),
      );
}
