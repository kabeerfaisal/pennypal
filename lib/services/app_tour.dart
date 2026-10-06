import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/guided_tour.dart';

/// Shows the first-login walkthrough once, over the dashboard.
///
/// Deliberately keyed off a preference rather than "is this a new account", so
/// a student who dismisses it is not shown it again, and an existing account
/// is never interrupted on an update.
class AppTour {
  AppTour._();
  static final AppTour instance = AppTour._();

  static const String prefKey = 'pennypal_tour_done';

  /// The one walkthrough currently in flight, or null when none is.
  ///
  /// This exists because the dashboard's `initState` can run more than once
  /// while a student is signing in. Each run asked for a tour, and because
  /// [maybeShow] has to await the preference store before it can decide, two
  /// callers both read "not seen" and both inserted an entry. The student then
  /// got two walkthroughs stacked on each other, each counting its own steps,
  /// so one card read "1 of 7" while the other read "4 of 7".
  static OverlayEntry? _activeEntry;

  /// Whether the slot above is claimed.
  ///
  /// Separate from [_activeEntry] on purpose. `OverlayEntry.mounted` only turns
  /// true once the entry has actually been inserted, so it cannot be used to
  /// tell "claimed but still waiting on the preference store" apart from
  /// "torn down without finishing". Confusing the two let a second caller
  /// reclaim a slot that was still in use, which is the very bug this guards.
  static bool _showing = false;

  /// How many walkthroughs are on screen. It must never be more than one.
  @visibleForTesting
  static int get activeCount => _showing ? 1 : 0;

  /// Clears the in-flight slot so each test starts from a clean slate.
  @visibleForTesting
  static void resetForTest() {
    final entry = _activeEntry;
    _activeEntry = null;
    _showing = false;
    if (entry != null && entry.mounted) entry.remove();
  }

  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      // No store means no memory of the tour, which only means it is shown
      // again. Better than locking anybody out of the app.
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (_) {
      // Nothing to do; the tour simply reappears next launch.
    }
  }

  /// Puts the tour on screen over [context] if it has not been seen.
  ///
  /// [locate] resolves an anchor name to its on-screen rectangle, so the
  /// highlight tracks the real widget rather than a hard coded coordinate.
  ///
  /// Safe to call as often as the dashboard likes: a second call while a
  /// walkthrough is already up does nothing, so the student only ever sees one.
  static Future<void> maybeShow(
    BuildContext context, {
    required Rect? Function(String anchor) locate,
    required List<TourStep> steps,
  }) async {
    if (steps.isEmpty) return;

    if (_showing) {
      final live = _activeEntry;
      // A null entry means the first caller is still inside an await and has not
      // put anything on screen yet, so this caller has nothing to do. A mounted
      // one means it is on screen. Both cases: walk away.
      if (live == null || live.mounted) return;
      // Mounted has gone false, so it was torn down without finishing. That
      // happens when the student presses the system back button and the route
      // underneath pops. Reclaim the slot so the tour can appear on the next
      // dashboard build.
      _activeEntry = null;
    }

    // Claim the slot before the first await. Two callers reaching this line in
    // the same frame both get past a check that happens after the await, and by
    // then both have already read the preference and both go on to insert.
    _showing = true;

    // The entry is built with a placeholder builder and pointed at the real one
    // afterwards, because `OverlayEntry.builder` is final and the entry has to
    // exist before the first await to be captured by the closure.
    WidgetBuilder? realBuilder;
    final entry = OverlayEntry(
      builder: (context) =>
          realBuilder?.call(context) ?? const SizedBox.shrink(),
    );

    void release() {
      _showing = false;
      _activeEntry = null;
    }

    try {
      if (await hasSeen()) {
        release();
        return;
      }
      if (!context.mounted) {
        release();
        return;
      }

      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        release();
        return;
      }

      realBuilder = (context) => GuidedTour(
        locate: locate,
        steps: steps,
        onDone: () {
          if (entry.mounted) entry.remove();
          release();
          markSeen();
        },
      );
      // Ownership is taken only now, once there is something real to own.
      _activeEntry = entry;
      overlay.insert(entry);
    } catch (_) {
      // Leave nothing half-inserted behind us.
      release();
      if (entry.mounted) entry.remove();
      rethrow;
    }
  }
}

