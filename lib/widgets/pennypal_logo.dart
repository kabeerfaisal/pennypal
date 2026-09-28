import 'package:flutter/material.dart';

/// The PennyPal piggy bank mark, in one place.
///
/// The splash screen's logo is the brand, so the app bar, the welcome banner
/// and the About screen all render this same mark rather than picking a
/// different leaf or coin icon and drifting apart.
class PennyPalLogo extends StatelessWidget {
  /// Outer size of the circular badge.
  final double size;

  /// Paints the mark on a filled circle. Use `false` for the bare glyph, e.g.
  /// on a coloured header where the circle would be invisible.
  final bool withCircle;

  final Color? background;
  final Color? foreground;

  const PennyPalLogo({
    super.key,
    this.size = 30,
    this.withCircle = true,
    this.background,
    this.foreground,
  });

  /// The single icon the whole app agrees on.
  static const IconData mark = Icons.savings_rounded;

  @override
  Widget build(BuildContext context) {
    final fg =
        foreground ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF15803D));

    if (!withCircle) {
      return Icon(mark, size: size, color: fg);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? fg.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(mark, size: size * 0.58, color: fg),
    );
  }
}
