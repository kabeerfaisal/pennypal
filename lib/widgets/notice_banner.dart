import 'dart:async';

import 'package:flutter/material.dart';

enum NoticeLevel { info, success, warning }

class AppNotice {
  final String title;
  final String body;
  final NoticeLevel level;
  final DateTime at;

  AppNotice({
    required this.title,
    required this.body,
    this.level = NoticeLevel.info,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  String get key => '${at.microsecondsSinceEpoch}-$title';
}

/// A dismissible banner pinned under the app bar.
///
/// Replaces the push notification service, which needed Firebase Cloud
/// Messaging and asked the student for notification permission. This renders
/// inside the app: no permission, no plugin, no background service.
class NoticeBanner extends StatefulWidget {
  final GlobalKey<NavigatorState>? navKey;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onNoticeTap;

  const NoticeBanner({
    super.key,
    required this.navKey,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onNoticeTap,
  });

  static Listenable listenable() => _NoticeBus.instance;

  /// How long a notice stays on screen, and how long after it was raised a
  /// banner that mounts late will still pick it up.
  static Duration displayDuration = const Duration(seconds: 7);

  /// Shows a notice from anywhere, including controllers with no context.
  static void show(
    String title,
    String body, {
    NoticeLevel level = NoticeLevel.info,
  }) {
    _NoticeBus.instance.add(AppNotice(title: title, body: body, level: level));
  }

  @override
  State<NoticeBanner> createState() => _NoticeBannerState();
}

class _NoticeBannerState extends State<NoticeBanner> {
  AppNotice? _current;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _NoticeBus.instance.addListener(_onNotice);
    // A notice can fire before this banner mounts, e.g. while the app is still
    // on the splash screen. Picking up the retained one avoids losing it.
    final pending = _NoticeBus.instance.latest;
    if (pending != null) {
      final age = DateTime.now().difference(pending.at);
      if (age < NoticeBanner.displayDuration) {
        _current = pending;
        _timer = Timer(NoticeBanner.displayDuration - age, _dismiss);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _NoticeBus.instance.removeListener(_onNotice);
    super.dispose();
  }

  void _onNotice() {
    final notice = _NoticeBus.instance.latest;
    if (notice == null) return;
    _timer?.cancel();
    setState(() => _current = notice);
    // Auto dismiss so a stale notice cannot sit on screen forever.
    _timer = Timer(NoticeBanner.displayDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _NoticeBus.instance,
          builder: (context, _) {
            final notice = _current;
            return AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: notice == null
                  ? const SizedBox(width: double.infinity)
                  : _card(context, notice),
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _card(BuildContext context, AppNotice notice) {
    final scheme = _palette(context, notice.level);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Material(
        color: scheme.bg,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onNoticeTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(scheme.icon, color: scheme.fg, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notice.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.fg,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notice.body,
                        style: TextStyle(
                          color: scheme.fg.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: scheme.fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _NoticePalette _palette(BuildContext context, NoticeLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const success = Color(0xFF2E7D32);
    const warning = Color(0xFFE65100);
    const info = Color(0xFF1565C0);

    final base = switch (level) {
      NoticeLevel.success => success,
      NoticeLevel.warning => warning,
      NoticeLevel.info => info,
    };
    final icon = switch (level) {
      NoticeLevel.success => Icons.check_circle_rounded,
      NoticeLevel.warning => Icons.warning_amber_rounded,
      NoticeLevel.info => Icons.info_rounded,
    };

    return _NoticePalette(
      bg: isDark ? base.withValues(alpha: 0.22) : base.withValues(alpha: 0.12),
      fg: isDark ? const Color(0xFFFFFFFF) : base,
      icon: icon,
    );
  }
}

class _NoticePalette {
  final Color bg;
  final Color fg;
  final IconData icon;
  const _NoticePalette({
    required this.bg,
    required this.fg,
    required this.icon,
  });
}

/// Holds the most recent notice so a banner that mounts later still shows it.
class _NoticeBus extends ChangeNotifier {
  static final _NoticeBus instance = _NoticeBus._();
  _NoticeBus._();

  AppNotice? _latest;
  AppNotice? get latest => _latest;

  void add(AppNotice notice) {
    _latest = notice;
    notifyListeners();
  }
}
