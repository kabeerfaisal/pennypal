import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One highlighted spot in the app tour.
class TourStep {
  /// Identifies the widget to point at. Must match a `tourAnchor` value.
  final String anchor;

  final String title;
  final String body;

  /// Which side of the highlighted widget the card sits on. Chosen per step so
  /// the card never covers the thing it is describing.
  final TourPlacement placement;

  const TourStep({
    required this.anchor,
    required this.title,
    required this.body,
    this.placement = TourPlacement.below,
  });
}

/// Where the callout sits relative to its highlight.
enum TourPlacement { below, above, center }

/// The walkthrough shown once, the first time a brand new student reaches the
/// dashboard.
///
/// The splash already shows the general pitch; this is the part a student
/// actually needs, which is what every control on the screen is for. Each step
/// highlights the real widget and points at it, so it cannot drift out of date
/// the way a separate screenshot would.
class GuidedTour extends StatefulWidget {
  /// Resolves an anchor name to its position on screen. Returns null when the
  /// widget is not currently built, e.g. a tab that is not selected.
  final Rect? Function(String anchor) locate;

  final List<TourStep> steps;

  /// Called when the student finishes or skips.
  final VoidCallback onDone;

  const GuidedTour({
    super.key,
    required this.locate,
    required this.steps,
    required this.onDone,
  });

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> {
  int _index = 0;

  TourStep get _step => widget.steps[_index];

  bool get _isLast => _index == widget.steps.length - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
      return;
    }
    setState(() => _index++);
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    // An empty or out of range list would otherwise index off the end. The
    // caller already checks, but a tour that crashes takes the app with it.
    if (widget.steps.isEmpty || _index >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final target = widget.locate(_step.anchor);

    // Swallows taps so the tour does not let the student wander into a screen
    // that is being explained. Back still exits, which is expected.
    return Material(
      type: MaterialType.transparency,
      // Every child below is positioned, and a Stack whose children are all
      // positioned sizes itself to constraints.smallest, which is zero here.
      // That made the whole tour zero sized, so nothing was tappable at all.
      // Pinning it to the incoming size is what makes the scrim and the
      // spotlight work.
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _next,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ),
              if (target != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      // The hole is painted rather than clipped, so the real
                      // widget underneath stays visible and obviously still
                      // there.
                      painter: _SpotlightPainter(rect: target),
                    ),
                  ),
                ),
              // An anchor that is not on screen yet, e.g. a control inside a
              // tab the student has not opened, still gets its explanation
              // shown rather than being skipped.
              _card(context, size, target),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Size size, Rect? target) {
    const margin = 16.0;
    final width = size.width - margin * 2;
    // One value used for BOTH the height cap and the top clamp. Capping the
    // height while positioning against a smaller assumed height is what pushed
    // the buttons off the bottom of the screen at a large text scale.
    final maxCardHeight = size.height < margin * 2 + 160
        ? size.height
        : math.min(size.height - margin * 2, 340.0);

    late Offset topLeft;
    if (target == null || _step.placement == TourPlacement.center) {
      topLeft = Offset(margin, (size.height - maxCardHeight) / 2);
    } else if (_step.placement == TourPlacement.below) {
      final y = target.bottom + 12;
      // Flip above when there is not enough room underneath.
      topLeft = Offset(
        margin,
        y + maxCardHeight > size.height - margin
            ? target.top - maxCardHeight - 12
            : y,
      );
    } else {
      final y = target.top - maxCardHeight - 12;
      topLeft = Offset(margin, y < margin ? target.bottom + 12 : y);
    }

    // Guarded because clamp throws when the low bound exceeds the high one,
    // which happens on a very short viewport. Falling back to the margin keeps
    // the card on screen instead of taking the app down.
    final maxX = size.width - width - margin;
    final maxY = size.height - maxCardHeight - margin;
    final clamped = Offset(
      maxX < margin ? margin : topLeft.dx.clamp(margin, maxX),
      maxY < margin ? margin : topLeft.dy.clamp(margin, maxY),
    );

    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      width: width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: Material(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Everything above the buttons scrolls, so the buttons stay on
                // screen no matter how large the system font is.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Flexible so the counter ellipsises instead of pushing the
                            // close button off a narrow card at a large system font.
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_index + 1} of ${widget.steps.length}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _skip,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close_rounded, size: 19),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _step.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _step.body,
                          style: const TextStyle(fontSize: 13, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Wrap, not Row. A Row overflows as soon as a large system font
                // makes the two labels wider than a small phone, whereas Wrap
                // drops Next onto its own line instead. On a normal screen both
                // stay on one line with Skip left and Next right.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Skip tour'),
                    ),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      child: Text(_isLast ? 'Got it' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.steps.length, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: active ? 0.95 : 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

/// Darkens the screen and cuts a rounded hole over the highlighted widget.
class _SpotlightPainter extends CustomPainter {
  final Rect rect;

  const _SpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    // Grown a little so the whole control is inside the glow, not just its
    // text.
    final hole = Rect.fromCenter(
      center: rect.center,
      width: rect.width + 12,
      height: rect.height + 12,
    );
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(12));

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      // Without even-odd the two shapes union and the hole fills in solid,
      // leaving no highlight at all.
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    // A green rim, so the eye is drawn to the right control.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF15803D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.rect != rect;
}
