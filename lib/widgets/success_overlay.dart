import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen confirmation with an animated green tick.
///
/// Used after an action the user must see succeed: adding a transaction, and an
/// admin suspending an account. A SnackBar is too easy to miss for something
/// this important, and it disappears on its own.
class SuccessOverlay extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Optional line under the subtitle, e.g. the saved amount.
  final String? detail;

  /// Label for the dismissing button. Defaults to "Done".
  final String actionLabel;

  final IconData icon;
  final Color color;

  const SuccessOverlay({
    super.key,
    required this.title,
    this.subtitle = '',
    this.detail,
    this.actionLabel = 'Done',
    this.icon = Icons.check_rounded,
    this.color = AppColors.income,
  });

  /// Shows the overlay and resolves once the user dismisses it.
  static Future<void> show(
    BuildContext context, {
    required String title,
    String subtitle = '',
    String? detail,
    String actionLabel = 'Done',
    IconData icon = Icons.check_rounded,
    Color color = AppColors.income,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => SuccessOverlay(
        title: title,
        subtitle: subtitle,
        detail: detail,
        actionLabel: actionLabel,
        icon: icon,
        color: color,
      ),
      transitionBuilder: (context, anim, _, child) {
        // Fades in and grows slightly, so it reads as arriving rather than
        // snapping onto the screen.
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadow.lifted(theme.colorScheme),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Tick(color: widget.color, controller: _ctrl),
                  const SizedBox(height: 22),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (widget.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white60
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (widget.detail != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        widget.detail!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _close,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.color,
                      ),
                      child: Text(widget.actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The green circle with a tick that draws itself in.
class _Tick extends StatelessWidget {
  final Color color;
  final AnimationController controller;

  const _Tick({required this.color, required this.controller});

  @override
  Widget build(BuildContext context) {
    final halo = Tween<double>(
      begin: 0.7,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    final draw = CurvedAnimation(
      parent: controller,
      // Holds at 0 for the first 30% so the circle lands before the tick draws.
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );

    return ScaleTransition(
      scale: halo,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 68,
            height: 68,
            child: CustomPaint(
              painter: _TickPainter(color: color, progress: draw.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  final double progress;

  const _TickPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Solid disc.
    canvas.drawCircle(center, radius, Paint()..color = color);

    if (progress <= 0) return;

    // The tick is two strokes, revealed by trimming the end of one path.
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.73, size.height * 0.34);

    final metrics = path.computeMetrics().first;
    final trimmed = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(trimmed, paint);
  }

  @override
  bool shouldRepaint(covariant _TickPainter old) =>
      old.progress != progress || old.color != color;
}
