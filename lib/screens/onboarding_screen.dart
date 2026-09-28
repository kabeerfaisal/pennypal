import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/pennypal_logo.dart';
import 'auth_gate.dart';

/// Friendly first-run walkthrough. Shown once, then never again unless the
/// student reopens it from the app menu.
class OnboardingScreen extends StatefulWidget {
  /// Where to go after finishing. Defaults to popping the route.
  final VoidCallback? onDone;

  const OnboardingScreen({super.key, this.onDone});

  static const String prefKey = 'pennypal_onboarding_done';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKey) ?? false;
  }

  /// Records that the walkthrough is done. Never throws: if the preference
  /// cannot be written the student must still get into the app, and seeing the
  /// slides once more is a much smaller problem than being locked out.
  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (e) {
      debugPrint('Onboarding pref not saved: $e');
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: PennyPalLogo.mark,
      color: AppColors.brand,
      title: 'Welcome to PennyPal',
      body:
          'Track what you spend, set a monthly limit, and actually see where '
          'your money goes.',
    ),
    _Slide(
      icon: Icons.receipt_long_rounded,
      color: AppColors.info,
      title: 'Log every transaction',
      body:
          'Add income and expenses in a few taps. You can even attach a photo '
          'of the receipt so nothing gets lost.',
    ),
    _Slide(
      icon: Icons.donut_large_rounded,
      color: AppColors.warning,
      title: 'Stay inside your limits',
      body:
          'Set a cap per category. We warn you before you cross the line, so '
          'there are no surprises at month end.',
    ),
    _Slide(
      icon: Icons.savings_rounded,
      color: AppColors.income,
      title: 'Save for real goals',
      body:
          'A laptop, a trip, an emergency fund. Set a target, add money when '
          'you can, and watch the progress grow.',
    ),
    _Slide(
      icon: Icons.smart_toy_rounded,
      color: Colors.indigo,
      title: 'Ask anything, by voice or text',
      body:
          'The built in advisor answers from your own numbers, and every '
          'conversation is saved to your account.',
    ),
    // The "where is what" slide, so a new student knows the layout before they
    // start hunting for anything.
    _Slide(
      icon: Icons.grid_view_rounded,
      color: AppColors.brand,
      title: 'What lives where',
      body: 'Five tabs along the bottom, and this is what each one holds.',
      map: true,
    ),
  ];

  /// The tab guide shown on the final slide. Kept beside the slide data so
  /// adding a tab means adding one row here too.
  static const List<_Feature> _features = [
    _Feature(
      icon: Icons.grid_view_rounded,
      label: 'Dashboard',
      detail: 'Balance, recent activity and the budget ring',
    ),
    _Feature(
      icon: Icons.receipt_long_rounded,
      label: 'Transactions',
      detail: 'Every entry, with filters, search and receipt photos',
    ),
    _Feature(
      icon: Icons.donut_large_rounded,
      label: 'Budget',
      detail: 'Set the monthly limit and a cap per category',
    ),
    _Feature(
      icon: Icons.savings_rounded,
      label: 'Savings',
      detail: 'Your goals, milestones and progress',
    ),
    _Feature(
      icon: Icons.menu_book_rounded,
      label: 'Learning',
      detail: 'Short money lessons from your admin',
    ),
    _Feature(
      icon: Icons.smart_toy_rounded,
      label: 'AI advisor',
      detail: 'Tap the robot on the green bar to ask anything',
    ),
    _Feature(
      icon: Icons.notifications_none_rounded,
      label: 'Notifications',
      detail: 'The bell in the top bar: warnings, milestones, admin replies',
    ),
    _Feature(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
      detail: 'Edit your details, theme and notification settings',
    ),
  ];

  void _finish() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    final done = widget.onDone;
    if (done != null) {
      done();
      return;
    }
    // Standalone use: hand over to the auth gate instead of popping back into
    // the splash screen that launched this.
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
      return;
    }
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// The plain icon + title + body slide.
  ///
  /// Scrollable, because a 128pt circle plus the title and body does not fit
  /// on a short screen at a large system font, and a student who cannot read
  /// the slide would be stuck on it with no way to continue.
  Widget _textSlide(_Slide s) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          // minHeight equal to the viewport lets a short slide stay vertically
          // centred, while a tall one simply grows and scrolls.
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AppColors.tint(s.color),
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon, size: 58, color: s.color),
              ),
              const SizedBox(height: 36),
              Text(
                s.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                s.body,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "what lives where" guide. Scrollable, because eight rows do not fit on
  /// a short screen and a student on a small phone must still be able to reach
  /// the bottom of the list.
  Widget _featureMap(_Slide s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          s.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? Colors.white60 : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (final f in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.brandTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.icon, size: 17, color: s.color),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              f.detail,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: s.map ? _featureMap(s) : _textSlide(s),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.brand
                              : AppColors.brand.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                      label: Text(isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  /// When set, the slide body is replaced by a scrollable "what lives where"
  /// list instead of a paragraph.
  final bool map;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.map = false,
  });
}

/// One row of the "what lives where" guide.
class _Feature {
  final IconData icon;
  final String label;
  final String detail;

  const _Feature({
    required this.icon,
    required this.label,
    required this.detail,
  });
}