/// The anchors the dashboard marks up, and what each one is for.
///
/// Anchors are plain strings on purpose. A key would tie the copy to a widget
/// instance, and a step whose anchor has been renamed would then crash instead
/// of quietly explaining itself in the middle of the screen.
class TourAnchors {
  TourAnchors._();

  static const String topBar = 'top-bar';
  static const String aiLink = 'ai-link';
  static const String statCards = 'stat-cards';
  static const String budget = 'budget-card';
  static const String recent = 'recent-transactions';
  static const String addButton = 'add-button';
  static const String bottomNav = 'bottom-nav';

  static const List<String> all = [
    topBar,
    aiLink,
    statCards,
    budget,
    recent,
    addButton,
    bottomNav,
  ];
}

/// The GlobalKeys for each anchor, and the lookup the tour uses.
///
/// Held in one place because the dashboard and its views are separate widgets:
/// the home view is a `const` instance inside the shell's view list, so it
/// cannot own keys of its own.
class TourKeys {
  TourKeys._();

  static final Map<String, GlobalKey> _keys = {
    for (final a in TourAnchors.all) a: GlobalKey(debugLabel: 'tour-$a'),
  };

  /// Marks [child] as the anchor called [anchor].
  static Widget wrap(String anchor, Widget child) =>
      KeyedSubtree(key: _keys[anchor], child: child);

  /// Where [anchor] currently sits on screen, or null when it is not built.
  static Rect? locate(String anchor) {
    final ctx = _keys[anchor]?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// The copy for the walkthrough, kept in one place so the wording can be edited
/// without touching any UI code.
List<TourStep> buildTourSteps() => const [
  TourStep(
    anchor: TourAnchors.topBar,
    title: 'Your screen at a glance',
    body:
        'The piggy bank icon is the app, the bell is your notifications, and '
        'the person icon opens your profile and settings.',
    placement: TourPlacement.below,
  ),
  TourStep(
    anchor: TourAnchors.aiLink,
    title: 'Ask the AI anything',
    body:
        'Tap the robot on the green bar. You can type or use the microphone, '
        'and it answers using your own numbers. Every chat is saved to your '
        'account.',
    placement: TourPlacement.below,
  ),
  TourStep(
    anchor: TourAnchors.statCards,
    title: 'Balance, spent and income',
    body:
        'These three figures update as you add transactions. They cover this '
        'month only.',
    placement: TourPlacement.below,
  ),
  TourStep(
    anchor: TourAnchors.budget,
    title: 'Your monthly budget',
    body:
        'Set a limit here. We warn you in the app and on your phone before you '
        'go past it. Tap "View Budget" to change it, or to add a cap per '
        'category.',
    placement: TourPlacement.below,
  ),
  TourStep(
    anchor: TourAnchors.recent,
    title: 'Recent activity',
    body:
        'Your latest transactions. Tap any one to edit or delete it, and "View '
        'All" opens the full list with search and filters.',
    placement: TourPlacement.above,
  ),
  TourStep(
    anchor: TourAnchors.addButton,
    title: 'Add a transaction',
    body:
        'The green button adds income or an expense. You can attach a photo of '
        'the receipt so you do not lose it.',
    placement: TourPlacement.above,
  ),
  TourStep(
    anchor: TourAnchors.bottomNav,
    title: 'Everything lives down here',
    body:
        'Dashboard, Transactions, Budget, Savings and Learning. That is the '
        'whole app. The three dots in the top bar hold the AI advisor, your '
        'profile, feedback, support and the privacy policy.',
    placement: TourPlacement.above,
  ),
];
